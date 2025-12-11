import SwiftUI

struct AuthView: View {
    @ObservedObject var telegram = TelegramService.shared

    var body: some View {
        NavigationStack {
            Group {
                switch telegram.authState {
                case .loading:
                    ProgressView("Connecting to Telegram...")
                case .waitingPhoneNumber:
                    PhoneInputView()
                case .waitingCode(let info):
                    CodeInputView(codeInfo: info)
                case .waitingPassword(let hint):
                    PasswordInputView(hint: hint)
                case .ready:
                    Text("Authenticated!")
                case .error(let message):
                    ErrorView(message: message)
                }
            }
            .navigationTitle("Telegram Login")
        }
    }
}

#Preview {
    AuthView()
}
