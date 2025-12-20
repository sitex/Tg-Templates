# CarPlay Interface Implementation Plan

## Overview

Add Apple CarPlay support to TgTemplates, allowing users to send pre-configured Telegram message templates directly from their car's infotainment system. The implementation uses `CPGridTemplate` for a button-based interface (up to 8 templates) with Siri voice integration for hands-free operation.

## Current State Analysis

**Existing Architecture:**
- iOS app uses SwiftUI `@main` lifecycle (`TgTemplatesApp.swift`)
- Data shared via App Group: `group.com.sitex.TgTemplates`
- Templates stored in `UserDefaults.appGroup.widgetTemplates` as `[WidgetTemplate]`
- `TelegramService.shared` handles message sending with `@MainActor` isolation
- Location support via `LocationService.shared.getCurrentLocation()`

**Key Files:**
- `TgTemplates/TgTemplatesApp.swift:1-88` - App entry point
- `TgTemplates/Services/TelegramService.swift:232-270` - `sendTemplateMessage(WidgetTemplate)`
- `TgTemplates/Extensions/UserDefaults+AppGroup.swift:25-37` - Template storage
- `TgTemplates/Info.plist` - No scene manifest currently
- `TgTemplates/TgTemplates.entitlements` - Only App Groups

**CarPlay Differs from watchOS:**
- CarPlay is an additional scene in the same iOS target (not a separate target)
- Shares the same `TelegramService.shared` instance
- No inter-process communication needed
- Must configure `UIApplicationSceneManifest` in Info.plist

## Desired End State

After implementation:
1. App appears in CarPlay dashboard when connected to compatible vehicle/simulator
2. CarPlay displays up to 8 templates as grid buttons with icons
3. Tapping a template sends the message and shows success/error alert
4. Location is included for templates with `includeLocation: true`
5. Siri can send templates via voice command: "Hey Siri, send [template name] with TgTemplates"
6. Works in Xcode CarPlay Simulator for development/testing

**Verification:**
- App launches in CarPlay Simulator (Window > Devices and Simulators > CarPlay)
- Grid displays configured templates with correct icons
- Sending a template shows success alert
- Siri shortcut appears in Shortcuts app after sending

## What We're NOT Doing

- **CPTabBarTemplate navigation** - Single grid view is sufficient
- **Template editing from CarPlay** - Read-only, templates managed from iPhone
- **Real-time template sync** - Templates load on CarPlay connect
- **Custom CarPlay icons** - Using SF Symbols only
- **Waiting for entitlement approval** - Code structure first, entitlement later

## Implementation Approach

CarPlay uses a scene-based architecture separate from the main SwiftUI app. We'll:
1. Configure Info.plist for multiple scenes (iPhone + CarPlay)
2. Create a `CarPlaySceneDelegate` that implements `CPTemplateApplicationSceneDelegate`
3. Use `CPGridTemplate` with `CPGridButton` for each template
4. Wrap TelegramService calls in `Task { @MainActor in ... }` for thread safety
5. Add Siri Intents for voice-activated sending

---

## Phase 1: Info.plist Scene Configuration

### Overview
Configure the app to support multiple scenes: the main iPhone UI and CarPlay interface.

### Changes Required:

#### 1. Disable Auto-Generated Scene Manifest
**Action**: In Xcode Build Settings

1. Open project in Xcode
2. Select TgTemplates target
3. Build Settings > Search "Application Scene Manifest"
4. Set "Generate Info.plist File" to **No** (if using auto-generation)
5. Or set "Application Scene Manifest (Generation)" to **Disabled**

#### 2. Update Info.plist
**File**: `TgTemplates/Info.plist`
**Changes**: Add UIApplicationSceneManifest with both scene configurations

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>ITSAppUsesNonExemptEncryption</key>
	<false/>
	<key>CFBundleIconName</key>
	<string>AppIcon</string>
	<key>NSLocationWhenInUseUsageDescription</key>
	<string>To attach your location to template messages</string>
	<key>CFBundleURLTypes</key>
	<array>
		<dict>
			<key>CFBundleTypeRole</key>
			<string>Editor</string>
			<key>CFBundleURLName</key>
			<string>com.sitex.TgTemplates</string>
			<key>CFBundleURLSchemes</key>
			<array>
				<string>tgtemplates</string>
			</array>
		</dict>
	</array>
	<key>UIApplicationSceneManifest</key>
	<dict>
		<key>UIApplicationSupportsMultipleScenes</key>
		<true/>
		<key>UISceneConfigurations</key>
		<dict>
			<key>CPTemplateApplicationSceneSessionRoleApplication</key>
			<array>
				<dict>
					<key>UISceneClassName</key>
					<string>CPTemplateApplicationScene</string>
					<key>UISceneConfigurationName</key>
					<string>CarPlay</string>
					<key>UISceneDelegateClassName</key>
					<string>$(PRODUCT_MODULE_NAME).CarPlaySceneDelegate</string>
				</dict>
			</array>
			<key>UIWindowSceneSessionRoleApplication</key>
			<array>
				<dict>
					<key>UISceneClassName</key>
					<string>UIWindowScene</string>
					<key>UISceneConfigurationName</key>
					<string>Default Configuration</string>
					<key>UISceneDelegateClassName</key>
					<string>$(PRODUCT_MODULE_NAME).SceneDelegate</string>
				</dict>
			</array>
		</dict>
	</dict>
