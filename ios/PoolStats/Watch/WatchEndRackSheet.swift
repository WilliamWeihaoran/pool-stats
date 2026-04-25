import SwiftUI

struct EndRackSheet: View {
    private enum SubmissionAction { case nextRack, saveAndExit }

    let isPractice: Bool
    let breakerIsMe: Bool
    let breakQualityBalls: Int
    let onSaveRack: (String?, Bool, Bool) -> Void
    let onSaveAndExit: (String?, Bool, Bool) -> Void
    let onClose: () -> Void

    @State private var selectedResult: String? = nil
    @State private var runoutFirst: Bool = false
    @State private var submissionAction: SubmissionAction?

    private var canSave: Bool { isPractice || selectedResult != nil }
    private var breakAndRun: Bool { runoutFirst && breakerIsMe && breakQualityBalls >= 1 }
    private var runoutEnabled: Bool { selectedResult == "won" }
    private var isSubmitting: Bool { submissionAction != nil }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 7) {
                    if !isPractice {
                        HStack(spacing: 7) {
                            resultButton("Won", selected: selectedResult == "won", color: .green) {
                                WKInterfaceDevice.current().play(.click)
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                                    selectedResult = "won"
                                }
                            }
                            resultButton("Lost", selected: selectedResult == "lost", color: .red) {
                                WKInterfaceDevice.current().play(.click)
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                                    selectedResult = "lost"
                                    runoutFirst = false
                                }
                            }
                        }

                        runoutCard
                    }

                    VStack(spacing: 7) {
                        actionButton("Next Rack", color: .teal, prominent: true, disabled: !canSave || isSubmitting) {
                            guard submissionAction == nil else { return }
                            submissionAction = .nextRack
                            WKInterfaceDevice.current().play(.success)
                            onSaveRack(selectedResult, runoutFirst, breakAndRun)
                        }

                        actionButton("Save & Exit", color: .red, prominent: false, disabled: !canSave || isSubmitting) {
                            guard submissionAction == nil else { return }
                            submissionAction = .saveAndExit
                            WKInterfaceDevice.current().play(.click)
                            onSaveAndExit(selectedResult, runoutFirst, breakAndRun)
                        }
                    }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 8)
            }
            .scrollIndicators(.hidden)
            .navigationTitle(isPractice ? "Finish Rack" : "Result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        WKInterfaceDevice.current().play(.click)
                        onClose()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
            .background(Color.black.ignoresSafeArea())
        }
    }

    @ViewBuilder
    private var runoutCard: some View {
        Button {
            guard runoutEnabled else { return }
            WKInterfaceDevice.current().play(.click)
            withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                runoutFirst.toggle()
            }
        } label: {
            HStack(spacing: 8) {
                Text("Runout")
                    .font(.caption.weight(.semibold))
                Spacer()
                Image(systemName: runoutFirst ? "checkmark.circle.fill" : "circle")
                    .font(.title3.weight(.semibold))
            }
            .foregroundStyle(runoutEnabled ? (runoutFirst ? Color.black.opacity(0.82) : Color.yellow.opacity(0.95)) : Color.secondary.opacity(0.55))
            .padding(.horizontal, 11)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(runoutFirst ? Color.yellow : Color.white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(runoutEnabled ? Color.yellow.opacity(runoutFirst ? 0.95 : 0.28) : Color.white.opacity(0.08), lineWidth: 1)
            )
            .opacity(runoutEnabled ? 1 : 0.72)
            .scaleEffect(runoutFirst ? 1.02 : 1)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func resultButton(_ title: String, selected: Bool, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(selected ? Color.black.opacity(0.84) : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(selected ? color : Color.white.opacity(0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(selected ? color.opacity(0.95) : Color.white.opacity(0.09), lineWidth: 1)
                )
                .scaleEffect(selected ? 1.03 : 1)
                .shadow(color: selected ? color.opacity(0.28) : .clear, radius: 10, y: 4)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func actionButton(_ title: String, color: Color, prominent: Bool, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(prominent ? .headline.weight(.semibold) : .subheadline.weight(.semibold))
                .foregroundStyle(prominent || disabled ? .white : color)
                .frame(maxWidth: .infinity)
                .padding(.vertical, prominent ? 8 : 6)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(disabled ? Color(white: 0.24) : (prominent ? color : color.opacity(0.16)))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(disabled ? Color.clear : color.opacity(prominent ? 0 : 0.4), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.72 : 1)
    }
}
