import Foundation
import WatchConnectivity

@MainActor
class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()

    @Published var isReachable = false

    private var session: WCSession?

    private override init() {
        super.init()

        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }

    func sendTemplates(_ templates: [WidgetTemplate]) {
        guard let session = session,
              session.activationState == .activated else {
            return
        }

        do {
            let data = try JSONEncoder().encode(templates)

            // Use updateApplicationContext for persistent data
            // This ensures Watch gets data even if not currently reachable
            try session.updateApplicationContext(["templates": data])

            // Also send immediate message if reachable
            if session.isReachable {
                session.sendMessageData(data, replyHandler: nil) { error in
                    print("WatchConnectivity send error: \(error)")
                }
            }
        } catch {
            print("WatchConnectivity encode error: \(error)")
        }
    }
}

extension WatchConnectivityManager: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            self.isReachable = session.isReachable
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        // Reactivate session after switching watches
        session.activate()
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isReachable = session.isReachable
        }
    }
}