</dict>
</plist>
```

#### 3. Create iPhone SceneDelegate
**File**: `TgTemplates/SceneDelegate.swift` (new file)
**Purpose**: Handle iPhone scene lifecycle for SwiftUI app

```swift
import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = UIHostingController(rootView: RootView())
        self.window = window
        window.makeKeyAndVisible()
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        handleDeepLink(url)
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "tgtemplates",
              url.host == "send",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let idString = components.queryItems?.first(where: { $0.name == "id" })?.value,
              let templateId = UUID(uuidString: idString) else {
            return
        }

        NotificationCenter.default.post(
            name: .sendTemplate,
            object: nil,
            userInfo: ["templateId": templateId]
        )
    }
}
```

#### 4. Create RootView Wrapper
**File**: `TgTemplates/Views/RootView.swift` (new file)
**Purpose**: Extract root view logic from TgTemplatesApp for SceneDelegate use

```swift
import SwiftUI
import SwiftData

struct RootView: View {
    @StateObject private var telegram = TelegramService.shared
    @Environment(\.scenePhase) private var scenePhase
    @State private var isConfigured = TelegramConfig.isConfigured

    var body: some View {
        Group {
            if !isConfigured {
                ApiConfigView(isConfigured: $isConfigured)
            } else if telegram.isReady {
                ContentView()
                    .onOpenURL { url in
                        handleDeepLink(url)
                    }
                    .onAppear {
                        checkPendingTemplate()
                    }
            } else {
                AuthView()
            }
        }
        .modelContainer(for: [Template.self])
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                checkPendingTemplate()
            }
        }
        .onChange(of: isConfigured) { _, configured in
            if configured {
                TelegramService.shared.start()
            }
        }
    }

    private func checkPendingTemplate() {
        let defaults = UserDefaults(suiteName: "group.com.sitex.TgTemplates")
        guard let idString = defaults?.string(forKey: "pendingTemplateId"),
              let templateId = UUID(uuidString: idString) else {
            return
        }

        defaults?.removeObject(forKey: "pendingTemplateId")

        NotificationCenter.default.post(
            name: .sendTemplate,
            object: nil,
            userInfo: ["templateId": templateId]
        )
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "tgtemplates",
              url.host == "send",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let idString = components.queryItems?.first(where: { $0.name == "id" })?.value,
              let templateId = UUID(uuidString: idString) else {
            return
        }

        NotificationCenter.default.post(
            name: .sendTemplate,
            object: nil,
            userInfo: ["templateId": templateId]
        )
    }
}
```

#### 5. Update TgTemplatesApp.swift
**File**: `TgTemplates/TgTemplatesApp.swift`
**Changes**: Simplify to just initialization, remove UI code (moved to RootView)

```swift
import SwiftUI
import SwiftData
import WidgetKit

@main
struct TgTemplatesApp: App {

    init() {
        // Initialize WatchConnectivity early
        _ = WatchConnectivityManager.shared

        if TelegramConfig.isConfigured {
            TelegramService.shared.start()
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [Template.self])
    }
}

extension Notification.Name {
    static let sendTemplate = Notification.Name("sendTemplate")
}
```

### Success Criteria:

#### Automated Verification:
- [ ] Project builds without errors: `xcodebuild -scheme TgTemplates build`
- [ ] Info.plist contains UIApplicationSceneManifest key
- [ ] SceneDelegate.swift compiles
- [ ] RootView.swift compiles

#### Manual Verification:
- [ ] App launches normally on iPhone simulator
- [ ] Authentication flow works
- [ ] Template list displays correctly
- [ ] Deep links still work

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation that the iPhone app still works correctly before proceeding.

---

## Phase 2: CarPlay Scene Delegate

### Overview
Create the CarPlay scene delegate that displays templates in a grid and handles sending.

### Changes Required:

#### 1. Create CarPlay Directory
**Action**: Create directory structure

```
TgTemplates/
├── CarPlay/
│   └── CarPlaySceneDelegate.swift
```

#### 2. Create CarPlaySceneDelegate
**File**: `TgTemplates/CarPlay/CarPlaySceneDelegate.swift` (new file)

```swift
import CarPlay
import UIKit

