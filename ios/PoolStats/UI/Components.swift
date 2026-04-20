import SwiftUI
import Charts

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

// MARK: - Layout constants

enum Layout {
    static let pagePadding: CGFloat = 14
    static let cardSpacing: CGFloat = 14
    static let gridSpacing: CGFloat = 10

    static func twoColumn() -> [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: gridSpacing), count: 2)
    }

    static func columns(hSizeClass: UserInterfaceSizeClass?) -> [GridItem] {
        let count = hSizeClass == .regular ? 3 : 2
        return Array(repeating: GridItem(.flexible(), spacing: gridSpacing), count: count)
    }

    static let chartSm: CGFloat = 180
    static let chartMd: CGFloat = 200
    static let chartLg: CGFloat = 220
    static let chartRadar: CGFloat = 240

    static func chartHeight(_ base: CGFloat, hSizeClass: UserInterfaceSizeClass?) -> CGFloat {
        hSizeClass == .regular ? base * 1.4 : base
    }
}

// MARK: - Session display helper

extension Session {
    var resultAccentColor: Color {
        if isPractice { return Theme.muted }
        if wins > losses { return Theme.green }
        if losses > wins { return Theme.red }
        if isDraw { return Theme.amber }
        return Theme.border
    }
}

// MARK: - Log section card

struct LogSectionCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Capsule()
                    .fill(Theme.border)
                    .frame(width: 18, height: 3)
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Theme.text2)
                Spacer(minLength: 0)
            }
            content
        }
        .padding(12)
        .background(Theme.panel)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border.opacity(0.75), lineWidth: 0.5))
    }
}

// MARK: - Log choice buttons

struct ChoiceButton: View {
    let label: String
    let isOn: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.callout)
                .foregroundColor(isOn ? color : Theme.text2)
                .frame(maxWidth: .infinity)
                .frame(height: 34)
                .background(isOn ? color.opacity(0.20) : Theme.panel2)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(isOn ? color : Theme.border, lineWidth: 1))
        }
    }
}

struct SmallToggleButton: View {
    let label: String
    let isOn: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption2)
                .foregroundColor(isOn ? color : Theme.text2)
                .frame(maxWidth: .infinity)
                .frame(height: 28)
                .background(isOn ? color.opacity(0.20) : Theme.panel2)
                .cornerRadius(9)
                .overlay(RoundedRectangle(cornerRadius: 9).stroke(isOn ? color : Theme.border, lineWidth: 1))
        }
    }
}

struct ErrorCounterTile: View {
    let label: String
    let value: Int
    let color: Color
    let increment: () -> Void
    let decrement: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(color.opacity(0.92))
                Spacer(minLength: 0)
                Circle()
                    .fill(color.opacity(0.6))
                    .frame(width: 6, height: 6)
            }
            Text("\(value)")
                .font(.title2)
                .foregroundColor(Theme.text)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Theme.panel2)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 0.75))
        .onTapGesture(perform: increment)
        .onLongPressGesture(minimumDuration: 0.5, perform: decrement)
    }
}

struct MiniStatCard: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(Theme.muted)
            Text(value)
                .font(.headline)
                .foregroundColor(Theme.text)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.panel)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border, lineWidth: 0.5))
    }
}

struct RadarChart: View {
    let labels: [String]
    let values: [Int]
    let color: Color

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2 + 4)
            let radius = max(0, size / 2 - 28)
            let count = max(labels.count, 1)

            Canvas { ctx, _ in
                for i in 1...4 {
                    let r = radius * CGFloat(i) / 4.0
                    var ring = Path()
                    for j in 0..<count {
                        let angle = CGFloat(Double(j) / Double(count) * 2 * Double.pi - Double.pi / 2)
                        let pt = CGPoint(x: center.x + r * cos(angle), y: center.y + r * sin(angle))
                        if j == 0 { ring.move(to: pt) } else { ring.addLine(to: pt) }
                    }
                    ring.closeSubpath()
                    ctx.stroke(ring, with: .color(Theme.border), lineWidth: 1)
                }

                var poly = Path()
                for (i, v) in values.enumerated() {
                    let angle = CGFloat(Double(i) / Double(count) * 2 * Double.pi - Double.pi / 2)
                    let r = radius * CGFloat(v) / 100.0
                    let pt = CGPoint(x: center.x + r * cos(angle), y: center.y + r * sin(angle))
                    if i == 0 { poly.move(to: pt) } else { poly.addLine(to: pt) }
                }
                poly.closeSubpath()
                ctx.fill(poly, with: .color(color.opacity(0.2)))
                ctx.stroke(poly, with: .color(color), lineWidth: 2)

                let labelFont = Font.caption2
                for i in 0..<count {
                    let angle = CGFloat(Double(i) / Double(count) * 2 * Double.pi - Double.pi / 2)
                    let lr = radius * 1.22
                    let lx = center.x + lr * cos(angle)
                    let ly = center.y + lr * sin(angle)
                    let label = labels.indices.contains(i) ? labels[i] : ""
                    let text = ctx.resolve(Text(label).font(labelFont).foregroundColor(Theme.muted))
                    let size = text.measure(in: CGSize(width: 200, height: 20))
                    let drawPoint = CGPoint(x: lx - size.width / 2, y: ly - size.height / 2)
                    ctx.draw(text, at: drawPoint, anchor: .topLeading)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 220)
    }
}
