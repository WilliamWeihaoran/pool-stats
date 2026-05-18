import SwiftUI

struct GoalActionOverlay: View {
    let goal: Goal
    let onEdit: () -> Void
    let onComplete: () -> Void
    let onArchive: () -> Void
    let onDelete: () -> Void
    let onReset: () -> Void
    let onDismiss: () -> Void

    private var archiveTitle: String {
        if goal.completedAt != nil { return "Reset goal" }
        return goal.isArchived ? "Unarchive" : "Archive"
    }

    private var archiveAccent: Color {
        goal.completedAt != nil ? Theme.purple : Theme.amber
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)

            VStack {
                Spacer(minLength: 0)
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(goal.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(Theme.text)
                        Text("Choose an action")
                            .font(.caption)
                            .foregroundColor(Theme.muted)
                    }

                    VStack(spacing: 8) {
                        GoalActionButton(title: "Edit", systemImage: "pencil", accent: Theme.teal, action: onEdit)
                        if goal.completedAt == nil {
                            GoalActionButton(title: "Complete", systemImage: "checkmark.seal.fill", accent: Theme.green, action: onComplete)
                        }
                        GoalActionButton(title: archiveTitle,
                                         systemImage: goal.completedAt != nil ? "arrow.counterclockwise" : (goal.isArchived ? "tray.and.arrow.down.fill" : "archivebox.fill"),
                                         accent: archiveAccent,
                                         action: goal.completedAt != nil ? onReset : onArchive)
                        GoalActionButton(title: "Delete", systemImage: "trash.fill", accent: Theme.red, destructive: true, action: onDelete)
                    }

                    Button("Cancel", action: onDismiss)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Theme.text2)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Theme.panel2.opacity(0.75))
                        .cornerRadius(14)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.border, lineWidth: 0.5))
                }
                .padding(16)
                .background(Theme.panel)
                .cornerRadius(22)
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(Theme.border, lineWidth: 0.5))
                .padding(.horizontal, Layout.pagePadding)
                .padding(.bottom, 12)
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: goal.id)
    }
}

struct GoalActionButton: View {
    let title: String
    let systemImage: String
    let accent: Color
    var destructive: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.caption.weight(.semibold))
                    .frame(width: 18)
                Text(LocalizedStringKey(title))
                    .font(.subheadline.weight(.semibold))
                Spacer(minLength: 0)
            }
            .foregroundColor(destructive ? Theme.red : accent)
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .background((destructive ? Theme.red : accent).opacity(0.10))
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke((destructive ? Theme.red : accent).opacity(0.45), lineWidth: 0.8))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct GoalCelebrationOverlay: View {
    let goal: Goal
    @State private var pulse = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()

            VStack(spacing: 14) {
                ZStack {
                    ForEach(0..<10, id: \.self) { idx in
                        Image(systemName: idx % 2 == 0 ? "sparkles" : "star.fill")
                            .font(.caption.weight(.bold))
                            .foregroundColor([Theme.green, Theme.purple, Theme.amber, Theme.teal, Theme.red][idx % 5])
                            .offset(
                                x: CGFloat(cos(Double(idx) * .pi / 5.0)) * (pulse ? 68 : 22),
                                y: CGFloat(sin(Double(idx) * .pi / 5.0)) * (pulse ? 68 : 22)
                            )
                            .opacity(pulse ? 0.95 : 0.35)
                            .scaleEffect(pulse ? 1.1 : 0.7)
                    }

                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(Theme.green)
                        .scaleEffect(pulse ? 1.0 : 0.75)
                }
                .frame(width: 140, height: 140)

                Text("Goal complete")
                    .font(.title3.bold())
                    .foregroundColor(Theme.text)

                Text(goal.title)
                    .font(.caption)
                    .foregroundColor(Theme.muted)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 240)
            }
            .padding(22)
            .background(Theme.panel)
            .cornerRadius(24)
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(Theme.border, lineWidth: 0.5))
            .padding(.horizontal, Layout.pagePadding * 2)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.18).repeatCount(4, autoreverses: true)) {
                pulse = true
            }
        }
        .transition(.opacity.combined(with: .scale))
    }
}

struct GoalResetPrompt: View {
    let goal: Goal
    let onReset: () -> Void
    let onLater: () -> Void

    private var suggestedTargetText: String {
        goal.metric.format(goal.metric.suggestedResetTarget(from: goal.target))
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()

            VStack {
                Spacer(minLength: 0)
                VStack(alignment: .leading, spacing: 12) {
                    Text("Reset this goal?")
                        .font(.title3.bold())
                        .foregroundColor(Theme.text)
                    Text(AppLanguageRuntime.localizedFormat("We can start a new version with a nudged target: %@.", suggestedTargetText))
                        .font(.caption)
                        .foregroundColor(Theme.muted)

                    Button {
                        onReset()
                    } label: {
                        HStack {
                            Text("Reset goal")
                            Spacer()
                            Image(systemName: "arrow.right.circle.fill")
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Theme.bg)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                        .background(Theme.purple)
                        .cornerRadius(14)
                    }
                    .buttonStyle(.plain)

                    Button {
                        onLater()
                    } label: {
                        Text("Not now")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(Theme.text2)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Theme.panel2.opacity(0.75))
                            .cornerRadius(14)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.border, lineWidth: 0.5))
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
                .background(Theme.panel)
                .cornerRadius(22)
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(Theme.border, lineWidth: 0.5))
                .padding(.horizontal, Layout.pagePadding)
                .padding(.bottom, 12)
            }
        }
        .transition(.opacity.combined(with: .scale))
    }
}