class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    private var interfaceController: CPInterfaceController?

    // MARK: - CPTemplateApplicationSceneDelegate

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        self.interfaceController = interfaceController

        // Ensure TelegramService is started
        Task { @MainActor in
            if TelegramConfig.isConfigured && !TelegramService.shared.isReady {
                TelegramService.shared.start()
            }
        }

        // Set the root template
        let gridTemplate = createGridTemplate()
        interfaceController.setRootTemplate(gridTemplate, animated: true, completion: nil)
    }

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnect interfaceController: CPInterfaceController
    ) {
        self.interfaceController = nil
    }

    // MARK: - Template Creation

    private func createGridTemplate() -> CPGridTemplate {
        let templates = UserDefaults.appGroup.widgetTemplates

        // CPGridTemplate supports up to 8 buttons
        let maxButtons = min(templates.count, 8)
        let displayTemplates = Array(templates.prefix(maxButtons))

        let gridButtons: [CPGridButton] = displayTemplates.map { template in
            let image = UIImage(systemName: template.icon) ?? UIImage(systemName: "paperplane.fill")!

            let button = CPGridButton(
                titleVariants: [template.name],
                image: image
            ) { [weak self] _ in
                self?.sendTemplate(template)
            }

            return button
        }

        // If no templates, show a placeholder
        let buttons: [CPGridButton]
        if gridButtons.isEmpty {
            let placeholderImage = UIImage(systemName: "doc.badge.plus")!
            let placeholder = CPGridButton(
                titleVariants: ["Add templates on iPhone"],
                image: placeholderImage
            ) { _ in }
            buttons = [placeholder]
        } else {
            buttons = gridButtons
        }

        let gridTemplate = CPGridTemplate(
            title: "TgTemplates",
            gridButtons: buttons
        )

        return gridTemplate
    }

    // MARK: - Template Sending

    private func sendTemplate(_ template: WidgetTemplate) {
        Task { @MainActor in
            // Check if TelegramService is ready
            guard TelegramService.shared.isReady else {
                showAlert(
                    title: "Not Logged In",
                    message: "Please open the app on your iPhone to log in.",
                    isError: true
                )
                return
            }

            do {
                try await TelegramService.shared.sendTemplateMessage(template)
                showAlert(
                    title: "Sent!",
                    message: template.name,
                    isError: false
                )

                // Donate Siri shortcut for this template
                donateShortcut(for: template)
            } catch {
                showAlert(
                    title: "Failed",
                    message: error.localizedDescription,
                    isError: true
                )
            }
        }
    }

    // MARK: - Alerts

    private func showAlert(title: String, message: String, isError: Bool) {
        let alert = CPAlertTemplate(
            titleVariants: [title],
            actions: [
                CPAlertAction(title: "OK", style: isError ? .cancel : .default) { [weak self] _ in
                    self?.interfaceController?.dismissTemplate(animated: true, completion: nil)
                }
            ]
        )

        interfaceController?.presentTemplate(alert, animated: true, completion: nil)
    }

    // MARK: - Siri Shortcut Donation

    private func donateShortcut(for template: WidgetTemplate) {
        // Shortcut donation will be implemented in Phase 4
    }
}
```

### Success Criteria:

#### Automated Verification:
- [ ] Project builds without errors: `xcodebuild -scheme TgTemplates build`
- [ ] CarPlaySceneDelegate.swift compiles with CarPlay framework
- [ ] No warnings about missing scene delegate

#### Manual Verification:
- [ ] CarPlay Simulator shows TgTemplates app icon
- [ ] Tapping app shows grid of templates
- [ ] Template icons display correctly (SF Symbols)
- [ ] Empty state shows "Add templates on iPhone" if no templates

**Implementation Note**: After completing this phase, test in CarPlay Simulator before proceeding. The entitlement is not yet configured, so the app may not appear in simulator until Phase 3.

---

## Phase 3: Entitlements Configuration

### Overview
Add the CarPlay entitlement to the app. Note: For App Store distribution, you must also request the entitlement from Apple Developer Portal.

### Changes Required:

#### 1. Update Entitlements File
**File**: `TgTemplates/TgTemplates.entitlements`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.security.application-groups</key>
	<array>
		<string>group.com.sitex.TgTemplates</string>
	</array>
	<key>com.apple.developer.carplay-communication</key>
	<true/>
</dict>
</plist>
```

