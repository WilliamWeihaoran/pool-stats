import SwiftUI

struct DifficultyGradientSlider: View {
    let levels: [DrillDifficulty]
    @Binding var selectedLevel: DrillDifficultyLevel

    var selectedIndex: Int { levels.firstIndex(where: { $0.level == selectedLevel }) ?? 0 }

    var body: some View {
        VStack(spacing: 9) {
            GeometryReader { geo in
                let count = max(levels.count, 1)
                let inset: CGFloat = 14
                let width = max(geo.size.width - inset * 2, 1)
                let step = count > 1 ? width / CGFloat(count - 1) : 0
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(LinearGradient(colors: [Theme.green, Theme.amber, Theme.red], startPoint: .leading, endPoint: .trailing))
                        .frame(width: width, height: 10)
                        .position(x: inset + width / 2, y: 20)
                        .opacity(0.9)
                    ForEach(Array(levels.enumerated()), id: \.element.id) { idx, difficulty in
                        Circle()
                            .fill(selectedIndex == idx ? Color.white : Theme.bg)
                            .overlay(Circle().stroke(difficultyColor(for: difficulty.level), lineWidth: selectedIndex == idx ? 3 : 2))
                            .frame(width: selectedIndex == idx ? 26 : 18, height: selectedIndex == idx ? 26 : 18)
                            .position(x: inset + CGFloat(idx) * step, y: 20)
                    }
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let x = min(max(value.location.x - inset, 0), width)
                            let idx = min(max(Int(round(x / max(step, 1))), 0), count - 1)
                            selectedLevel = levels[idx].level
                        }
                )
            }
            .frame(height: 40)

            HStack(spacing: 4) {
                ForEach(levels) { difficulty in
                    Text(difficulty.level.label)
                        .font(.system(size: 9, weight: difficulty.level == selectedLevel ? .black : .semibold))
                        .foregroundColor(difficulty.level == selectedLevel ? difficultyColor(for: difficulty.level) : Theme.muted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.55)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

struct PottedAttemptSlider: View {
    @Binding var value: Double
    let maxValue: Int

    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { geo in
                let inset: CGFloat = 10
                let width = max(geo.size.width - inset * 2, 1)
                let total = max(maxValue, 1)
                let step = width / CGFloat(total)
                let selected = min(max(Int(value.rounded()), 0), total)
                let selectedX = inset + CGFloat(selected) * step
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Theme.border.opacity(0.7))
                        .frame(width: width, height: 7)
                        .position(x: inset + width / 2, y: 18.5)
                    Capsule()
                        .fill(LinearGradient(colors: [Theme.red, Theme.amber, Theme.green], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(7, selectedX - inset), height: 7)
                        .position(x: inset + max(7, selectedX - inset) / 2, y: 18.5)
                    ForEach(0...total, id: \.self) { idx in
                        Circle()
                            .fill(idx <= selected ? Theme.green.opacity(0.88) : Theme.panel)
                            .frame(width: 9, height: 9)
                            .position(x: inset + CGFloat(idx) * step, y: 18.5)
                    }
                    Circle()
                        .fill(Color.white)
                        .overlay(Circle().stroke(Theme.green, lineWidth: 3))
                        .frame(width: 24, height: 24)
                        .position(x: selectedX, y: 18.5)
                        .shadow(color: Theme.green.opacity(0.35), radius: 6, y: 2)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { drag in
                            let x = min(max(drag.location.x - inset, 0), width)
                            value = Double(min(max(Int(round(x / max(step, 1))), 0), total))
                        }
                )
            }
            .frame(height: 38)

            HStack {
                Text("0")
                Spacer()
                Text("Target \(maxValue)")
            }
            .font(.caption2.weight(.semibold))
            .foregroundColor(Theme.muted)
        }
    }
}

struct FilterSkillButton: View {
    let skill: String
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(skill)
                .font(.caption.weight(.bold))
                .foregroundColor(isOn ? .black.opacity(0.82) : drillColor(skill))
                .padding(.horizontal, 11)
                .padding(.vertical, 8)
                .background(isOn ? drillColor(skill) : drillColor(skill).opacity(0.12))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(drillColor(skill).opacity(0.32), lineWidth: 0.6))
        }
        .buttonStyle(.plain)
    }
}

struct MistakeSquareButton: View {
    let title: String
    let isOn: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 10, weight: .black))
                .foregroundColor(isOn ? .black.opacity(0.82) : color)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(isOn ? color : color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(isOn ? 0.55 : 0.28), lineWidth: 0.8))
        }
        .buttonStyle(.plain)
    }
}

struct DrillInfoTile: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.caption2.weight(.bold))
                .foregroundColor(Theme.muted)
            Text(value)
                .font(.title3.bold())
                .foregroundColor(color)
                .monospacedDigit()
        }
        .frame(width: 92, alignment: .leading)
        .padding(12)
        .background(Theme.panel2)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.border, lineWidth: 0.5))
    }
}

func drillColor(_ name: String) -> Color {
    switch name.lowercased() {
    case "potting", "red": return Theme.red
    case "position", "blue": return Theme.blue
    case "pattern", "teal": return Theme.teal
    case "runout", "purple": return Theme.purple
    case "overall", "fundamentals", "green": return Theme.green
    case "break", "orange", "yellow", "amber": return Theme.amber
    default: return Theme.text2
    }
}

func difficultyColor(for level: DrillDifficultyLevel) -> Color {
    switch level {
    case .beginner: return Theme.green
    case .easy: return Theme.teal
    case .standard: return Theme.amber
    case .hard: return Color.orange
    case .expert: return Theme.red
    }
}
