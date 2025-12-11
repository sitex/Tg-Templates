import SwiftUI

struct CodeInputView: View {
    let codeInfo: String
    @State private var code = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 24) {
            Text("Enter the code")
                .font(.title2)

            Text(codeInfo)
                .font(.caption)
                .foregroundColor(.secondary)

            TextField("12345", text: $code)
                .keyboardType(.numberPad)
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
                    Text("Verify")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(code.isEmpty || isLoading)
        }
        .padding()
    }

    private func submit() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                try await TelegramService.shared.sendCode(code)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

#Preview {
    CodeInputView(codeInfo: "Code sent via SMS")
}
