# Telegram Templates iOS App - Implementation Plan

## Overview

Build an iOS app that allows users to send pre-defined template messages to Telegram groups with a single tap. The app uses TDLib for full Telegram client functionality (messages appear from the user's own account), supports editable templates with multiple target groups, includes iOS home screen widgets, and can attach geolocation to messages.

## Current State Analysis

This is a **greenfield project**. The repository https://github.com/sitex/Tg-Templates is empty and ready for initial commit.

**Existing files:**
- `.claude/` - Claude Code configuration
- `.gitignore` - Git ignore rules
- `thoughts/` - Research documentation

## Desired End State

A fully functional iOS app with:

1. **Telegram Authentication** - User logs in with their Telegram account
2. **Template Management** - Create, edit, delete message templates
3. **Group Selection** - Choose target Telegram group per template
4. **One-Tap Sending** - Tap template button → message sent instantly
5. **Geolocation** - Optional GPS coordinates attached to messages
6. **iOS Widgets** - Home screen buttons for instant sending without opening app

### Verification

- App builds and runs on iOS 17+ simulator and device
- User can authenticate with Telegram
- Templates persist across app restarts
- Messages appear in Telegram groups from user's account
- Widgets update and send messages correctly
- Location permission works and coordinates are accurate

## What We're NOT Doing

- macOS/iPadOS Catalyst support (iOS only for MVP)
- Cloud sync of templates (local storage only)
- Message history/log viewing
- Voice messages or media attachments
- Telegram calls or voice features
- Bot API integration (using TDLib only)
- Push notifications for incoming messages

## Implementation Approach

Use modern Swift stack:
- **SwiftUI** for all UI (iOS 17+)
- **TDLibKit** via Swift Package Manager for Telegram
- **SwiftData** for local persistence
- **WidgetKit** with App Groups for home screen widgets
- **CoreLocation** for geolocation

## Workflow

- **Git push after each phase** - Commit and push changes to `origin/main` after completing each phase

---

## Phase 1: Project Setup

### Overview
Create Xcode project with proper structure, add TDLibKit dependency, configure App Groups for widget data sharing.

### Changes Required:

#### 1. Create Xcode Project

**Action**: Create new Xcode project via Xcode IDE

- Product Name: `TgTemplates`
- Team: Your Apple Developer account
- Organization Identifier: `com.sitex`
- Bundle Identifier: `com.sitex.TgTemplates`
- Interface: SwiftUI
- Language: Swift
- Storage: SwiftData
- Minimum Deployment: iOS 17.0

#### 2. Add TDLibKit Dependency

**File**: `TgTemplates.xcodeproj` (via Xcode)

Add Swift Package:
- URL: `https://github.com/Swiftgram/TDLibKit`
- Version: Latest (1.5.x)

#### 3. Configure App Groups

**Action**: In Xcode Signing & Capabilities

1. Add "App Groups" capability to main target
2. Create group: `group.com.sitex.TgTemplates`
3. Later: Add same group to Widget extension

#### 4. Create Project Structure

```
TgTemplates/
├── TgTemplatesApp.swift          # App entry point
├── Config/
│   └── TelegramConfig.swift      # API credentials (gitignored)
├── Models/
│   ├── Template.swift            # SwiftData model
│   └── TelegramGroup.swift       # Group model
├── Services/
│   ├── TelegramService.swift     # TDLib wrapper
│   └── LocationService.swift     # CoreLocation wrapper
├── Views/
│   ├── ContentView.swift         # Main tab view
│   ├── Auth/
│   │   ├── AuthView.swift        # Auth flow container
│   │   ├── PhoneInputView.swift  # Phone number entry
│   │   └── CodeInputView.swift   # SMS code entry
│   ├── Templates/
│   │   ├── TemplateListView.swift    # Template grid
│   │   ├── TemplateEditView.swift    # Create/edit template
│   │   └── TemplateButtonView.swift  # Single template button
│   ├── Groups/
│   │   └── GroupPickerView.swift # Select target group
│   └── Settings/
│       └── SettingsView.swift    # App settings
├── Extensions/
│   └── UserDefaults+AppGroup.swift
└── Resources/
    └── Assets.xcassets
```

#### 5. Create Telegram Config File

**File**: `TgTemplates/Config/TelegramConfig.swift`

```swift
import Foundation

enum TelegramConfig {
    // Get these from https://my.telegram.org
    static let apiId: Int32 = 0 // Replace with your API ID
    static let apiHash = "" // Replace with your API Hash
}
```

#### 6. Update .gitignore

**File**: `.gitignore` - DONE

```gitignore
# Claude Code local settings
.claude/settings.local.json

# Xcode
*.xcodeproj/project.xcworkspace/
*.xcodeproj/xcuserdata/
*.xcworkspace/xcuserdata/
DerivedData/
*.hmap
*.ipa
*.dSYM.zip
*.dSYM

# Swift Package Manager
.build/
.swiftpm/

# Secrets
TgTemplates/Config/TelegramConfig.swift

# macOS
.DS_Store
```

### Success Criteria:

#### Automated Verification:
- [ ] Project builds without errors: `xcodebuild -scheme TgTemplates -sdk iphonesimulator build`
- [ ] TDLibKit package resolves successfully
- [ ] App launches in simulator

#### Manual Verification:
- [x] Project structure matches the plan (created on Linux)
- [ ] App Groups capability is configured (requires Xcode on macOS)
- [x] TelegramConfig.swift is gitignored

---

## Phase 2: Telegram Authentication

### Overview
Implement TDLib authentication flow: phone number → SMS code → optional 2FA password → ready state.

### Changes Required:

#### 1. Telegram Service

**File**: `TgTemplates/Services/TelegramService.swift`

```swift
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
            authState = .waitingCode(codeInfo: info.codeInfo.type.description)
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

    private func setTdlibParameters() {
        Task {
            let documentsPath = FileManager.default
                .urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("tdlib")
                .path

            try? await client?.setTdlibParameters(
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
```

#### 2. Auth View Container

**File**: `TgTemplates/Views/Auth/AuthView.swift`

```swift
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
```

#### 3. Phone Input View

**File**: `TgTemplates/Views/Auth/PhoneInputView.swift`

```swift
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
```

#### 4. Code Input View

**File**: `TgTemplates/Views/Auth/CodeInputView.swift`

```swift
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
```

#### 5. Password Input View (2FA)

**File**: `TgTemplates/Views/Auth/PasswordInputView.swift`

```swift
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
```

#### 6. App Entry Point

**File**: `TgTemplates/TgTemplatesApp.swift`

```swift
import SwiftUI
import SwiftData

@main
struct TgTemplatesApp: App {
    @StateObject private var telegram = TelegramService.shared

    var body: some Scene {
        WindowGroup {
            if telegram.isReady {
                ContentView()
            } else {
                AuthView()
            }
        }
        .modelContainer(for: [Template.self])
    }

    init() {
        TelegramService.shared.start()
    }
}
```

### Success Criteria:

#### Automated Verification:
- [ ] Project builds: `xcodebuild -scheme TgTemplates -sdk iphonesimulator build`
- [ ] No compiler warnings related to TDLibKit

#### Manual Verification:
- [ ] App shows phone number input on first launch
- [ ] After entering phone, SMS code screen appears
- [ ] After entering code, app shows "Authenticated" (or main screen)
- [ ] 2FA password screen works if account has 2FA enabled
- [ ] Auth state persists after app restart

---

## Phase 3: Data Models

### Overview
Create SwiftData models for templates and cached Telegram groups.

### Changes Required:

#### 1. Template Model

**File**: `TgTemplates/Models/Template.swift`

```swift
import Foundation
import SwiftData

@Model
final class Template {
    var id: UUID
    var name: String
    var icon: String // SF Symbol name
    var messageText: String
    var targetGroupId: Int64?
    var targetGroupName: String?
    var includeLocation: Bool
    var createdAt: Date
    var updatedAt: Date
    var sortOrder: Int

    init(
        name: String,
        icon: String = "paperplane.fill",
        messageText: String,
        targetGroupId: Int64? = nil,
        targetGroupName: String? = nil,
        includeLocation: Bool = false,
        sortOrder: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.messageText = messageText
        self.targetGroupId = targetGroupId
        self.targetGroupName = targetGroupName
        self.includeLocation = includeLocation
        self.createdAt = Date()
        self.updatedAt = Date()
        self.sortOrder = sortOrder
    }
}
```

#### 2. Telegram Group Model

**File**: `TgTemplates/Models/TelegramGroup.swift`

```swift
import Foundation

struct TelegramGroup: Identifiable, Codable, Hashable {
    let id: Int64
    let title: String
    let memberCount: Int

    var displayTitle: String {
        "\(title) (\(memberCount) members)"
    }
}
```

#### 3. App Group UserDefaults Extension

**File**: `TgTemplates/Extensions/UserDefaults+AppGroup.swift`

```swift
import Foundation

extension UserDefaults {
    static let appGroup = UserDefaults(suiteName: "group.com.sitex.TgTemplates")!

    private enum Keys {
        static let cachedGroups = "cachedGroups"
        static let cachedTemplates = "cachedTemplatesForWidget"
    }

    var cachedGroups: [TelegramGroup] {
        get {
            guard let data = data(forKey: Keys.cachedGroups),
                  let groups = try? JSONDecoder().decode([TelegramGroup].self, from: data) else {
                return []
            }
            return groups
        }
        set {
            let data = try? JSONEncoder().encode(newValue)
            set(data, forKey: Keys.cachedGroups)
        }
    }
}
```

### Success Criteria:

#### Automated Verification:
- [ ] Project builds successfully
- [ ] SwiftData container initializes without errors

#### Manual Verification:
- [ ] Template model can be created and saved
- [ ] Data persists across app restarts

---

## Phase 4: Group Selection

### Overview
Fetch user's Telegram groups/chats and allow selection for templates.

### Changes Required:

#### 1. Add Group Fetching to TelegramService

**File**: `TgTemplates/Services/TelegramService.swift` (add to existing)

```swift
// Add these methods to TelegramService class

@Published var groups: [TelegramGroup] = []

func fetchGroups() async throws {
    guard let client = client else { return }

    // Get chat list
    let chats = try await client.getChats(
        chatList: .chatListMain,
        limit: 100
    )

    var fetchedGroups: [TelegramGroup] = []

    for chatId in chats.chatIds {
        if let chat = try? await client.getChat(chatId: chatId) {
            // Only include groups and supergroups
            switch chat.type {
            case .chatTypeBasicGroup(let info):
                let fullInfo = try? await client.getBasicGroupFullInfo(
                    basicGroupId: info.basicGroupId
                )
                fetchedGroups.append(TelegramGroup(
                    id: chatId,
                    title: chat.title,
                    memberCount: fullInfo?.members.count ?? 0
                ))
            case .chatTypeSupergroup(let info):
                if !info.isChannel {
                    let fullInfo = try? await client.getSupergroupFullInfo(
                        supergroupId: info.supergroupId
                    )
                    fetchedGroups.append(TelegramGroup(
                        id: chatId,
                        title: chat.title,
                        memberCount: fullInfo?.memberCount ?? 0
                    ))
                }
            default:
                break
            }
        }
    }

    groups = fetchedGroups
    UserDefaults.appGroup.cachedGroups = fetchedGroups
}
```

#### 2. Group Picker View

**File**: `TgTemplates/Views/Groups/GroupPickerView.swift`

```swift
import SwiftUI

struct GroupPickerView: View {
    @ObservedObject var telegram = TelegramService.shared
    @Binding var selectedGroupId: Int64?
    @Binding var selectedGroupName: String?
    @Environment(\.dismiss) private var dismiss

    @State private var isLoading = true
    @State private var searchText = ""

    var filteredGroups: [TelegramGroup] {
        if searchText.isEmpty {
            return telegram.groups
        }
        return telegram.groups.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading groups...")
                } else if telegram.groups.isEmpty {
                    ContentUnavailableView(
                        "No Groups",
                        systemImage: "person.3",
                        description: Text("You're not a member of any groups")
                    )
                } else {
                    List(filteredGroups) { group in
                        Button {
                            selectedGroupId = group.id
                            selectedGroupName = group.title
                            dismiss()
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(group.title)
                                        .foregroundColor(.primary)
                                    Text("\(group.memberCount) members")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if selectedGroupId == group.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                    .searchable(text: $searchText, prompt: "Search groups")
                }
            }
            .navigationTitle("Select Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .task {
            do {
                try await telegram.fetchGroups()
            } catch {
                print("Error fetching groups: \(error)")
            }
            isLoading = false
        }
    }
}
```

### Success Criteria:

#### Automated Verification:
- [ ] Project builds successfully

#### Manual Verification:
- [ ] Groups load after authentication
- [ ] Search filters groups correctly
- [ ] Selected group is highlighted with checkmark
- [ ] Selection persists when picker is dismissed

---

## Phase 5: Template Management

### Overview
Build CRUD interface for templates with icon picker, text editor, and group selection.

### Changes Required:

#### 1. Template List View (Main Screen)

**File**: `TgTemplates/Views/Templates/TemplateListView.swift`

```swift
import SwiftUI
import SwiftData

struct TemplateListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Template.sortOrder) private var templates: [Template]

    @State private var showingAddTemplate = false
    @State private var templateToEdit: Template?

    let columns = [
        GridItem(.adaptive(minimum: 100), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                if templates.isEmpty {
                    ContentUnavailableView(
                        "No Templates",
                        systemImage: "doc.badge.plus",
                        description: Text("Tap + to create your first template")
                    )
                    .padding(.top, 100)
                } else {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(templates) { template in
                            TemplateButtonView(
                                template: template,
                                onLongPress: { templateToEdit = template }
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Templates")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddTemplate = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showingAddTemplate) {
                TemplateEditView(template: nil)
            }
            .sheet(item: $templateToEdit) { template in
                TemplateEditView(template: template)
            }
        }
    }
}
```

#### 2. Template Button View

**File**: `TgTemplates/Views/Templates/TemplateButtonView.swift`

```swift
import SwiftUI

struct TemplateButtonView: View {
    let template: Template
    let onLongPress: () -> Void

    @ObservedObject var telegram = TelegramService.shared
    @State private var isSending = false
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        Button {
            sendMessage()
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.2))
                        .frame(width: 60, height: 60)

                    if isSending {
                        ProgressView()
                    } else if showSuccess {
                        Image(systemName: "checkmark")
                            .font(.title2)
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: template.icon)
                            .font(.title2)
                            .foregroundColor(.accentColor)
                    }
                }

                Text(template.name)
                    .font(.caption)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 100, height: 100)
        }
        .buttonStyle(.plain)
        .onLongPressGesture {
            onLongPress()
        }
        .sensoryFeedback(.success, trigger: showSuccess)
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }

    private func sendMessage() {
        guard let groupId = template.targetGroupId else {
            errorMessage = "No group selected"
            showError = true
            return
        }

        isSending = true

        Task {
            do {
                try await telegram.sendTemplateMessage(template)
                showSuccess = true
                try await Task.sleep(for: .seconds(1))
                showSuccess = false
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isSending = false
        }
    }
}
```

#### 3. Template Edit View

**File**: `TgTemplates/Views/Templates/TemplateEditView.swift`

```swift
import SwiftUI
import SwiftData

struct TemplateEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let template: Template?

    @State private var name = ""
    @State private var icon = "paperplane.fill"
    @State private var messageText = ""
    @State private var targetGroupId: Int64?
    @State private var targetGroupName: String?
    @State private var includeLocation = false

    @State private var showingIconPicker = false
    @State private var showingGroupPicker = false

    private var isEditing: Bool { template != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Template Info") {
                    TextField("Name", text: $name)

                    Button {
                        showingIconPicker = true
                    } label: {
                        HStack {
                            Text("Icon")
                            Spacer()
                            Image(systemName: icon)
                                .foregroundColor(.accentColor)
                        }
                    }
                }

                Section("Message") {
                    TextEditor(text: $messageText)
                        .frame(minHeight: 100)
                }

                Section("Target Group") {
                    Button {
                        showingGroupPicker = true
                    } label: {
                        HStack {
                            Text("Group")
                            Spacer()
                            Text(targetGroupName ?? "Select...")
                                .foregroundColor(targetGroupName == nil ? .secondary : .primary)
                        }
                    }
                }

                Section("Options") {
                    Toggle("Include Location", isOn: $includeLocation)
                }

                if isEditing {
                    Section {
                        Button("Delete Template", role: .destructive) {
                            deleteTemplate()
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Template" : "New Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveTemplate() }
                        .disabled(name.isEmpty || messageText.isEmpty || targetGroupId == nil)
                }
            }
            .sheet(isPresented: $showingIconPicker) {
                IconPickerView(selectedIcon: $icon)
            }
            .sheet(isPresented: $showingGroupPicker) {
                GroupPickerView(
                    selectedGroupId: $targetGroupId,
                    selectedGroupName: $targetGroupName
                )
            }
            .onAppear {
                if let template = template {
                    name = template.name
                    icon = template.icon
                    messageText = template.messageText
                    targetGroupId = template.targetGroupId
                    targetGroupName = template.targetGroupName
                    includeLocation = template.includeLocation
                }
            }
        }
    }

    private func saveTemplate() {
        if let template = template {
            template.name = name
            template.icon = icon
            template.messageText = messageText
            template.targetGroupId = targetGroupId
            template.targetGroupName = targetGroupName
            template.includeLocation = includeLocation
            template.updatedAt = Date()
        } else {
            let newTemplate = Template(
                name: name,
                icon: icon,
                messageText: messageText,
                targetGroupId: targetGroupId,
                targetGroupName: targetGroupName,
                includeLocation: includeLocation
            )
            modelContext.insert(newTemplate)
        }

        dismiss()
    }

    private func deleteTemplate() {
        if let template = template {
            modelContext.delete(template)
        }
        dismiss()
    }
}
```

#### 4. Icon Picker View

**File**: `TgTemplates/Views/Templates/IconPickerView.swift`

```swift
import SwiftUI

struct IconPickerView: View {
    @Binding var selectedIcon: String
    @Environment(\.dismiss) private var dismiss

    let icons = [
        "paperplane.fill", "location.fill", "car.fill", "bed.double.fill",
        "fork.knife", "cup.and.saucer.fill", "figure.walk", "figure.run",
        "bicycle", "tram.fill", "airplane", "house.fill",
        "building.2.fill", "cart.fill", "bag.fill", "creditcard.fill",
        "phone.fill", "envelope.fill", "calendar", "clock.fill",
        "sun.max.fill", "moon.fill", "cloud.fill", "bolt.fill",
        "heart.fill", "star.fill", "flag.fill", "bookmark.fill",
        "tag.fill", "folder.fill", "doc.fill", "pencil",
        "checkmark.circle.fill", "xmark.circle.fill", "exclamationmark.triangle.fill", "info.circle.fill"
    ]

    let columns = [GridItem(.adaptive(minimum: 50))]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(icons, id: \.self) { icon in
                        Button {
                            selectedIcon = icon
                            dismiss()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(selectedIcon == icon ? Color.accentColor : Color.gray.opacity(0.2))
                                    .frame(width: 50, height: 50)

                                Image(systemName: icon)
                                    .font(.title2)
                                    .foregroundColor(selectedIcon == icon ? .white : .primary)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Choose Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
```

### Success Criteria:

#### Automated Verification:
- [ ] Project builds successfully

#### Manual Verification:
- [ ] Can create new template with all fields
- [ ] Can edit existing template
- [ ] Can delete template
- [ ] Icon picker shows grid of SF Symbols
- [ ] Group picker allows selecting target group
- [ ] Long press on template opens edit view

---

## Phase 6: Message Sending with Geolocation

### Overview
Implement message sending via TDLib with optional geolocation attachment.

### Changes Required:

#### 1. Location Service

**File**: `TgTemplates/Services/LocationService.swift`

```swift
import Foundation
import CoreLocation

class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationService()

    private let manager = CLLocationManager()

    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    private var locationContinuation: CheckedContinuation<CLLocation, Error>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = manager.authorizationStatus
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func getCurrentLocation() async throws -> CLLocation {
        if authorizationStatus == .notDetermined {
            requestPermission()
        }

        guard authorizationStatus == .authorizedWhenInUse ||
              authorizationStatus == .authorizedAlways else {
            throw LocationError.notAuthorized
        }

        return try await withCheckedThrowingContinuation { continuation in
            locationContinuation = continuation
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            currentLocation = location
            locationContinuation?.resume(returning: location)
            locationContinuation = nil
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationContinuation?.resume(throwing: error)
        locationContinuation = nil
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }

    enum LocationError: LocalizedError {
        case notAuthorized

        var errorDescription: String? {
            switch self {
            case .notAuthorized:
                return "Location access not authorized"
            }
        }
    }
}
```

#### 2. Add Location Permission to Info.plist

**File**: `TgTemplates/Info.plist` (add keys)

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>To attach your location to template messages</string>
```

#### 3. Add Send Message to TelegramService

**File**: `TgTemplates/Services/TelegramService.swift` (add method)

```swift
// Add to TelegramService class

func sendTemplateMessage(_ template: Template) async throws {
    guard let client = client,
          let groupId = template.targetGroupId else {
        throw TelegramError.noGroupSelected
    }

    var messageText = template.messageText

    // Add location if enabled
    if template.includeLocation {
        do {
            let location = try await LocationService.shared.getCurrentLocation()
            let lat = location.coordinate.latitude
            let lon = location.coordinate.longitude
            let mapsUrl = "https://maps.google.com/?q=\(lat),\(lon)"
            messageText += "\n\n📍 \(mapsUrl)"
        } catch {
            print("Location error: \(error)")
            // Continue without location
        }
    }

    let inputContent = InputMessageContent.inputMessageText(
        InputMessageText(
            clearDraft: true,
            linkPreviewOptions: nil,
            text: FormattedText(entities: [], text: messageText)
        )
    )

    _ = try await client.sendMessage(
        chatId: groupId,
        inputMessageContent: inputContent,
        messageThreadId: 0,
        options: nil,
        replyMarkup: nil,
        replyTo: nil
    )
}

enum TelegramError: LocalizedError {
    case noGroupSelected
    case notAuthenticated

    var errorDescription: String? {
        switch self {
        case .noGroupSelected:
            return "No target group selected"
        case .notAuthenticated:
            return "Not authenticated with Telegram"
        }
    }
}
```

### Success Criteria:

#### Automated Verification:
- [ ] Project builds successfully
- [ ] Location permission key present in Info.plist

#### Manual Verification:
- [ ] Tapping template button sends message to correct group
- [ ] Message appears in Telegram from user's account
- [ ] Location is appended when "Include Location" is enabled
- [ ] Location permission prompt appears on first use
- [ ] Error shown if no group selected

---

## Phase 7: iOS Widgets

### Overview
Create WidgetKit extension with template buttons on home screen. Widget reads cached data from App Groups.

### Changes Required:

#### 1. Create Widget Extension

**Action**: In Xcode, File > New > Target > Widget Extension

- Product Name: `TgTemplatesWidget`
- Include Configuration App Intent: Yes
- Add to "TgTemplates" project and target

#### 2. Configure Widget App Group

**Action**: In Xcode Signing & Capabilities for Widget target

Add same App Group: `group.com.sitex.TgTemplates`

#### 3. Widget Data Model (Shared)

**File**: `TgTemplatesWidget/WidgetTemplate.swift`

```swift
import Foundation
import AppIntents

struct WidgetTemplate: Codable, Identifiable {
    let id: UUID
    let name: String
    let icon: String
    let messageText: String
    let targetGroupId: Int64?
    let targetGroupName: String?
    let includeLocation: Bool
}

extension UserDefaults {
    static let widgetGroup = UserDefaults(suiteName: "group.com.sitex.TgTemplates")!

    var widgetTemplates: [WidgetTemplate] {
        get {
            guard let data = data(forKey: "widgetTemplates"),
                  let templates = try? JSONDecoder().decode([WidgetTemplate].self, from: data) else {
                return []
            }
            return templates
        }
        set {
            let data = try? JSONEncoder().encode(newValue)
            set(data, forKey: "widgetTemplates")
        }
    }
}
```

#### 4. Update Main App to Cache Templates

**File**: `TgTemplates/Views/Templates/TemplateListView.swift` (add to existing)

```swift
// Add this method and call it when templates change
private func syncWidgetData() {
    let widgetTemplates = templates.map { template in
        WidgetTemplate(
            id: template.id,
            name: template.name,
            icon: template.icon,
            messageText: template.messageText,
            targetGroupId: template.targetGroupId,
            targetGroupName: template.targetGroupName,
            includeLocation: template.includeLocation
        )
    }
    UserDefaults.appGroup.widgetTemplates = widgetTemplates

    // Reload widgets
    WidgetCenter.shared.reloadAllTimelines()
}
```

#### 5. Widget Intent for Sending Messages

**File**: `TgTemplatesWidget/SendTemplateIntent.swift`

```swift
import AppIntents
import WidgetKit

struct SendTemplateIntent: AppIntent {
    static var title: LocalizedStringResource = "Send Template"
    static var description = IntentDescription("Sends a template message to Telegram")

    @Parameter(title: "Template ID")
    var templateId: String

    init() {}

    init(templateId: UUID) {
        self.templateId = templateId.uuidString
    }

    func perform() async throws -> some IntentResult {
        // Deep link to main app to send
        // Widget cannot run TDLib directly
        guard let url = URL(string: "tgtemplates://send?id=\(templateId)") else {
            return .result()
        }

        // This will open the main app
        await UIApplication.shared.open(url)

        return .result()
    }
}
```

#### 6. Widget View

**File**: `TgTemplatesWidget/TgTemplatesWidget.swift`

```swift
import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> TemplateEntry {
        TemplateEntry(date: Date(), templates: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (TemplateEntry) -> Void) {
        let templates = UserDefaults.widgetGroup.widgetTemplates
        completion(TemplateEntry(date: Date(), templates: Array(templates.prefix(4))))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TemplateEntry>) -> Void) {
        let templates = UserDefaults.widgetGroup.widgetTemplates
        let entry = TemplateEntry(date: Date(), templates: Array(templates.prefix(4)))
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

struct TemplateEntry: TimelineEntry {
    let date: Date
    let templates: [WidgetTemplate]
}

struct TgTemplatesWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        if entry.templates.isEmpty {
            Text("No templates")
                .font(.caption)
                .foregroundColor(.secondary)
        } else {
            switch family {
            case .systemSmall:
                smallWidget
            case .systemMedium:
                mediumWidget
            default:
                mediumWidget
            }
        }
    }

    var smallWidget: some View {
        if let first = entry.templates.first {
            Button(intent: SendTemplateIntent(templateId: first.id)) {
                VStack {
                    Image(systemName: first.icon)
                        .font(.largeTitle)
                    Text(first.name)
                        .font(.caption)
                }
            }
            .buttonStyle(.plain)
        } else {
            Text("Add template")
        }
    }

    var mediumWidget: some View {
        HStack(spacing: 16) {
            ForEach(entry.templates.prefix(4)) { template in
                Button(intent: SendTemplateIntent(templateId: template.id)) {
                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .fill(Color.accentColor.opacity(0.2))
                                .frame(width: 44, height: 44)
                            Image(systemName: template.icon)
                                .font(.title2)
                        }
                        Text(template.name)
                            .font(.caption2)
                            .lineLimit(1)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
    }
}

@main
struct TgTemplatesWidget: Widget {
    let kind: String = "TgTemplatesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TgTemplatesWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Templates")
        .description("Quick access to your Telegram templates")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
```

#### 7. Handle Deep Link in Main App

**File**: `TgTemplates/TgTemplatesApp.swift` (update)

```swift
import SwiftUI
import SwiftData
import WidgetKit

@main
struct TgTemplatesApp: App {
    @StateObject private var telegram = TelegramService.shared

    var body: some Scene {
        WindowGroup {
            if telegram.isReady {
                ContentView()
                    .onOpenURL { url in
                        handleDeepLink(url)
                    }
            } else {
                AuthView()
            }
        }
        .modelContainer(for: [Template.self])
    }

    init() {
        TelegramService.shared.start()
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "tgtemplates",
              url.host == "send",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let idString = components.queryItems?.first(where: { $0.name == "id" })?.value,
              let templateId = UUID(uuidString: idString) else {
            return
        }

        // Post notification to send template
        NotificationCenter.default.post(
            name: .sendTemplate,
            object: nil,
            userInfo: ["templateId": templateId]
        )
    }
}

extension Notification.Name {
    static let sendTemplate = Notification.Name("sendTemplate")
}
```

#### 8. Register URL Scheme

**File**: `TgTemplates/Info.plist` (add)

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>tgtemplates</string>
        </array>
    </dict>
</array>
```

### Success Criteria:

#### Automated Verification:
- [ ] Main app builds successfully
- [ ] Widget extension builds successfully

#### Manual Verification:
- [ ] Widget appears in widget gallery
- [ ] Widget shows template buttons
- [ ] Tapping widget button opens app and sends message
- [ ] Widget updates when templates change in main app

---

## Phase 8: Polish & Error Handling

### Overview
Add loading states, error handling, haptic feedback, and settings view.

### Changes Required:

#### 1. Content View (Main Tab Container)

**File**: `TgTemplates/Views/ContentView.swift`

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        TemplateListView()
    }
}
```

#### 2. Settings View

**File**: `TgTemplates/Views/Settings/SettingsView.swift`

```swift
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
```

#### 3. Error View Component

**File**: `TgTemplates/Views/Auth/ErrorView.swift`

```swift
import SwiftUI

