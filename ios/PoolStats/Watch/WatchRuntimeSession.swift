import Foundation
import WatchKit

@MainActor
final class WatchRuntimeSession: NSObject, ObservableObject {
    @Published private(set) var isActive: Bool = false

    private var session: WKExtendedRuntimeSession?

    func start() {
        #if targetEnvironment(simulator)
        isActive = false
        return
        #else
        guard session == nil else { return }
        let next = WKExtendedRuntimeSession()
        next.delegate = self
        next.start()
        session = next
        #endif
    }

    func stop() {
        #if targetEnvironment(simulator)
        isActive = false
        return
        #else
        session?.invalidate()
        session = nil
        isActive = false
        #endif
    }
}

extension WatchRuntimeSession: WKExtendedRuntimeSessionDelegate {
    nonisolated func extendedRuntimeSession(
        _ extendedRuntimeSession: WKExtendedRuntimeSession,
        didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason,
        error: Error?
    ) {
        Task { @MainActor in
            self.session = nil
            self.isActive = false
        }
    }

    nonisolated func extendedRuntimeSessionDidStart(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        Task { @MainActor in
            self.isActive = true
        }
    }

    nonisolated func extendedRuntimeSessionWillExpire(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        Task { @MainActor in
            self.session = nil
            let next = WKExtendedRuntimeSession()
            next.delegate = self
            next.start()
            self.session = next
        }
    }
}
