import Foundation
import TDLibKit

@MainActor
class TelegramService: ObservableObject {
    static let shared = TelegramService()

    private let manager = TDLibClientManager()
    private var client: TDLibClient?

    @Published var authState: AuthState = .loading
    @Published var isReady = false

    enum AuthState: Equatable {
        case loading
        case waitingPhoneNumber
        case waitingCode(codeInfo: String)
        case waitingPassword(hint: String)
        case ready
        case error(String)
    }

    private init() {}

    func start() {
        client = manager.createClient { [weak self] data, client in
            Task { @MainActor in
                self?.handleUpdate(data: data, client: client)
            }
        }
    }

    private func handleUpdate(data: Data, client: TDLibClient) {
        do {
            let update = try client.decoder.decode(Update.self, from: data)
            switch update {
            case .updateAuthorizationState(let state):
                handleAuthState(state.authorizationState)
            default:
                break
            }
        } catch {
            print("Update decode error: \(error)")
        }
    }

    private func handleAuthState(_ state: AuthorizationState) {
        switch state {
        case .authorizationStateWaitTdlibParameters:
            setTdlibParameters()
        case .authorizationStateWaitPhoneNumber:
            authState = .waitingPhoneNumber
        case .authorizationStateWaitCode(let info):
            authState = .waitingCode(codeInfo: describeCodeType(info.codeInfo.type))
        case .authorizationStateWaitPassword(let info):
            authState = .waitingPassword(hint: info.passwordHint)
        case .authorizationStateReady:
            authState = .ready
            isReady = true
        case .authorizationStateClosed:
            authState = .loading
            isReady = false
        default:
            break
        }
    }

    private func describeCodeType(_ type: AuthenticationCodeType) -> String {
        switch type {
        case .authenticationCodeTypeTelegramMessage:
            return "Code sent via Telegram message"
        case .authenticationCodeTypeSms:
            return "Code sent via SMS"
        case .authenticationCodeTypeCall:
            return "Code will be delivered via phone call"
        case .authenticationCodeTypeFlashCall:
            return "Code will be delivered via flash call"
        case .authenticationCodeTypeMissedCall:
            return "Code will be the last digits of the calling number"
        case .authenticationCodeTypeFragment:
            return "Code sent via Fragment"
        case .authenticationCodeTypeFirebaseAndroid:
            return "Code verified via Firebase"
        case .authenticationCodeTypeFirebaseIos:
            return "Code verified via Firebase"
        case .authenticationCodeTypeSmsWord:
            return "Code is a word from SMS"
        case .authenticationCodeTypeSmsPhrase:
            return "Code is a phrase from SMS"
        }
    }

    private func setTdlibParameters() {
        Task {
            let documentsPath = FileManager.default
                .urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("tdlib")
                .path

            do {
                try await client?.setTdlibParameters(
                    apiHash: TelegramConfig.apiHash,
                    apiId: TelegramConfig.apiId,
                    applicationVersion: "1.0",
                    databaseDirectory: documentsPath,
                    databaseEncryptionKey: Data(),
                    deviceModel: "iPhone",
                    filesDirectory: documentsPath + "/files",
                    systemLanguageCode: "en",
                    systemVersion: "iOS 17",
                    useChatInfoDatabase: true,
                    useFileDatabase: true,
                    useMessageDatabase: true,
                    useSecretChats: false,
                    useTestDc: false
                )
            } catch {
                authState = .error(error.localizedDescription)
            }
        }
    }

    func sendPhoneNumber(_ phone: String) async throws {
        _ = try await client?.setAuthenticationPhoneNumber(
            phoneNumber: phone,
            settings: nil
        )
    }

    func sendCode(_ code: String) async throws {
        _ = try await client?.checkAuthenticationCode(code: code)
    }

    func sendPassword(_ password: String) async throws {
        _ = try await client?.checkAuthenticationPassword(password: password)
    }

    func logout() async throws {
        _ = try await client?.logOut()
    }
}
