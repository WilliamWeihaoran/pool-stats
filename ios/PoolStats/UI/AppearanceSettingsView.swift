import SwiftUI

struct AppearanceSettingsView: View {
    @EnvironmentObject private var themeStore: ThemeStore

    var body: some View {
        SectionCard(title: "Appearance") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Themes")
                    .font(.caption)
                    .foregroundColor(Theme.muted)

                LazyVGrid(columns: Layout.twoColumn(), spacing: 10) {
                    ForEach(ThemeStyle.allCases) { style in
                        ThemeChoiceCard(style: style, isOn: themeStore.selectedTheme == style) {
                            themeStore.setTheme(style)
                        }
                    }
                }
            }
        }
    }
}

private struct ThemeChoiceCard: View {
    let style: ThemeStyle
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        let p = style.palette
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(style.label)
                            .font(.headline)
                            .foregroundColor(p.text)
                        Text(style.subtitle)
                            .font(.caption2)
                            .foregroundColor(p.muted)
                    }
                    Spacer(minLength: 0)
                    if isOn {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(p.purple)
                    }
                }
                RoundedRectangle(cornerRadius: 12)
                    .fill(p.panel)
                    .frame(height: 44)
                    .overlay(
                        VStack(spacing: 6) {
                            HStack(spacing: 6) {
                                Capsule().fill(p.purple.opacity(0.9)).frame(width: 30, height: 6)
                                Capsule().fill(p.teal.opacity(0.85)).frame(width: 18, height: 6)
                                Capsule().fill(p.red.opacity(0.85)).frame(width: 18, height: 6)
                            }
                            HStack {
                                Circle().fill(p.border).frame(width: 7, height: 7)
                                Spacer()
                                Capsule().fill(p.panel2).frame(width: 44, height: 8)
                            }
                            .padding(.horizontal, 8)
                        }
                    )
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isOn ? p.purple.opacity(0.12) : p.bg)
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(isOn ? p.purple : p.border, lineWidth: 0.9))
        }
        .buttonStyle(.plain)
    }
}
