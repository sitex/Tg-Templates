import Foundation
import WatchConnectivity

@MainActor
class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()

    @Published var templates: [WidgetTemplate] = []

    private var session: WCSession?

    private override init() {
        super.init()

        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }

        // Load cached templates from UserDefaults
        templates = UserDefaults.watchGroup.widgetTemplates
    }

    nonisolated private func processReceivedData(_ data: Data) {
        do {
            let decoded = try JSONDecoder().decode([WidgetTemplate].self, from: data)
            Task { @MainActor [weak self] in
                self?.templates = decoded
                // Also save to UserDefaults for persistence
                UserDefaults.watchGroup.widgetTemplates = decoded
            }
        } catch {
            print("WatchConnectivity decode error: \(error)")
        }
    }
}

extension WatchConnectivityManager: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // Check for any pending application context
        if let data = session.receivedApplicationContext["templates"] as? Data {
            processReceivedData(data)
        }
    }

    // Receive immediate messages
    nonisolated func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        processReceivedData(messageData)
    }

    // Receive application context updates
    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        if let data = applicationContext["templates"] as? Data {
            processReceivedData(data)
        }
    }
}
