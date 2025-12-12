---
date: 2025-12-12T17:30:00+00:00
researcher: Claude
git_commit: 3e1b3b1457595cfa2f6cef81f3159ca9b3e7f722
branch: main
repository: Tg-Templates
topic: "Apple Watch App with Templates from iOS App"
tags: [research, codebase, watchos, templates, data-sharing, app-group]
status: complete
last_updated: 2025-12-12
last_updated_by: Claude
---

# Research: Apple Watch App with Templates from iOS App

**Date**: 2025-12-12T17:30:00+00:00
**Researcher**: Claude
**Git Commit**: 3e1b3b1457595cfa2f6cef81f3159ca9b3e7f722
**Branch**: main
**Repository**: Tg-Templates

## Research Question
How to make an Apple Watch app with templates available from the existing iOS app.

## Summary

The existing iOS app already has a proven data sharing architecture between the main app and a Widget extension. The same patterns can be directly reused for an Apple Watch app. The key components are:

1. **App Group**: `group.com.sitex.TgTemplates` - shared container for data
2. **WidgetTemplate model**: Lightweight `Codable` struct for cross-target data
3. **UserDefaults suite**: JSON-encoded templates stored at key `widgetTemplates`
4. **Sync mechanism**: Main app writes, extensions read

A Watch app would follow the same pattern as the existing Widget extension.

## Detailed Findings

### Current Architecture

#### Data Model

**SwiftData Template** (`TgTemplates/Models/Template.swift:4-37`):
- `@Model` class used in main app
- Properties: id, name, icon, messageText, targetGroupId, targetGroupName, includeLocation, createdAt, updatedAt, sortOrder

**WidgetTemplate** (`TgTemplates/Models/WidgetTemplate.swift:3-11`):
- Lightweight `Codable` struct for extensions
- Properties: id, name, icon, messageText, targetGroupId, targetGroupName, includeLocation
- Excludes metadata fields (createdAt, updatedAt, sortOrder)

#### App Group Configuration

**Main App Entitlements** (`TgTemplates/TgTemplates.entitlements:5-8`):
```xml
<key>com.apple.security.application-groups</key>
<array>
    <string>group.com.sitex.TgTemplates</string>
</array>
```

**Widget Entitlements** (`TgTemplatesWidget/TgTemplatesWidgetExtension.entitlements:5-8`):
- Identical app group configuration

#### Data Sharing Implementation

