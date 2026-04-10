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
            Circle().stroke(Theme.border, lineWidth: 14)
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

struct RadarChart: View {
    let labels: [String]
    let values: [Int]
    let color: Color

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = size / 2
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

                let labelFont = Font.caption
                for i in 0..<count {
                    let angle = CGFloat(Double(i) / Double(count) * 2 * Double.pi - Double.pi / 2)
                    let lr = radius * 1.12
                    let lx = center.x + lr * cos(angle)
                    let ly = center.y + lr * sin(angle)
                    let label = labels.indices.contains(i) ? labels[i] : ""
                    var text = ctx.resolve(Text(label).font(labelFont).foregroundColor(Theme.muted))
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
