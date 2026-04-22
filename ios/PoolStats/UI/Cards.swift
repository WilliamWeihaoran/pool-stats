import SwiftUI

struct StatCard: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(Theme.muted)
            Text(value)
                .font(.title2)
                .foregroundColor(Theme.text)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.panel)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border, lineWidth: 0.5))
    }
}

struct SectionCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(Theme.text2)
            content
        }
        .padding(14)
        .background(Theme.panel)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 0.5))
    }
}

struct PillButton: View {
    let label: String
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption)
                .foregroundColor(isOn ? Theme.purple : Theme.muted)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(isOn ? Theme.panel2 : Color.clear)
                .cornerRadius(7)
                .overlay(RoundedRectangle(cornerRadius: 7).stroke(Theme.border, lineWidth: 0.5))
        }
    }
}

struct SegmentedRow<Item: Hashable>: View {
    let items: [Item]
    @Binding var selection: Item
    let label: (Item) -> String

    var body: some View {
        HStack(spacing: 6) {
            ForEach(items, id: \.self) { item in
                Button {
                    selection = item
                } label: {
                    Text(label(item))
                        .font(.caption)
                        .foregroundColor(selection == item ? Theme.text : Theme.muted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(selection == item ? Theme.panel2 : Color.clear)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(Theme.panel)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border, lineWidth: 0.5))
    }
}

struct SegmentedGrid<Item: Hashable>: View {
    let items: [Item]
    let columns: Int
    @Binding var selection: Item
    let label: (Item) -> String

    var body: some View {
        let grid = Array(repeating: GridItem(.flexible(), spacing: 6), count: columns)
        LazyVGrid(columns: grid, spacing: 6) {
            ForEach(items, id: \.self) { item in
                Button {
                    selection = item
                } label: {
                    Text(label(item))
                        .font(.caption)
                        .foregroundColor(selection == item ? Theme.text : Theme.muted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(selection == item ? Theme.panel2 : Color.clear)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(Theme.panel)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border, lineWidth: 0.5))
    }
}

struct FilterMenuButton<Item: Hashable>: View {
    let title: String
    let items: [Item]
    @Binding var selection: Item
    let label: (Item) -> String

    var body: some View {
        Menu {
            ForEach(items, id: \.self) { item in
                Button {
                    selection = item
                } label: {
                    HStack {
                        Text(label(item))
                        Spacer()
                        if selection == item {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 10) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(Theme.muted)
                Spacer(minLength: 8)
                Text(label(selection))
                    .font(.caption)
                    .foregroundColor(Theme.text)
                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(Theme.muted)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Theme.panel)
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border, lineWidth: 0.5))
        }
    }
}

struct MiniLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption2)
            .foregroundColor(Theme.muted)
    }
}

struct PercentageBar: View {
    let value: Int
    let color: Color
    var height: CGFloat = 6

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle().fill(Theme.border).frame(height: height)
                Rectangle().fill(color).frame(width: geo.size.width * CGFloat(value) / 100.0, height: height)
            }
            .cornerRadius(height / 2)
        }
        .frame(height: height)
    }
}

struct BufferedPaceBar: View {
    let value: Int
    let bufferColor: Color
    let activeColor: Color
    var bufferPercent: Int = 75
    var height: CGFloat = 6

    var body: some View {
        GeometryReader { geo in
            let total = CGFloat(min(max(value, 0), 100)) / 100.0
            let bufferWidth = geo.size.width * CGFloat(min(max(bufferPercent, 0), 100)) / 100.0
            let totalWidth = geo.size.width * total
            let activeWidth = max(0, totalWidth - bufferWidth)

            ZStack(alignment: .leading) {
                Rectangle().fill(Theme.border).frame(height: height)
                Rectangle()
                    .fill(bufferColor)
                    .frame(width: min(totalWidth, bufferWidth), height: height)
                Rectangle()
                    .fill(activeColor)
                    .frame(width: activeWidth, height: height)
                    .offset(x: min(totalWidth, bufferWidth))
            }
            .cornerRadius(height / 2)
        }
        .frame(height: height)
    }
}

struct RingChart: View {
    let wins: Int
    let losses: Int

    var body: some View {
        let total = max(wins + losses, 1)
        let winFrac = Double(wins) / Double(total)
        ZStack {
            Circle().stroke(Theme.red.opacity(0.35), lineWidth: 14)
            Circle()
                .trim(from: 0, to: winFrac)
                .stroke(Theme.teal, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 2) {
                Text("\(wins)")
                    .font(.title3)
                    .foregroundColor(Theme.text)
                Text("Wins")
                    .font(.caption)
                    .foregroundColor(Theme.muted)
            }
        }
        .frame(height: 120)
    }
}