#### 2. Apple Developer Portal (Manual Step)
**Action**: Request CarPlay entitlement

1. Go to https://developer.apple.com/carplay
2. Click "Request CarPlay entitlement"
3. Select category: **Communication**
4. Fill out the form:
   - App Name: TgTemplates
   - Bundle ID: com.sitex.TgTemplates
   - Description: Send pre-configured Telegram message templates
5. Submit and wait for approval (typically 1-2 weeks)

#### 3. Update Provisioning Profile (After Approval)
**Action**: After Apple approves the entitlement

1. Go to Certificates, Identifiers & Profiles
2. Select App ID: com.sitex.TgTemplates
3. Enable CarPlay (Communication) capability
4. Regenerate provisioning profile
5. Download and install in Xcode

### Success Criteria:

#### Automated Verification:
- [ ] Entitlements file contains `com.apple.developer.carplay-communication`
- [ ] Project builds with updated entitlements

#### Manual Verification:
- [ ] App appears in CarPlay Simulator
- [ ] Tapping app icon launches CarPlay interface
- [ ] Grid template displays with templates

**Implementation Note**: The simulator should work with just the entitlements file. For device testing and App Store, you need Apple approval.

---

## Phase 4: Siri Integration

### Overview
Add Siri Shortcuts support so users can send templates via voice command.

### Changes Required:

#### 1. Create SendTemplateIntent
**File**: `TgTemplates/Intents/CarPlaySendTemplateIntent.swift` (new file)

```swift
import AppIntents
import Foundation

@available(iOS 16.0, *)
struct CarPlaySendTemplateIntent: AppIntent {
    static var title: LocalizedStringResource = "Send Template"
    static var description = IntentDescription("Send a Telegram template message")

    static var openAppWhenRun: Bool = false

    @Parameter(title: "Template")
    var templateName: String

    static var parameterSummary: some ParameterSummary {
        Summary("Send \(\.$templateName)")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Find template by name
        let templates = UserDefaults.appGroup.widgetTemplates

        guard let template = templates.first(where: {
            $0.name.lowercased() == templateName.lowercased()
        }) else {
            return .result(dialog: "Template '\(templateName)' not found")
        }

        // Send the template
        do {
            try await TelegramService.shared.sendTemplateMessage(template)
            return .result(dialog: "Sent \(template.name)!")
        } catch {
            return .result(dialog: "Failed to send: \(error.localizedDescription)")
        }
    }
}
```

#### 2. Create App Shortcuts Provider
**File**: `TgTemplates/Intents/AppShortcuts.swift` (new file)

```swift
import AppIntents

@available(iOS 16.0, *)
struct TgTemplatesShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CarPlaySendTemplateIntent(),
            phrases: [
                "Send \(\.$templateName) with \(.applicationName)",
                "Send \(\.$templateName) template",
                "\(.applicationName) send \(\.$templateName)"
            ],
            shortTitle: "Send Template",
            systemImageName: "paperplane.fill"
        )
    }
}
```

#### 3. Update CarPlaySceneDelegate Shortcut Donation
**File**: `TgTemplates/CarPlay/CarPlaySceneDelegate.swift`
**Changes**: Implement the `donateShortcut` method

```swift
// Replace the empty donateShortcut method with:
private func donateShortcut(for template: WidgetTemplate) {
    if #available(iOS 16.0, *) {
        let intent = CarPlaySendTemplateIntent()
        intent.templateName = template.name

        // Donate the shortcut to Siri
        Task {
            do {
                try await intent.donate()
            } catch {
                print("Failed to donate shortcut: \(error)")
            }
        }
    }
}
```

#### 4. Create Intents Directory Structure
**Action**: Create directory

```
TgTemplates/
├── Intents/
│   ├── CarPlaySendTemplateIntent.swift
│   └── AppShortcuts.swift
```

### Success Criteria:

#### Automated Verification:
- [ ] Project builds without errors
- [ ] AppIntents framework links correctly
- [ ] No compiler errors in intent files

#### Manual Verification:
- [ ] After sending a template from CarPlay, shortcut appears in Shortcuts app
- [ ] Saying "Hey Siri, send [template name] with TgTemplates" triggers the intent
- [ ] Siri responds with success/failure message
- [ ] Template is actually sent to Telegram

**Implementation Note**: Siri integration requires iOS 16+. The intent will only be available on compatible devices.

