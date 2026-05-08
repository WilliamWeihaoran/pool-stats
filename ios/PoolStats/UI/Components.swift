import SwiftUI
import UIKit

struct AppBackButton: View {
    @Environment(\.dismiss) private var dismiss
    var label: String = "Back"
    var iconOnly: Bool = false
    var action: (() -> Void)? = nil

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            if let action {
                action()
            } else {
                dismiss()
            }
        } label: {
            HStack(spacing: 7) {
                Image(systemName: "chevron.left")
                    .font(.caption.weight(.bold))
                if !iconOnly {
                    Text(label)
                        .font(.subheadline.weight(.semibold))
                }
            }
            .foregroundColor(Theme.text2)
            .padding(.horizontal, iconOnly ? 0 : 11)
            .frame(width: iconOnly ? 34 : nil)
            .frame(height: 34)
            .background {
                if iconOnly {
                    Circle().fill(Theme.panel2.opacity(0.9))
                } else {
                    Capsule().fill(Theme.panel2.opacity(0.9))
                }
            }
            .overlay {
                if iconOnly {
                    Circle().stroke(Theme.border, lineWidth: 0.6)
                } else {
                    Capsule().stroke(Theme.border, lineWidth: 0.6)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

extension View {
    func appBackSwipeEnabled() -> some View {
        background(InteractivePopGestureEnabler().frame(width: 0, height: 0))
    }
}

private struct InteractivePopGestureEnabler: UIViewControllerRepresentable {
    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }

    func updateUIViewController(_ viewController: UIViewController, context: Context) {
        enablePopGesture(from: viewController, coordinator: context.coordinator)
        DispatchQueue.main.async {
            enablePopGesture(from: viewController, coordinator: context.coordinator)
        }
    }

    private func enablePopGesture(from viewController: UIViewController, coordinator: Coordinator) {
        guard let navigationController = viewController.nearestNavigationController,
              let gesture = navigationController.interactivePopGestureRecognizer else { return }
        coordinator.navigationController = navigationController
        gesture.delegate = coordinator
        gesture.isEnabled = true
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        weak var navigationController: UINavigationController?

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            (navigationController?.viewControllers.count ?? 0) > 1
        }
    }
}

private extension UIViewController {
    var nearestNavigationController: UINavigationController? {
        if let navigationController { return navigationController }
        if let navigationController = self as? UINavigationController { return navigationController }
        var parentController = parent
        while let current = parentController {
            if let navigationController = current.navigationController { return navigationController }
            if let navigationController = current as? UINavigationController { return navigationController }
            parentController = current.parent
        }
        return nil
    }
}
