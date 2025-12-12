# Apple Watch App Implementation Plan

## Overview

Create an Apple Watch app that displays templates from the iOS app and allows users to trigger message sends. The Watch app will leverage the existing App Group data sharing architecture already proven by the Widget extension.

## Current State Analysis

### Existing Architecture
The iOS app already shares data with a Widget extension using:
- **App Group**: `group.com.sitex.TgTemplates`
- **Shared UserDefaults**: JSON-encoded `[WidgetTemplate]` at key `"widgetTemplates"`
- **Intent Pattern**: `SendTemplateIntent` with `openAppWhenRun = true` writes `pendingTemplateId` to shared UserDefaults
- **Main App Detection**: Checks `pendingTemplateId` on activation and posts `.sendTemplate` notification

### Key Code References
- Entitlements: `TgTemplates/TgTemplates.entitlements:5-8`
- WidgetTemplate model: `TgTemplates/Models/WidgetTemplate.swift:3-11`
- UserDefaults extension: `TgTemplates/Extensions/UserDefaults+AppGroup.swift:4-37`
- Sync function: `TgTemplates/Views/Templates/TemplateListView.swift:112-127`
- SendTemplateIntent: `TgTemplatesWidget/SendTemplateIntent.swift:4-26`
- Pending template check: `TgTemplates/TgTemplatesApp.swift:36-52`

## Desired End State

After implementation:
1. A WatchOS app target exists in the Xcode project
2. The Watch app displays all templates synced from the iOS app
3. Users can tap a template on Watch to trigger sending via the iPhone app
4. The architecture follows the same pattern as the existing Widget extension
5. No changes required to the main iOS app's sync mechanism

### Verification
- Watch app appears in Xcode scheme list
- Watch app builds successfully for watchOS simulator
- Templates display on Watch when iOS app has templates
- Tapping a template on Watch opens iOS app and sends the message

## What We're NOT Doing

- **No Watch-only template creation**: Templates can only be created/edited on iPhone
- **No direct Telegram API calls from Watch**: TDLib runs on iPhone only
- **No WatchConnectivity framework**: App Group UserDefaults is sufficient for this use case
- **No Watch complications**: Can be added as a future enhancement
- **No shared framework**: Duplicate `WidgetTemplate.swift` like the Widget does (simpler for small projects)

## Implementation Approach

Follow the same pattern established by the Widget extension:
1. Create WatchOS target with same App Group entitlements
2. Copy `WidgetTemplate.swift` to Watch target
3. Create UserDefaults extension for reading templates
4. Build SwiftUI views for template list and detail
5. Create intent for triggering sends (same as Widget)

## Phase 1: Create WatchOS Target

### Overview
Set up the basic WatchOS app target in Xcode with proper configuration.

### Changes Required

#### 1. Create Watch App Target in Xcode
**Action**: In Xcode, File → New → Target → watchOS → App

**Configuration**:
- Product Name: `TgTemplatesWatch`
- Bundle Identifier: `com.sitex.TgTemplates.watchkitapp`
- Interface: SwiftUI
- Language: Swift
- Include Notification Scene: No
- Include Complication: No

This will create:
- `TgTemplatesWatch/` directory
- `TgTemplatesWatch/TgTemplatesWatchApp.swift`
- `TgTemplatesWatch/ContentView.swift`
- `TgTemplatesWatch/Assets.xcassets/`
- `TgTemplatesWatch/Preview Content/`

#### 2. Create Entitlements File
**File**: `TgTemplatesWatch/TgTemplatesWatch.entitlements`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.security.application-groups</key>
	<array>
		<string>group.com.sitex.TgTemplates</string>
	</array>
</dict>
</plist>
```

#### 3. Configure Signing & Capabilities
**Action**: In Xcode, select TgTemplatesWatch target → Signing & Capabilities → + Capability → App Groups → Enable `group.com.sitex.TgTemplates`

### Success Criteria

#### Automated Verification:
- [ ] Watch target builds: `xcodebuild -scheme TgTemplatesWatch -destination 'platform=watchOS Simulator,name=Apple Watch Series 9 (45mm)' build`
- [x] Entitlements file exists at `TgTemplatesWatch/TgTemplatesWatch.entitlements`
- [x] App Group is configured in entitlements

#### Manual Verification:
- [ ] Watch app target appears in Xcode scheme selector
- [ ] Watch app launches in watchOS Simulator
- [ ] Default "Hello, World!" view displays

**Implementation Note**: Phase 1 requires Xcode GUI for target creation. After creating the target in Xcode, verify the files were created before proceeding.

---

## Phase 2: Add Data Model and UserDefaults Extension

### Overview
Add the shared data model and UserDefaults extension to read templates from the App Group.

### Changes Required

#### 1. Copy WidgetTemplate Model
**File**: `TgTemplatesWatch/WidgetTemplate.swift`

```swift
import Foundation

