import SwiftUI

struct SkillChipRow: View {
    let items: [String]
    let colorProvider: (String) -> Color

    var body: some View {
        ChipGrid(items: items) { item in drillBadge(item, color: colorProvider(item)) }
    }
}

struct DrillMistakeTagGrid: View {
    let options: [String]
    @Binding var selectedTags: Set<String>

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(options, id: \.self) { item in
                MistakeSquareButton(title: item, isOn: selectedTags.contains(item), color: drillColor(item)) {
                    if selectedTags.contains(item) {
                        selectedTags.remove(item)
                    } else {
                        selectedTags.insert(item)
                    }
                }
            }
        }
    }
}

private struct ChipGrid<Content: View>: View {
    let items: [String]
    let content: (String) -> Content

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 86), spacing: 7, alignment: .leading)], alignment: .leading, spacing: 7) {
            ForEach(items, id: \.self) { item in
                content(item).frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

func drillBadge(_ text: String, color: Color) -> some View {
    Text(text)
        .font(.caption2.weight(.bold))
        .foregroundColor(color)
        .lineLimit(1)
        .minimumScaleFactor(0.78)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(color.opacity(0.13))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(color.opacity(0.28), lineWidth: 0.5))
}
