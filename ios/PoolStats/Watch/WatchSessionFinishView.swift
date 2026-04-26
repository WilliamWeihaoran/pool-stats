import SwiftUI

struct WatchSessionFinishView: View {
    let session: WatchSession
    let onSave: (Int) -> Void
    let onDiscard: () -> Void

    @State private var rating: Double = 7
    @State private var showDiscardConfirmation = false
    @State private var savePressed = false
    @State private var discardPressed = false

    private var durationText: String {
        guard let d = session.durationSeconds, d > 0 else { return "--" }
        let m = d / 60
        return m > 0 ? "\(m)m" : "<1m"
    }

    private var winRateText: String? {
        let total = session.wins + session.losses
        guard total > 0, !session.isPractice else { return nil }
        return "\(Int(round(Double(session.wins) / Double(total) * 100)))%"
    }

    private var avgBreakBalls: String {
        let valid = session.racks.filter { $0.breakBalls >= 0 }
        guard !valid.isEmpty else { return "--" }
        let avg = Double(valid.map(\.breakBalls).reduce(0, +)) / Double(valid.count)
        return String(format: "%.1f", avg)
    }

    private var avgErrors: String {
        guard !session.racks.isEmpty else { return "--" }
        let total = session.racks.reduce(0) { $0 + $1.missCount + $1.badPosition + $1.fouls + $1.badSafety + $1.patternCount }
        let avg = Double(total) / Double(session.racks.count)
        return String(format: "%.1f", avg)
    }

    private var avgErrorsValue: Double {
        guard !session.racks.isEmpty else { return 0 }
        let total = session.racks.reduce(0) { $0 + $1.missCount + $1.badPosition + $1.fouls + $1.badSafety + $1.patternCount }
        return Double(total) / Double(session.racks.count)
    }

    private var ratingColor: Color {
        switch Int(rating) {
        case 1...3: .red
        case 4...6: .orange
        case 7...8: .yellow
        default: .green
        }
    }

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 10) {
                    if !session.isPractice {
                        HStack(spacing: 4) {
                            Spacer()
                            Text("\(session.wins)")
                                .font(.title2.weight(.bold))
                                .foregroundStyle(.green)
                            Text("–")
                                .font(.title2.weight(.bold))
                                .foregroundStyle(.white.opacity(0.4))
                            Text("\(session.losses)")
                                .font(.title2.weight(.bold))
                                .foregroundStyle(.red)
                            Spacer()
                        }
                        .padding(.top, 2)
                    }

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                        summaryTile("Duration", durationText, color: .white)
                        summaryTile("Avg Break", avgBreakBalls, color: Color(red: 0.98, green: 0.75, blue: 0.25))
                        summaryTile("Avg Err", avgErrors, color: avgErrorsValue > 0 ? .orange : Color.white.opacity(0.5))
                        if let wr = winRateText {
                            summaryTile("Win Rate", wr, color: .green)
                        }
                    }

                    VStack(spacing: 6) {
                        HStack {
                            Text("Performance")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.8))
                            Spacer()
                            Text("\(Int(rating))/10")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(ratingColor)
                                .contentTransition(.numericText())
                        }

                        GeometryReader { geo in
                            let barWidth = geo.size.width
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.white.opacity(0.12))
                                    .frame(height: 22)
                                Capsule()
                                    .fill(ratingColor.opacity(0.88))
                                    .frame(width: max(0, barWidth * (rating - 1) / 9.0), height: 22)
                                    .transaction { $0.animation = nil }
                                Text("\(Int(rating))")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                            }
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        let pct = max(0, min(1, value.location.x / barWidth))
                                        let newRating = (pct * 9.0 + 1).rounded()
                                        let clamped = max(1, min(10, newRating))
                                        if clamped != rating {
                                            rating = clamped
                                            WKInterfaceDevice.current().play(.click)
                                        }
                                    }
                            )
                        }
                        .frame(height: 22)
                    }

                    HStack(spacing: 6) {
                        Button {
                            WKInterfaceDevice.current().play(.success)
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.62)) { savePressed = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                                withAnimation(.spring(response: 0.24, dampingFraction: 0.78)) { savePressed = false }
                                onSave(Int(rating))
                            }
                        } label: {
                            Text("Save")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Capsule(style: .continuous).fill(Color.teal))
                                .scaleEffect(savePressed ? 0.94 : 1)
                                .shadow(color: Color.teal.opacity(savePressed ? 0.12 : 0.28), radius: savePressed ? 2 : 6, y: 2)
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity)

                        Button {
                            WKInterfaceDevice.current().play(.click)
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.62)) { discardPressed = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation(.spring(response: 0.24, dampingFraction: 0.78)) { discardPressed = false }
                                showDiscardConfirmation = true
                            }
                        } label: {
                            Text("Discard")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Capsule(style: .continuous).fill(Color.red.opacity(0.12)))
                                .overlay(Capsule(style: .continuous).stroke(Color.red.opacity(0.38), lineWidth: 1))
                                .scaleEffect(discardPressed ? 0.94 : 1)
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.top, 4)
                .padding(.bottom, 10)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            if showDiscardConfirmation {
                Color.black.opacity(0.62)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.18)) { showDiscardConfirmation = false }
                    }

                VStack(spacing: 10) {
                    Text("Discard Session?")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    HStack(spacing: 6) {
                        Button {
                            WKInterfaceDevice.current().play(.click)
                            withAnimation(.easeOut(duration: 0.18)) { showDiscardConfirmation = false }
                        } label: {
                            Text("Keep")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Capsule(style: .continuous).fill(Color.white.opacity(0.12)))
                        }
                        .buttonStyle(.plain)

                        Button {
                            WKInterfaceDevice.current().play(.failure)
                            withAnimation(.easeOut(duration: 0.12)) { showDiscardConfirmation = false }
                            onDiscard()
                        } label: {
                            Text("Discard")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Capsule(style: .continuous).fill(Color.red.opacity(0.14)))
                                .overlay(Capsule(style: .continuous).stroke(Color.red.opacity(0.4), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color(red: 0.08, green: 0.09, blue: 0.14))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                .padding(.horizontal, 8)
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
                .zIndex(5)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .navigationTitle("Summary")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
    }

    @ViewBuilder
    private func summaryTile(_ label: String, _ value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.callout.weight(.bold).monospacedDigit())
                .foregroundStyle(color)
                .lineLimit(1)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.48))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.07)))
    }
}
