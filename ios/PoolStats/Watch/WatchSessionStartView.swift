import SwiftUI

struct WatchSessionStartView: View {
    @EnvironmentObject private var client: WatchConnectivityClient

    @Binding var game: String
    @Binding var type: String
    @Binding var opponent: String
    @State private var showOpponentPicker = false

    private var opponents: [String] {
        let names = client.snapshot?.availableOpponents ?? ["Other"]
        return names.isEmpty ? ["Other"] : names
    }

    private let gameOptions = [("8ball", "8-ball"), ("9ball", "9-ball")]
    private let cardBackground = Color(red: 0.16, green: 0.16, blue: 0.17)

    private var canStart: Bool {
        !game.isEmpty
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Quick Log")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white.opacity(0.94))
                Spacer()
            }
            .padding(.top, -12)
            .padding(.bottom, 2)

            HStack(spacing: 8) {
                modeBadge
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(cardBackground))

                Button {
                    let idx = gameOptions.firstIndex(where: { $0.0 == game }) ?? 0
                    game = gameOptions[(idx + 1) % gameOptions.count].0
                    WKInterfaceDevice.current().play(.click)
                } label: {
                    gameBadge
                }
                .buttonStyle(.plain)
            }

            Button {
                showOpponentPicker = true
                WKInterfaceDevice.current().play(.click)
            } label: {
                HStack {
                    Text(opponent.isEmpty ? "Opponent" : opponent)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(opponent.isEmpty ? .white.opacity(0.4) : .teal)
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white.opacity(0.38))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(cardBackground))
            }
            .buttonStyle(.plain)

            Button {
                guard canStart else { return }
                WKInterfaceDevice.current().play(.start)
                type = "match"
                client.startSession(game: game, type: "match", opponent: opponent.isEmpty ? "Other" : opponent)
            } label: {
                Text("Start Session")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(canStart ? Color(red: 0.37, green: 0.92, blue: 0.83) : Color(white: 0.34))
                    )
                    .contentShape(RoundedRectangle(cornerRadius: 18))
            }
            .buttonStyle(.plain)
            .disabled(!canStart)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("")
        .onAppear { type = "match" }
        .sheet(isPresented: $showOpponentPicker) {
            WatchOpponentPickerSheet(opponents: opponents, selectedOpponent: $opponent)
        }
    }

    @ViewBuilder
    private func compactPickerButton<Content: View>(action: @escaping () -> Void, @ViewBuilder content: () -> Content) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                content()
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(cardBackground))
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var modeBadge: some View {
        Text("Match")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(Color(red: 0.37, green: 0.92, blue: 0.83))
    }

    private var gameBadge: some View {
        game == "8ball" ? AnyView(eightBall) : AnyView(nineBall)
    }

    private var eightBall: some View {
        ZStack {
            Circle().fill(Color.black)
                .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1.5))
            Circle()
                .fill(Color.white)
                .frame(width: 15)
                .overlay(Text("8").font(.system(size: 10, weight: .black)).foregroundStyle(.black))
        }
        .frame(width: 30, height: 30)
    }

    private var nineBall: some View {
        ZStack {
            Circle().fill(Color(red: 0.98, green: 0.82, blue: 0.12))
            GeometryReader { geo in
                Rectangle()
                    .fill(Color.white)
                    .frame(height: geo.size.height * 0.38)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
            }
            .clipShape(Circle())
            Circle()
                .fill(Color.white)
                .frame(width: 15)
                .overlay(Text("9").font(.system(size: 10, weight: .black)).foregroundStyle(.black))
        }
        .frame(width: 30, height: 30)
    }
}

struct WatchOpponentPickerSheet: View {
    let opponents: [String]
    @Binding var selectedOpponent: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Opponent")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                Spacer()
            }
            .padding(.horizontal, 4)
            .padding(.top, 2)

            List(opponents, id: \.self) { name in
                Button {
                    selectedOpponent = name
                    WKInterfaceDevice.current().play(.click)
                    dismiss()
                } label: {
                    HStack {
                        Text(name)
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        Spacer()
                        if selectedOpponent == name {
                            Image(systemName: "checkmark")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.teal)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(red: 0.12, green: 0.12, blue: 0.13))
                )
            }
            .listStyle(.carousel)
            .scrollContentBackground(.hidden)
            .background(Color.black)
        }
        .padding(.horizontal, 4)
        .background(Color.black.ignoresSafeArea())
    }
}