struct WidgetTemplate: Codable, Identifiable {
    let id: UUID
    let name: String
    let icon: String
    let messageText: String
    let targetGroupId: Int64?
    let targetGroupName: String?
    let includeLocation: Bool
}
```

**Note**: Add this file to the TgTemplatesWatch target membership in Xcode.

#### 2. Create UserDefaults Extension
**File**: `TgTemplatesWatch/UserDefaults+Watch.swift`

```swift
import Foundation

extension UserDefaults {
    static let watchGroup = UserDefaults(suiteName: "group.com.sitex.TgTemplates")!

    var widgetTemplates: [WidgetTemplate] {
        guard let data = data(forKey: "widgetTemplates"),
              let templates = try? JSONDecoder().decode([WidgetTemplate].self, from: data) else {
            return []
        }
        return templates
    }
}
```

### Success Criteria

#### Automated Verification:
- [ ] Watch target builds with new files: `xcodebuild -scheme TgTemplatesWatch -destination 'platform=watchOS Simulator,name=Apple Watch Series 9 (45mm)' build`
- [x] `WidgetTemplate.swift` exists in Watch target
- [x] `UserDefaults+Watch.swift` exists in Watch target

#### Manual Verification:
- [ ] Files appear in Xcode under TgTemplatesWatch group
- [ ] No build errors related to model or UserDefaults

**Implementation Note**: After adding files, ensure they have correct target membership in Xcode.

---

## Phase 3: Build Watch UI

### Overview
Create the SwiftUI views for displaying templates on the Watch.

### Changes Required

#### 1. Update Watch App Entry Point
**File**: `TgTemplatesWatch/TgTemplatesWatchApp.swift`

```swift
import SwiftUI

@main
struct TgTemplatesWatchApp: App {
    var body: some Scene {
        WindowGroup {
            TemplateListView()
        }
    }
}
```

#### 2. Create Template List View
**File**: `TgTemplatesWatch/TemplateListView.swift`

```swift
import SwiftUI

struct TemplateListView: View {
    @State private var templates: [WidgetTemplate] = []

    var body: some View {
        NavigationStack {
            Group {
                if templates.isEmpty {
                    emptyStateView
                } else {
                    templateList
                }
            }
            .navigationTitle("Templates")
        }
        .onAppear {
            loadTemplates()
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "doc.text")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text("No Templates")
                .font(.headline)
            Text("Add templates in the iPhone app")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private var templateList: some View {
        List(templates) { template in
            NavigationLink(value: template) {
                TemplateRowView(template: template)
            }
        }
        .navigationDestination(for: WidgetTemplate.self) { template in
            TemplateDetailView(template: template)
        }
    }

    private func loadTemplates() {
        templates = UserDefaults.watchGroup.widgetTemplates
    }
}

#Preview {
    TemplateListView()
}
```

#### 3. Create Template Row View
**File**: `TgTemplatesWatch/TemplateRowView.swift`

```swift
import SwiftUI

struct TemplateRowView: View {
    let template: WidgetTemplate

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: template.icon)
                .font(.title3)
                .foregroundColor(.accentColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(template.name)
                    .font(.headline)
                    .lineLimit(1)

                if let groupName = template.targetGroupName {
                    Text(groupName)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    TemplateRowView(template: WidgetTemplate(
        id: UUID(),
        name: "Good Morning",
        icon: "sun.max.fill",
        messageText: "Good morning!",
        targetGroupId: nil,
        targetGroupName: "Family Chat",
        includeLocation: false
    ))
}
```

#### 4. Create Template Detail View
**File**: `TgTemplatesWatch/TemplateDetailView.swift`

```swift
import SwiftUI
import AppIntents

struct TemplateDetailView: View {
    let template: WidgetTemplate

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Icon and name
                VStack(spacing: 8) {
                    Image(systemName: template.icon)
                        .font(.system(size: 40))
                        .foregroundColor(.accentColor)

                    Text(template.name)
                        .font(.headline)
                }
                .padding(.top)

                // Message preview
                VStack(alignment: .leading, spacing: 4) {
                    Text("Message")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(template.messageText)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal)

                // Target group
                if let groupName = template.targetGroupName {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Send to")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(groupName)
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal)
                }

                // Location indicator
                if template.includeLocation {
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundColor(.secondary)
                        Text("Includes location")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Send button
                Button(intent: WatchSendTemplateIntent(templateId: template.id)) {
                    Label("Send", systemImage: "paperplane.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        TemplateDetailView(template: WidgetTemplate(
            id: UUID(),
            name: "Good Morning",
            icon: "sun.max.fill",
            messageText: "Good morning everyone! Hope you have a great day!",
            targetGroupId: nil,
            targetGroupName: "Family Chat",
            includeLocation: true
        ))
    }
}
```

### Success Criteria

#### Automated Verification:
- [ ] Watch target builds: `xcodebuild -scheme TgTemplatesWatch -destination 'platform=watchOS Simulator,name=Apple Watch Series 9 (45mm)' build`
- [x] All view files exist in Watch target

#### Manual Verification:
- [ ] Empty state displays when no templates exist
- [ ] Template list displays correctly when templates exist
- [ ] Navigation to detail view works
- [ ] Detail view shows all template information
- [ ] UI is readable and appropriately sized for Watch

**Implementation Note**: The Send button uses an AppIntent which will be created in Phase 4. The build may fail until Phase 4 is complete.

---

## Phase 4: Implement Send Intent

### Overview
Create the AppIntent that triggers message sending via the iPhone app.

### Changes Required

#### 1. Create Watch Send Intent
**File**: `TgTemplatesWatch/WatchSendTemplateIntent.swift`

```swift
import AppIntents
import Foundation

