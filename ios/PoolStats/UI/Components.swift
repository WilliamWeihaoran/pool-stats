import SwiftUI
import UIKit

struct AppBackButton: View {
    @Environment(\.dismiss) private var dismiss
    var label: String = "Back"
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
                Text(label)
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundColor(Theme.text2)
            .padding(.horizontal, 11)
            .frame(height: 34)
            .background(Theme.panel2.opacity(0.9))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Theme.border, lineWidth: 0.6))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Back")
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
