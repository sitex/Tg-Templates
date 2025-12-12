import SwiftUI

struct ApiConfigView: View {
    @Binding var isConfigured: Bool

    @State private var apiIdText = ""
    @State private var apiHash = ""
    @State private var showingError = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "key.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)

                Text("Telegram API Setup")
                    .font(.title)
                    .fontWeight(.bold)

                Text("To use this app, you need to provide your Telegram API credentials.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("API ID")
                            .font(.headline)
                        TextField("Enter API ID", text: $apiIdText)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("API Hash")
                            .font(.headline)
                        SecureField("Enter API Hash", text: $apiHash)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                .padding(.horizontal)

                Button(action: saveCredentials) {
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canSave ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(!canSave)
                .padding(.horizontal)

                Spacer()

                Link(destination: URL(string: "https://my.telegram.org")!) {
                    Label("Get credentials at my.telegram.org", systemImage: "arrow.up.right.square")
                        .font(.footnote)
                }
                .padding(.bottom)
            }
            .padding(.top, 40)
            .navigationBarTitleDisplayMode(.inline)
            .alert("Invalid Credentials", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please enter a valid API ID and API Hash.")
            }
        }
    }

    private var canSave: Bool {
        guard let apiId = Int32(apiIdText), apiId > 0 else { return false }
        return !apiHash.isEmpty && apiHash.count >= 20
    }

    private func saveCredentials() {
        guard let apiId = Int32(apiIdText), apiId > 0, !apiHash.isEmpty else {
            showingError = true
            return
        }

        TelegramConfig.apiId = apiId
        TelegramConfig.apiHash = apiHash
        isConfigured = true
    }
}

#Preview {
    ApiConfigView(isConfigured: .constant(false))
}