---

## Phase 5: Template Refresh & Polish

### Overview
Add template refresh capability and polish the CarPlay experience.

### Changes Required:

#### 1. Add Refresh Button to Grid
**File**: `TgTemplates/CarPlay/CarPlaySceneDelegate.swift`
**Changes**: Update `createGridTemplate()` to include a refresh button

```swift
private func createGridTemplate() -> CPGridTemplate {
    let templates = UserDefaults.appGroup.widgetTemplates

    // Reserve one slot for refresh button, so max 7 templates
    let maxTemplates = min(templates.count, 7)
    let displayTemplates = Array(templates.prefix(maxTemplates))

    var gridButtons: [CPGridButton] = displayTemplates.map { template in
        let image = UIImage(systemName: template.icon) ?? UIImage(systemName: "paperplane.fill")!

        let button = CPGridButton(
            titleVariants: [template.name],
            image: image
        ) { [weak self] _ in
            self?.sendTemplate(template)
        }

        return button
    }

    // Add refresh button
    let refreshImage = UIImage(systemName: "arrow.clockwise")!
    let refreshButton = CPGridButton(
        titleVariants: ["Refresh"],
        image: refreshImage
    ) { [weak self] _ in
        self?.refreshTemplates()
    }
    gridButtons.append(refreshButton)

    // If no templates (only refresh button), show placeholder
    if displayTemplates.isEmpty {
        let placeholderImage = UIImage(systemName: "doc.badge.plus")!
        let placeholder = CPGridButton(
            titleVariants: ["Add on iPhone"],
            image: placeholderImage
        ) { _ in }
        gridButtons.insert(placeholder, at: 0)
    }

    let gridTemplate = CPGridTemplate(
        title: "TgTemplates",
        gridButtons: gridButtons
    )

    return gridTemplate
}

private func refreshTemplates() {
    let gridTemplate = createGridTemplate()
    interfaceController?.setRootTemplate(gridTemplate, animated: true, completion: nil)
}
```

#### 2. Add Connection Status Handling
**File**: `TgTemplates/CarPlay/CarPlaySceneDelegate.swift`
**Changes**: Add better status handling

```swift
// Add after sendTemplate method:

private func checkTelegramStatus() -> Bool {
    // This runs on CarPlay's thread, need to check MainActor state
    var isReady = false
    let semaphore = DispatchSemaphore(value: 0)

    Task { @MainActor in
        isReady = TelegramService.shared.isReady
        semaphore.signal()
    }

    semaphore.wait()
    return isReady
}
```

### Success Criteria:

#### Automated Verification:
- [ ] Project builds without errors
- [ ] No runtime crashes in CarPlay simulator

#### Manual Verification:
- [ ] Refresh button appears in grid
- [ ] Tapping refresh reloads templates
- [ ] New templates added on iPhone appear after refresh
- [ ] Grid handles 0-7 templates gracefully

---

## Testing Strategy

### Unit Tests:
- Test `WidgetTemplate` encoding/decoding
- Test UserDefaults.appGroup read/write
- Test CarPlaySendTemplateIntent template lookup

### Integration Tests:
- Test TelegramService.sendTemplateMessage from background thread with @MainActor
- Test template sync between iPhone and CarPlay

### Manual Testing Steps:
1. Build and run on iPhone simulator
2. Window > Devices and Simulators > select simulator > CarPlay
3. Verify app icon appears in CarPlay dashboard
4. Add templates in iPhone app
5. Open CarPlay app, verify grid shows templates
6. Tap template, verify message sends
7. Test refresh button
8. Test with 0, 1, 7, and 8+ templates
9. Test Siri command after sending once from CarPlay

## Performance Considerations

- Templates loaded from UserDefaults on connect (fast, local storage)
- Grid limited to 8 buttons (CarPlay framework limit)
- Async message sending doesn't block CarPlay UI
- Location fetch is async with silent failure fallback

## Migration Notes

- No data migration needed
- Existing templates work automatically
- Users just need to connect to CarPlay

## References

- Original research: `thoughts/shared/research/2025-12-20-carplay-interface.md`
- Watch app pattern: `TgTemplatesWatch/WatchConnectivityManager.swift`
- Widget intent pattern: `TgTemplatesWidget/SendTemplateIntent.swift`
- [Apple CarPlay Documentation](https://developer.apple.com/documentation/carplay)
- [CPTemplateApplicationSceneDelegate](https://developer.apple.com/documentation/carplay/cptemplateapplicationscenedelegate)
- [AppIntents Framework](https://developer.apple.com/documentation/appintents)
