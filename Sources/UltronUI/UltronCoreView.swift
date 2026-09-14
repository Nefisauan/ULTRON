import SwiftUI
import UltronCore

public struct UltronCoreView: View {
    public let state: UltronState
    public let speechIntensity: Double
    public let lastWordAt: Date
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(state: UltronState, speechIntensity: Double = 0, lastWordAt: Date = .distantPast) {
        self.state = state
        self.speechIntensity = speechIntensity
        self.lastWordAt = lastWordAt
    }

    private var tint: Color { state == .error ? .orange : .cyan }

    public var body: some View {
        TimelineView(.animation(minimumInterval: state == .idle ? 1 / 15 : 1 / 30,
                                paused: scenePhase != .active || reduceMotion || state == .error)) { context in
            let time = reduceMotion ? 0 : context.date.timeIntervalSinceReferenceDate
            let wordPulse = max(0, 1 - context.date.timeIntervalSince(lastWordAt) * 3)
            let intensity = state == .speaking ? max(speechIntensity, wordPulse) : 0
            let speed: Double = state == .thinking ? 32 : state == .acting ? 22 : 6
            ZStack {
                Circle().fill(RadialGradient(colors: [tint.opacity(0.14), .clear], center: .center, startRadius: 45, endRadius: 170))
                    .frame(width: 340, height: 340)
                Circle().stroke(tint.opacity(0.12), lineWidth: 1).frame(width: 290, height: 290)
                ForEach(0..<3) { index in
                    Circle().trim(from: 0.08, to: 0.78)
                        .stroke(AngularGradient(colors: [.clear, tint.opacity(0.3), tint.opacity(0.9)], center: .center), style: StrokeStyle(lineWidth: index == 1 ? 2 : 1, lineCap: .round))
                        .frame(width: CGFloat(200 + index * 32), height: CGFloat(200 + index * 32))
                        .rotationEffect(.degrees(time * speed * (index == 1 ? -1 : 1) + Double(index * 100)))
                        .scaleEffect(reduceMotion ? 1 : 1 + intensity * 0.045)
                }
                Circle().fill(RadialGradient(colors: [Color(red: 0.24, green: 0.67, blue: 0.75), Color(red: 0.02, green: 0.13, blue: 0.2), .black], center: .topLeading, startRadius: 0, endRadius: 155))
                    .frame(width: 148, height: 148)
                    .overlay { Circle().stroke(tint.opacity(0.6), lineWidth: 1) }
                    .shadow(color: tint.opacity(0.15 + intensity * 0.35), radius: 28)
                    .scaleEffect(reduceMotion ? 1 : 1 + sin(time * 1.4) * 0.012 + intensity * 0.03)
                if state == .seeing {
                    Rectangle().fill(tint.opacity(0.7)).frame(width: 140, height: 1)
                        .offset(y: reduceMotion ? 0 : sin(time * 2) * 60)
                }
                Image(systemName: state == .error ? "exclamationmark" : "waveform")
                    .font(.system(size: 30, weight: .ultraLight)).foregroundStyle(tint.opacity(0.8))
            }.frame(maxWidth: .infinity).frame(height: 340)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("ULTRON core, \(state.rawValue)")
    }
}
