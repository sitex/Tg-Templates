import SwiftUI

struct PasswordInputView: View {
    let hint: String
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 24) {
            Text("Two-Factor Authentication")
                .font(.title2)

            if !hint.isEmpty {
                Text("Hint: \(hint)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)

            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            Button(action: submit) {
                if isLoading {
                    ProgressView()
                } else {
                    Text("Submit")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(password.isEmpty || isLoading)
        }
        .padding()
    }

    private func submit() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                try await TelegramService.shared.sendPassword(password)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

#Preview {
    PasswordInputView(hint: "Your hint here")
}