struct WatchSendTemplateIntent: AppIntent {
    static var title: LocalizedStringResource = "Send Template from Watch"
    static var description = IntentDescription("Sends a template message to Telegram via iPhone")

    @Parameter(title: "Template ID")
    var templateId: String

    static var openAppWhenRun: Bool = true

    init() {
        self.templateId = ""
    }

    init(templateId: UUID) {
        self.templateId = templateId.uuidString
    }

    func perform() async throws -> some IntentResult {
        // Store the template ID for the iPhone app to read when it opens
        UserDefaults(suiteName: "group.com.sitex.TgTemplates")?.set(templateId, forKey: "pendingTemplateId")
        return .result()
    }
}
```

**Note**: This is identical to `SendTemplateIntent` from the Widget. The iPhone app already handles `pendingTemplateId` - no changes needed there.

### Success Criteria

#### Automated Verification:
- [ ] Watch target builds: `xcodebuild -scheme TgTemplatesWatch -destination 'platform=watchOS Simulator,name=Apple Watch Series 9 (45mm)' build`
- [x] Intent file exists in Watch target

#### Manual Verification:
- [ ] Tapping "Send" button on Watch triggers intent
- [ ] iPhone app opens when intent runs
- [ ] Message is sent via Telegram
- [ ] Success/error feedback appears on iPhone

**Implementation Note**: End-to-end testing requires both Watch and iPhone to be paired and running.

---

## Phase 5: Add Refresh Capability (Optional Enhancement)

### Overview
Allow users to manually refresh the template list on Watch.

### Changes Required

#### 1. Update Template List View with Refresh
**File**: `TgTemplatesWatch/TemplateListView.swift`

Update the `templateList` computed property:

```swift
private var templateList: some View {
    List(templates) { template in
        NavigationLink(value: template) {
            TemplateRowView(template: template)
        }
    }
    .navigationDestination(for: WidgetTemplate.self) { template in
        TemplateDetailView(template: template)
    }
    .refreshable {
        loadTemplates()
    }
    .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                loadTemplates()
            } label: {
                Image(systemName: "arrow.clockwise")
            }
        }
    }
}
```

### Success Criteria

#### Automated Verification:
- [ ] Watch target builds successfully (verify on macOS with Xcode)

#### Manual Verification:
- [ ] Pull-to-refresh gesture works on template list
- [ ] Refresh button appears in toolbar
- [ ] New templates appear after refresh without restarting app

---

## Testing Strategy

### Unit Tests
- Not applicable for this phase (primarily UI code)
- Future consideration: Mock UserDefaults for testing data loading

### Integration Tests
- Watch ↔ iPhone data sync via App Group
- Intent triggering and app handoff

### Manual Testing Steps
1. **Empty State**: Launch Watch app with no templates in iOS app → verify empty state displays
2. **Template Sync**: Add template in iOS app → refresh Watch app → verify template appears
3. **Template Display**: Verify all template fields display correctly on Watch
4. **Send Action**: Tap Send on Watch → verify iPhone opens and message sends
5. **Multiple Templates**: Add 5+ templates → verify scrolling works on Watch
6. **Long Content**: Test with long template names and messages → verify truncation/wrapping

## File Structure Summary

After implementation, the project will have:

```
TgTemplates.xcodeproj/
├── TgTemplates/               (existing - no changes)
├── TgTemplatesWidget/         (existing - no changes)
└── TgTemplatesWatch/          (new)
    ├── TgTemplatesWatchApp.swift
    ├── TemplateListView.swift
    ├── TemplateRowView.swift
    ├── TemplateDetailView.swift
    ├── WidgetTemplate.swift
    ├── UserDefaults+Watch.swift
    ├── WatchSendTemplateIntent.swift
    ├── TgTemplatesWatch.entitlements
    ├── Assets.xcassets/
    └── Preview Content/
```

## References

- Research document: `thoughts/shared/research/2025-12-12-apple-watch-app-templates.md`
- Widget implementation pattern: `TgTemplatesWidget/TgTemplatesWidget.swift`
- Send intent pattern: `TgTemplatesWidget/SendTemplateIntent.swift`
- Data sync implementation: `TgTemplates/Views/Templates/TemplateListView.swift:112-127`
