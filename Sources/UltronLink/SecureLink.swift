import Combine
import CryptoKit
import Foundation
import Network
import Security

public enum LinkError: Error { case unavailable, invalidInput, connectionLost, timeout, invalidFrame }

struct LinkMessage: Codable, Sendable {
    enum Kind: String, Codable, Sendable { case command, response, cancel }
    let kind: Kind
    let id: UUID
    let text: String
}

/// A user-started, single-peer TLS-PSK channel. Pairing keys and responses are never logged or persisted.
@MainActor
public final class SecureLink: ObservableObject {
    @Published public private(set) var status = "Disconnected"
    @Published public private(set) var isConnected = false
    @Published public private(set) var isHosting = false
    @Published public private(set) var port: UInt16?
    @Published public private(set) var pairingKey = ""
    public var handleCommand: (@MainActor @Sendable (String) async throws -> String)?
    private var listener: NWListener?
    private var connection: NWConnection?
    private var buffer = Data()
    private var commandTask: Task<Void, Never>?
    private var commandID: UUID?
    private var seen = Set<UUID>()
    private var pending: (UUID, CheckedContinuation<String, Error>)?
    private var timeoutTask: Task<Void, Never>?
    private var connectionTimeout: Task<Void, Never>?
    private var hostingTimeout: Task<Void, Never>?

    public init() {}

    nonisolated static func keyData(_ text: String) throws -> Data {
        guard text.count == 64, text.allSatisfy({ $0.isASCII && $0.isHexDigit }) else { throw LinkError.invalidInput }
        let chars = Array(text)
        return Data(stride(from: 0, to: 64, by: 2).map { UInt8(String(chars[$0...$0 + 1]), radix: 16)! })
    }

    private static func parameters(key: Data) -> NWParameters {
        let tls = NWProtocolTLS.Options()
        // Restrict negotiation to an authenticated PSK cipher; there is no plaintext/certificate fallback.
        sec_protocol_options_set_min_tls_protocol_version(tls.securityProtocolOptions, .TLSv12)
        sec_protocol_options_set_max_tls_protocol_version(tls.securityProtocolOptions, .TLSv12)
        sec_protocol_options_add_tls_ciphersuite(tls.securityProtocolOptions, SSLCipherSuite(TLS_PSK_WITH_AES_128_GCM_SHA256))
        let psk = key.withUnsafeBytes { DispatchData(bytes: $0) }
        let identity = Data("ultron-link-v1".utf8).withUnsafeBytes { DispatchData(bytes: $0) }
        sec_protocol_options_add_pre_shared_key(tls.securityProtocolOptions, psk as __DispatchData, identity as __DispatchData)
        return NWParameters(tls: tls, tcp: NWProtocolTCP.Options())
    }

    public func startHosting() throws {
        disconnect()
        let key = SymmetricKey(size: .bits256).withUnsafeBytes { Data($0) }
        pairingKey = key.map { String(format: "%02x", $0) }.joined()
        let next = try NWListener(using: Self.parameters(key: key), on: .any)
        listener = next
        isHosting = true
        status = "Starting local hosting…"
        next.stateUpdateHandler = { [weak self, weak next] state in
            Task { @MainActor in
                guard let self, let next, self.listener === next else { return }
                switch state {
                case .ready: self.port = next.port?.rawValue; self.status = "Waiting for a device with the pairing key"
                case .failed: self.disconnect(); self.status = "Hosting failed. Check Local Network permission."
                default: break
                }
            }
        }
        next.newConnectionHandler = { [weak self, weak next] incoming in
            Task { @MainActor in
                guard let self, let next, self.listener === next, self.connection == nil else { incoming.cancel(); return }
                self.attach(incoming)
            }
        }
        next.start(queue: .main)
        hostingTimeout = Task { [weak self] in
            try? await Task.sleep(for: .seconds(1800))
            guard !Task.isCancelled else { return }
            self?.disconnect()
            self?.status = "Hosting session expired. Start a new session to reconnect."
        }
    }

    public func connect(host: String, port: UInt16, pairingKey: String) throws {
        let key = try Self.keyData(pairingKey.trimmingCharacters(in: .whitespacesAndNewlines))
        guard !host.isEmpty, host.count < 254, !host.contains(where: \.isWhitespace), port > 0 else { throw LinkError.invalidInput }
        disconnect()
        status = "Connecting securely…"
        let next = NWConnection(host: NWEndpoint.Host(host), port: NWEndpoint.Port(rawValue: port)!, using: Self.parameters(key: key))
        attach(next)
    }

    private func attach(_ next: NWConnection) {
        connection = next
        buffer.removeAll()
        seen.removeAll()
        next.stateUpdateHandler = { [weak self, weak next] state in
            Task { @MainActor in
                guard let self, let next, self.connection === next else { return }
                switch state {
                case .ready:
                    self.connectionTimeout?.cancel()
                    self.isConnected = true
                    self.status = "Connected · encrypted local session"
                    self.receive(next)
                case .failed, .cancelled:
                    self.closeConnection()
                    self.status = "Connection ended. Check the address and pairing key."
                default: break
                }
            }
        }
        next.start(queue: .main)
        connectionTimeout = Task { [weak self, weak next] in
            try? await Task.sleep(for: .seconds(12))
            guard !Task.isCancelled, let self, let next, self.connection === next, !self.isConnected else { return }
            self.closeConnection()
            self.status = "Connection timed out. Check the address, key, and Local Network permission."
        }
    }

