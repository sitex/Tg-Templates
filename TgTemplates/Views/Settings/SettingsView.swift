import SwiftUI

struct SettingsView: View {
    @ObservedObject var telegram = TelegramService.shared
    @ObservedObject var location = LocationService.shared

    @State private var showingLogoutConfirm = false

    var body: some View {
        Form {
            Section("Account") {
                HStack {
                    Text("Status")
                    Spacer()
                    Text(telegram.isReady ? "Connected" : "Disconnected")
                        .foregroundColor(telegram.isReady ? .green : .red)
                }

                Button("Log Out", role: .destructive) {
                    showingLogoutConfirm = true
                }
            }

            Section("Permissions") {
                HStack {
                    Text("Location")
                    Spacer()
                    Text(locationStatusText)
                        .foregroundColor(locationStatusColor)
                }

                if location.authorizationStatus == .notDetermined {
                    Button("Grant Location Access") {
                        location.requestPermission()
                    }
                }
            }

            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
        .confirmationDialog(
            "Log Out",
            isPresented: $showingLogoutConfirm,
            titleVisibility: .visible
        ) {
            Button("Log Out", role: .destructive) {
                Task {
                    try? await telegram.logout()
                }
            }
        } message: {
            Text("Are you sure you want to log out of Telegram?")
        }
    }

    var locationStatusText: String {
        switch location.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return "Enabled"
        case .denied, .restricted:
            return "Denied"
        case .notDetermined:
            return "Not Set"
        @unknown default:
            return "Unknown"
        }
    }

    var locationStatusColor: Color {
        switch location.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return .green
        case .denied, .restricted:
            return .red
        default:
            return .secondary
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