struct ErrorView: View {
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundColor(.red)

            Text("Error")
                .font(.title2)

            Text(message)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                TelegramService.shared.start()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
```

### Success Criteria:

#### Automated Verification:
- [ ] Project builds without warnings
- [ ] All views compile successfully

#### Manual Verification:
- [ ] Settings show correct connection status
- [ ] Logout works and returns to auth screen
- [ ] Location permission status displays correctly
- [ ] Haptic feedback on successful send
- [ ] Error messages are user-friendly

---

## Testing Strategy

### Unit Tests
- Template model creation and properties
- UserDefaults encoding/decoding for widget data
- Location service authorization states

### Integration Tests
- TelegramService authentication flow (mock TDLib)
- Template persistence with SwiftData
- Widget data synchronization

### Manual Testing Steps
1. Fresh install → Auth flow completes successfully
2. Create template → Appears in list
3. Tap template → Message sent to correct group
4. Enable location → Coordinates appear in message
5. Add widget to home screen → Shows templates
6. Tap widget → Opens app and sends message
7. Kill app → Relaunch maintains auth state
8. Edit template → Changes reflected in widget
9. Delete template → Removed from widget
10. Logout → Returns to auth screen

---

## Performance Considerations

- TDLibKit downloads ~300MB binary; app size will be significant
- TDLib initializes asynchronously; show loading state
- Widget cannot run TDLib; must use deep links to main app
- Location requests should timeout after 10 seconds
- Cache groups list to avoid repeated API calls

---

## References

- Research document: `thoughts/shared/research/2025-12-11-telegram-templates-iphone-app.md`
- TDLibKit: https://github.com/Swiftgram/TDLibKit
- Telegram API credentials: https://my.telegram.org
- WidgetKit: https://developer.apple.com/documentation/widgetkit
- SwiftData: https://developer.apple.com/documentation/swiftdata