    public func request(_ text: String) async throws -> String {
        guard isConnected, !isHosting, pending == nil else { throw LinkError.unavailable }
        guard !text.isEmpty, text.utf8.count <= 2000 else { throw LinkError.invalidInput }
        try Task.checkCancellation()
        let id = UUID()
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                pending = (id, continuation)
                do { try send(.init(kind: .command, id: id, text: text)) }
                catch { resolve(id, result: .failure(error)); return }
                timeoutTask = Task { [weak self] in
                    try? await Task.sleep(for: .seconds(45))
                    guard !Task.isCancelled else { return }
                    self?.cancelRequest(id, error: LinkError.timeout)
                }
            }
        } onCancel: { Task { @MainActor [weak self] in self?.cancelRequest(id, error: CancellationError()) } }
    }

    private func cancelRequest(_ id: UUID, error: Error) {
        guard pending?.0 == id else { return }
        try? send(.init(kind: .cancel, id: id, text: ""))
        resolve(id, result: .failure(error))
    }

    private func resolve(_ id: UUID, result: Result<String, Error>) {
        guard let current = pending, current.0 == id else { return }
        pending = nil
        timeoutTask?.cancel(); timeoutTask = nil
        current.1.resume(with: result)
    }

    private func send(_ message: LinkMessage) throws {
        guard isConnected, let connection else { throw LinkError.unavailable }
        var data = try JSONEncoder().encode(message)
        guard data.count <= 32_000 else { throw LinkError.invalidFrame }
        data.append(10)
        connection.send(content: data, completion: .contentProcessed { [weak self, weak connection] error in
            guard error != nil else { return }
            Task { @MainActor in
                guard let self, let connection, self.connection === connection else { return }
                self.closeConnection()
            }
        })
    }

    private func receive(_ next: NWConnection) {
        next.receive(minimumIncompleteLength: 1, maximumLength: 8192) { [weak self, weak next] data, _, complete, error in
            Task { @MainActor in
                guard let self, let next, self.connection === next else { return }
                if let data { self.buffer.append(data) }
                guard self.buffer.count <= 40_192 else { self.closeConnection(); return }
                do {
                    while let end = self.buffer.firstIndex(of: 10) {
                        let line = self.buffer.prefix(upTo: end)
                        guard line.count <= 32_000 else { throw LinkError.invalidFrame }
                        let message = try JSONDecoder().decode(LinkMessage.self, from: line)
                        self.buffer.removeSubrange(...end)
                        try self.consume(message)
                    }
                    guard self.buffer.count <= 32_000 else { throw LinkError.invalidFrame }
                } catch { self.closeConnection(); return }
                if complete || error != nil { self.closeConnection() }
                else if self.connection === next { self.receive(next) }
            }
        }
    }

    private func consume(_ message: LinkMessage) throws {
        switch message.kind {
        case .response:
            guard !isHosting, message.text.utf8.count <= 24_000 else { throw LinkError.invalidFrame }
            resolve(message.id, result: .success(message.text))
        case .cancel:
            guard isHosting else { throw LinkError.invalidFrame }
            if commandID == message.id { commandTask?.cancel() }
        case .command:
            guard isHosting, !message.text.isEmpty, message.text.utf8.count <= 2000,
                  !seen.contains(message.id), seen.count < 128 else { throw LinkError.invalidFrame }
            seen.insert(message.id)
            guard commandTask == nil, let handleCommand else {
                try send(.init(kind: .response, id: message.id, text: "The Mac is busy. Try again shortly.")); return
            }
            commandID = message.id
            commandTask = Task { [weak self] in
                let result: String
                do { result = try await handleCommand(message.text) }
                catch { result = "The remote command was cancelled or could not be completed." }
                guard let self, self.commandID == message.id else { return }
                self.commandTask = nil; self.commandID = nil
                try? self.send(.init(kind: .response, id: message.id, text: String(result.prefix(6000))))
            }
        }
    }

    private func closeConnection() {
        let old = connection
        connection = nil
        old?.cancel()
        isConnected = false
        buffer.removeAll(); seen.removeAll()
        connectionTimeout?.cancel(); connectionTimeout = nil
        commandTask?.cancel(); commandTask = nil; commandID = nil
        if let id = pending?.0 { resolve(id, result: .failure(LinkError.connectionLost)) }
        status = isHosting ? "Waiting for a device with the pairing key" : "Disconnected"
    }

    public func disconnect() {
        hostingTimeout?.cancel(); hostingTimeout = nil
        let old = listener
        listener = nil; old?.cancel()
        isHosting = false; port = nil; pairingKey = ""
        closeConnection()
    }
}
