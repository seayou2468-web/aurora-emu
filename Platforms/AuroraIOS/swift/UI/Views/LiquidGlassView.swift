import SwiftUI

struct LiquidGlassView: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.05, blue: 0.06).ignoresSafeArea()

            // Dynamic Liquid Background for iOS 26
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    let now = timeline.date.timeIntervalSinceReferenceDate
                    context.addFilter(.blur(radius: 60))

                    for i in 0..<4 {
                        let x = size.width * (0.5 + 0.3 * cos(now * 0.5 + Double(i)))
                        let y = size.height * (0.5 + 0.3 * sin(now * 0.7 + Double(i)))
                        let rect = CGRect(x: x - 150, y: y - 150, width: 300, height: 300)

                        let color: Color = (i % 2 == 0) ? .purple : .indigo
                        context.fill(Path(ellipseIn: rect), with: .color(color.opacity(0.15)))
                    }
                }
            }
            .ignoresSafeArea()

            // Refractive Layer
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
                .overlay(
                    LinearGradient(colors: [.white.opacity(0.05), .clear], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
        }
    }
}
