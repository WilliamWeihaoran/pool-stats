import SwiftUI

struct WatchMatchScoreFlash: Equatable {
    let wins: Int
    let losses: Int
    let rackSeconds: Int?
}

struct WatchMatchScoreFlashView: View {
    let flash: WatchMatchScoreFlash
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 4) {
                Text("Score")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.5))
                    .textCase(.uppercase)
                    .kerning(1.2)

                HStack(alignment: .center, spacing: 0) {
                    scoreColumn(
                        score: flash.wins,
                        label: "Me",
                        color: Color(red: 0.37, green: 0.92, blue: 0.83)
                    )

                    Text("–")
                        .font(.system(size: 32, weight: .light))
                        .foregroundStyle(.white.opacity(0.3))

                    scoreColumn(
                        score: flash.losses,
                        label: "Opp",
                        color: Color(red: 0.97, green: 0.44, blue: 0.44)
                    )
                }

                if let seconds = flash.rackSeconds {
                    Text(String(format: "Rack  %d:%02d", seconds / 60, seconds % 60))
                        .font(.caption2.weight(.semibold).monospacedDigit())
                        .foregroundStyle(.white.opacity(0.55))
                }

                Text("Tap to continue")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.28))
                    .padding(.top, 4)
            }
            .padding(.horizontal, 12)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onDismiss)
    }

    private func scoreColumn(score: Int, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(score)")
                .font(.system(size: numberSize, weight: .black, design: .rounded).monospacedDigit())
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.48)
                .allowsTightening(true)
                .contentTransition(.numericText())
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(color.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }

    private var numberSize: CGFloat {
        let highScore = max(flash.wins, flash.losses)
        if highScore >= 100 { return 38 }
        if highScore >= 10 { return 50 }
        return 64
    }
}
