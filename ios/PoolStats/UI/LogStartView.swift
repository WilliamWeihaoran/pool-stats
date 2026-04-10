import SwiftUI

struct LogStartView: View {
    @EnvironmentObject private var store: DataStore
    @Binding var label: String

    var body: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 2)
        return VStack(alignment: .leading, spacing: 10) {
            Text("Log a session")
                .font(.headline)
            TextField("Opponent / location (optional)", text: $label)
                .textFieldStyle(.roundedBorder)

            LogSectionCard(title: "Match") {
                LazyVGrid(columns: columns, spacing: 10) {
                    StartActionButton(label: "Match 8-ball", isPrimary: true) {
                        store.startSession(game: "8ball", type: "match", label: label.trimmingCharacters(in: .whitespaces))
                    }
                    StartActionButton(label: "Match 9-ball", isPrimary: false) {
                        store.startSession(game: "9ball", type: "match", label: label.trimmingCharacters(in: .whitespaces))
                    }
                }
            }

            LogSectionCard(title: "Practice") {
                LazyVGrid(columns: columns, spacing: 10) {
                    StartActionButton(label: "Practice 8-ball", isPrimary: true) {
                        store.startSession(game: "8ball", type: "practice", label: "")
                    }
                    StartActionButton(label: "Practice 9-ball", isPrimary: false) {
                        store.startSession(game: "9ball", type: "practice", label: "")
                    }
                }
            }
        }
    }
}

private struct StartActionButton: View {
    let label: String
    let isPrimary: Bool
    let action: () -> Void

    var body: some View {
        if isPrimary {
            Button("▶ \(label)", action: action)
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
        } else {
            Button("▶ \(label)", action: action)
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
        }
    }
}
