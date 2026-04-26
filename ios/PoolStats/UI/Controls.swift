import SwiftUI

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

struct ChoiceButton: View {
    let label: String
    let isOn: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            Text(label)
                .font(.callout)
                .foregroundColor(isOn ? color : Theme.text2)
                .frame(maxWidth: .infinity)
                .frame(height: 34)
                .background(isOn ? color.opacity(0.20) : Theme.panel2)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(isOn ? color : Theme.border, lineWidth: 1))
        }
        .buttonStyle(PressScaleStyle())
    }
}

struct SmallToggleButton: View {
    let label: String
    let isOn: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            Text(label)
                .font(.caption2)
                .foregroundColor(isOn ? color : Theme.text2)
                .frame(maxWidth: .infinity)
                .frame(height: 28)
                .background(isOn ? color.opacity(0.20) : Theme.panel2)
                .cornerRadius(9)
                .overlay(RoundedRectangle(cornerRadius: 9).stroke(isOn ? color : Theme.border, lineWidth: 1))
        }
        .buttonStyle(PressScaleStyle())
    }
}

struct ErrorCounterTile: View {
    let label: String
    let value: Int
    let color: Color
    let increment: () -> Void
    let decrement: () -> Void

    @State private var valueScale: CGFloat = 1.0

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
                .scaleEffect(valueScale)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Theme.panel2)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 0.75))
        .onTapGesture {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            increment()
        }
        .onLongPressGesture(minimumDuration: 0.5) {
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            decrement()
        }
        .onChange(of: value) { _ in
            withAnimation(.spring(response: 0.18, dampingFraction: 0.45)) {
                valueScale = 1.28
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.spring(response: 0.22, dampingFraction: 0.65)) {
                    valueScale = 1.0
                }
            }
        }
    }
}

private struct PressScaleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
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

struct AppTabBar: View {
    @Binding var selection: AppTab

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Theme.border)
                .frame(height: 0.5)

            HStack(spacing: 0) {
                tabButton(.dashboard)
                tabButton(.goals)
                logButton
                tabButton(.drills)
                tabButton(.settings)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 4)
            .padding(.top, 2)
            .padding(.bottom, 0)
            .background(Theme.panel)
        }
        .frame(maxWidth: .infinity)
        .background(Theme.panel)
    }

    @ViewBuilder
    private func tabButton(_ tab: AppTab) -> some View {
        Button {
            selection = tab
        } label: {
            VStack(spacing: 2) {
                Image(systemName: tab.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 28, height: 20)
                    .foregroundColor(selection == tab ? Theme.purple : Theme.text2)
                Text(tab.label)
                    .font(.caption2.weight(.medium))
                    .foregroundColor(Theme.text2)
                    .lineLimit(1)
                    .frame(height: 14)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 46, alignment: .bottom)
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.label)
    }

    private var logButton: some View {
        Button {
            selection = .log
        } label: {
            Image(systemName: AppTab.log.icon)
                .font(.system(size: 18, weight: .bold))
                .frame(width: 42, height: 42)
                .foregroundColor(selection == .log ? Theme.bg : Theme.text2)
                .background(selection == .log ? Theme.purple : Theme.panel2)
                .clipShape(Circle())
                .overlay(Circle().stroke(selection == .log ? Theme.purple.opacity(0.5) : Theme.border, lineWidth: 1))
            .frame(maxWidth: .infinity)
            .frame(height: 46, alignment: .center)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Log")
    }
}

struct DiscreteRatingSlider: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    let activeColor: Color
    let trackColor: Color = Theme.border

    var body: some View {
        GeometryReader { geo in
            let minValue = range.lowerBound
            let maxValue = range.upperBound
            let count = max(maxValue - minValue, 1)
            let progress = CGFloat(value - minValue) / CGFloat(count)
            let width = max(0, geo.size.width - 22)
            let x = width * progress

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(trackColor)
                    .frame(height: 8)
                Capsule()
                    .fill(activeColor)
                    .frame(width: x + 11, height: 8)
                Circle()
                    .fill(activeColor)
                    .frame(width: 22, height: 22)
                    .overlay(Circle().stroke(Theme.bg, lineWidth: 2))
                    .offset(x: x)
                    .shadow(color: activeColor.opacity(0.25), radius: 4, x: 0, y: 2)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        value = Self.value(for: gesture.location.x, width: width, range: range)
                    }
            )
        }
        .frame(height: 22)
    }

    private static func value(for x: CGFloat, width: CGFloat, range: ClosedRange<Int>) -> Int {
        let minValue = range.lowerBound
        let maxValue = range.upperBound
        let count = max(maxValue - minValue, 1)
        let clamped = min(max(x, 0), max(width, 1))
        let raw = Int(round((clamped / max(width, 1)) * CGFloat(count))) + minValue
        return min(max(raw, minValue), maxValue)
    }
}
