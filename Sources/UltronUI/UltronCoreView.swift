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

    private func annotation(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.system(size: 9, weight: .medium, design: .monospaced)).tracking(2)
                .foregroundStyle(tint.opacity(0.75))
            Text(subtitle).font(.system(size: 7, design: .monospaced)).tracking(1.5)
                .foregroundStyle(tint.opacity(0.4))
        }
    }

    private var tint: Color { state == .error ? .orange : .cyan }

    public var body: some View {
        TimelineView(.animation(minimumInterval: state == .idle ? 1 / 15 : 1 / 30,
                                paused: scenePhase != .active || reduceMotion || state == .error)) { context in
            let time = reduceMotion ? 0 : context.date.timeIntervalSinceReferenceDate
            let wordPulse = max(0, 1 - context.date.timeIntervalSince(lastWordAt) * 3)
            let intensity = state == .speaking && !reduceMotion ? min(1, max(0, max(speechIntensity, wordPulse))) : 0
            let speed: Double = state == .thinking ? 32 : state == .acting ? 22 : 6
            ZStack {
                RadialGradient(colors: [tint.opacity(0.12 + intensity * 0.08), .clear],
                               center: .center, startRadius: 12, endRadius: 195)
                Canvas { context, size in
                    let tint = state == .error ? Color.orange : Color.cyan
                    let center = CGPoint(x: size.width / 2, y: size.height / 2)
                    let unit = min(size.width / 430, size.height / 370)
                    func point(_ radius: Double, _ angle: Double) -> CGPoint {
                        CGPoint(x: center.x + cos(angle) * radius * unit,
                                y: center.y + sin(angle) * radius * unit)
                    }
                    func ring(_ radius: Double, opacity: Double, width: Double = 1) {
                        let r = radius * unit
                        context.stroke(Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r,
                                                              width: r * 2, height: r * 2)),
                                       with: .color(tint.opacity(opacity)), lineWidth: width)
                    }
                    ring(168, opacity: 0.13)
                    ring(148, opacity: 0.25)
                    ring(125, opacity: 0.12)
                    ring(87, opacity: 0.6)
                    ring(82, opacity: 0.2)
                    // Instrument graduations, with a brighter mark every thirty degrees.
                    for index in 0..<120 {
                        let angle = Double(index) * .pi / 60
                        var tick = Path()
                        tick.move(to: point(index % 10 == 0 ? 153 : 159, angle))
                        tick.addLine(to: point(164, angle))
                        context.stroke(tick, with: .color(tint.opacity(index % 10 == 0 ? 0.8 : 0.25)),
                                       lineWidth: index % 10 == 0 ? 1.5 : 0.6)
                    }
                    // Independent segmented orbits suggest depth without a solid central orb.
                    for band in 0..<4 {
                        let radius = Double(97 + band * 13)
                        let rotation = time * speed * (band % 2 == 0 ? 1 : -0.7)
                        for segment in 0..<3 {
                            let start = rotation + Double(segment * 120 + band * 23)
                            var arc = Path()
                            arc.addArc(center: center, radius: radius * unit,
                                       startAngle: .degrees(start), endAngle: .degrees(start + 64), clockwise: false)
                            context.stroke(arc, with: .color(tint.opacity(band == 1 ? 0.8 : 0.35)),
                                           style: StrokeStyle(lineWidth: band == 1 ? 2.5 : 1, lineCap: .butt))
                        }
                    }
                    // A luminous wire sphere, animated by the actual speech state.
                    let sphere = (65 + intensity * 5) * unit
                    for index in -3...3 {
                        let fraction = Double(index) / 4
                        let width = sphere * 2 * sqrt(1 - fraction * fraction)
                        let latitude = CGRect(x: center.x - width / 2,
                                              y: center.y + fraction * sphere - 7 * unit,
                                              width: width, height: 14 * unit)
                        context.stroke(Path(ellipseIn: latitude), with: .color(tint.opacity(0.28)), lineWidth: 0.7)
                    }
                    for index in 0..<6 {
                        let phase = Double(index) * .pi / 6 + time * 0.13
                        let width = max(2, abs(cos(phase)) * sphere * 2)
                        context.stroke(Path(ellipseIn: CGRect(x: center.x - width / 2, y: center.y - sphere,
                                                              width: width, height: sphere * 2)),
                                       with: .color(tint.opacity(0.3)), lineWidth: 0.7)
                    }
                    // Speech envelope uses native word timing; it is not a microphone meter.
                    for index in -18...18 {
                        let envelope = max(0, 1 - abs(Double(index)) / 19)
                        let wave = abs(sin(Double(index) * 1.7 + time * 6))
                        let height = 2 + envelope * (4 + intensity * 31) * wave
                        let x = center.x + Double(index) * 3 * unit
                        var bar = Path()
                        bar.move(to: CGPoint(x: x, y: center.y - height * unit / 2))
                        bar.addLine(to: CGPoint(x: x, y: center.y + height * unit / 2))
                        context.stroke(bar, with: .color(.white.opacity(0.8)), lineWidth: 1.2)
                    }
                    if state == .seeing {
                        let y = center.y + (reduceMotion ? 0 : sin(time * 1.6) * 64 * unit)
                        var scan = Path()
                        scan.move(to: CGPoint(x: center.x - 74 * unit, y: y))
                        scan.addLine(to: CGPoint(x: center.x + 74 * unit, y: y))
                        context.stroke(scan, with: .color(tint.opacity(0.8)), lineWidth: 1)
                    }
                }
                VStack {
                    HStack {
                        annotation("U / 01", subtitle: "COGNITIVE CORE")
                        Spacer()
                        annotation("NATIVE", subtitle: "VOICE ENGINE")
                    }
                    Spacer()
                    HStack {
                        annotation("CONTEXT", subtitle: state == .seeing ? "READING" : "ON DEMAND")
                        Spacer()
                        annotation("ULTRON", subtitle: state.rawValue.uppercased())
                    }
                }.padding(.horizontal, 16).padding(.vertical, 22)
                if state == .error {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 30, weight: .light)).foregroundStyle(.orange)
                        .padding(12).background(.black.opacity(0.9), in: Circle())
                }
            }.frame(maxWidth: .infinity).frame(height: 370)

        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("ULTRON core, \(state.rawValue)")
    }
}
