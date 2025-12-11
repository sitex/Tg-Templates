import SwiftUI

struct PhoneInputView: View {
    @State private var phoneNumber = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 24) {
            Text("Enter your phone number")
                .font(.title2)

            TextField("+1234567890", text: $phoneNumber)
                .keyboardType(.phonePad)
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
                    Text("Continue")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(phoneNumber.isEmpty || isLoading)
        }
        .padding()
    }

    private func submit() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                try await TelegramService.shared.sendPhoneNumber(phoneNumber)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

#Preview {
    PhoneInputView()
}