**UserDefaults Extension** (`TgTemplates/Extensions/UserDefaults+AppGroup.swift:3-37`):
```swift
extension UserDefaults {
    static let appGroup = UserDefaults(suiteName: "group.com.sitex.TgTemplates")!

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

**Sync Function** (`TgTemplates/Views/Templates/TemplateListView.swift:112-127`):
```swift
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
    WidgetCenter.shared.reloadAllTimelines()
}
```

**Sync Triggers** (`TemplateListView.swift:83-88`):
- `.onAppear` - syncs when view appears
- `.onChange(of: templates.count)` - syncs on add/delete

### Widget Extension Pattern (Reference for Watch)

**Widget Reading Templates** (`TgTemplatesWidget/TgTemplatesWidget.swift:5-16`):
```swift
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
    }
}
```

**Intent for Actions** (`TgTemplatesWidget/SendTemplateIntent.swift:4-26`):
- AppIntent with `openAppWhenRun = true`
- Stores `templateId` in shared UserDefaults at key `pendingTemplateId`
- Main app reads and clears this on activation

**Main App Handling** (`TgTemplatesApp.swift:36-52`):
- `checkPendingTemplate()` reads `pendingTemplateId` from shared UserDefaults
- Posts `.sendTemplate` notification to trigger action
- Called on app activation (`.onAppear` and `.onChange(of: scenePhase)`)

### Project Structure

**Existing Targets**:
1. `TgTemplates` - Main iOS app (Bundle: `com.sitex.TgTemplates`)
2. `TgTemplatesWidgetExtension` - Widget extension (Bundle: `com.sitex.TgTemplates.TgTemplatesWidget`)

**Files Duplicated in Widget Target**:
- `WidgetTemplate.swift` - Model definition (identical copy)

## Code References

### Data Model
- `TgTemplates/Models/Template.swift:4-37` - SwiftData model
- `TgTemplates/Models/WidgetTemplate.swift:3-11` - Codable struct for extensions
- `TgTemplatesWidget/WidgetTemplate.swift:3-11` - Duplicate in widget target

### Data Sharing
- `TgTemplates/Extensions/UserDefaults+AppGroup.swift:3-37` - App group UserDefaults extension
- `TgTemplates/Views/Templates/TemplateListView.swift:112-127` - Sync function
- `TgTemplatesWidget/TgTemplatesWidget.swift:5-16` - Widget reading templates

### Entitlements
- `TgTemplates/TgTemplates.entitlements` - Main app app group
- `TgTemplatesWidget/TgTemplatesWidgetExtension.entitlements` - Widget app group

### Intent Handling
- `TgTemplatesWidget/SendTemplateIntent.swift:4-26` - Widget intent
- `TgTemplates/TgTemplatesApp.swift:36-52` - Pending template handling

## Architecture Documentation

### Data Flow: Main App → Extensions

```
SwiftData Template → WidgetTemplate struct → JSON → UserDefaults (App Group) → Extension reads
```

1. User modifies templates in main app
2. `syncWidgetData()` converts SwiftData models to `WidgetTemplate` structs
3. Array encoded to JSON via `JSONEncoder`
4. Stored in `UserDefaults(suiteName: "group.com.sitex.TgTemplates")`
5. Extensions read from same UserDefaults suite

### Data Flow: Extension → Main App (Actions)

```
Extension button tap → Intent writes templateId → App opens → Reads & clears → NotificationCenter → Action
```

1. User taps button in extension
2. AppIntent stores `templateId` string in shared UserDefaults
3. `openAppWhenRun = true` launches main app
4. App reads `pendingTemplateId`, clears it
5. Posts NotificationCenter event
6. ContentView handles the action

### Key Patterns for Watch App

1. **Same App Group**: Add `group.com.sitex.TgTemplates` to Watch app entitlements
2. **Same Model**: Copy `WidgetTemplate.swift` to Watch target (or create shared framework)
3. **Same UserDefaults Access**: Use `UserDefaults(suiteName: "group.com.sitex.TgTemplates")`
4. **Same Keys**: Read from `widgetTemplates` key
5. **Same Intent Pattern**: Use AppIntent with `pendingTemplateId` for actions

## Watch App Implementation Notes

### Required Files for Watch Target

1. **Entitlements file** with app group:
   ```xml
   <key>com.apple.security.application-groups</key>
   <array>
       <string>group.com.sitex.TgTemplates</string>
   </array>
   ```

2. **WidgetTemplate.swift** (copy from main app or widget)

3. **UserDefaults extension** for reading templates:
   ```swift
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

4. **Intent for sending** (if Watch should trigger sends):
   ```swift
   struct WatchSendTemplateIntent: AppIntent {
       static var title: LocalizedStringResource = "Send Template"
       static var openAppWhenRun: Bool = true

       @Parameter(title: "Template ID")
       var templateId: String

       func perform() async throws -> some IntentResult {
           UserDefaults(suiteName: "group.com.sitex.TgTemplates")?.set(templateId, forKey: "pendingTemplateId")
           return .result()
       }
   }
   ```

### Watch App Capabilities

**Can do without iPhone**:
- Display list of templates (from shared UserDefaults)
- Show template details (name, icon, message preview)

**Requires iPhone app**:
- Actually send messages (TDLib runs on iPhone)
- Modify templates
- Authenticate with Telegram

### Sync Considerations

- Templates sync when main iOS app's `TemplateListView` appears or template count changes
- Watch app should handle empty state gracefully
- Consider adding `WKApplicationRefreshBackgroundTask` for periodic updates
- Current `syncWidgetData()` already writes to shared UserDefaults - no changes needed

## Open Questions

1. **WatchConnectivity**: Should the Watch use WatchConnectivity framework for real-time sync, or is App Group UserDefaults sufficient?
2. **Complications**: Should templates be available as Watch complications?
3. **Offline behavior**: How should Watch handle when iPhone app hasn't synced recently?
4. **Send confirmation**: Should Watch show confirmation after triggering send on iPhone?
