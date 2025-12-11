# Xcode Project Setup

Follow these steps on macOS to create the Xcode project and complete Phase 1 setup.

## Step 1: Create Xcode Project

1. Open **Xcode** (version 15.0 or later)
2. File → New → Project
3. Select **iOS** → **App**
4. Configure:
   - **Product Name**: `TgTemplates`
   - **Team**: Your Apple Developer account
   - **Organization Identifier**: `com.sitex`
   - **Bundle Identifier**: `com.sitex.TgTemplates` (auto-filled)
   - **Interface**: SwiftUI
   - **Language**: Swift
   - **Storage**: SwiftData
5. Save the project in this repository's root folder
6. **IMPORTANT**: When Xcode creates the project, it will create a `TgTemplates/` folder with default files. Delete Xcode's generated files and keep the existing ones from this repo.

## Step 2: Configure Existing Files

After creating the project:

1. In Xcode's Project Navigator, right-click `TgTemplates` folder
2. Select "Add Files to TgTemplates..."
3. Add all files from the existing `TgTemplates/` directory:
   - `TgTemplatesApp.swift`
   - `Config/TelegramConfig.swift`
   - `Models/Template.swift`
   - `Views/ContentView.swift`
4. Make sure "Copy items if needed" is **unchecked**
5. Make sure "Create groups" is selected

## Step 3: Add TDLibKit Dependency

1. In Xcode: File → Add Package Dependencies...
2. Enter URL: `https://github.com/Swiftgram/TDLibKit`
3. Click "Add Package"
4. Select `TDLibKit` library and add to `TgTemplates` target
5. Wait for package resolution (~300MB download)

## Step 4: Configure App Groups

1. Select the project in Navigator
2. Select `TgTemplates` target
3. Go to "Signing & Capabilities" tab
4. Click "+ Capability"
5. Add "App Groups"
6. Click "+" under App Groups
7. Enter: `group.com.sitex.TgTemplates`

## Step 5: Set Deployment Target

1. Select the project in Navigator
2. Select `TgTemplates` target
3. Go to "General" tab
4. Set "Minimum Deployments" → iOS 17.0

## Step 6: Configure Telegram API Credentials

1. Go to https://my.telegram.org
2. Log in with your Telegram phone number
3. Click "API development tools"
4. Create a new application (any name/description)
5. Copy `api_id` and `api_hash`
6. Edit `TgTemplates/Config/TelegramConfig.swift`:
   ```swift
   enum TelegramConfig {
       static let apiId: Int32 = YOUR_API_ID
       static let apiHash = "YOUR_API_HASH"
   }
   ```

## Step 7: Build and Run

1. Select an iOS Simulator (iPhone 15 recommended)
2. Press Cmd+B to build
3. Press Cmd+R to run
4. App should launch showing "Tg Templates" text

## Verification Checklist

- [ ] Project builds without errors
- [ ] TDLibKit package resolves successfully
- [ ] App Groups capability is configured
- [ ] App launches in simulator
- [ ] TelegramConfig.swift has your API credentials
- [ ] TelegramConfig.swift is gitignored (check with `git status`)

## Troubleshooting

### "No such module 'TDLibKit'"
- Wait for package resolution to complete
- Try: File → Packages → Reset Package Caches

### Build errors about missing files
- Make sure all Swift files are added to the target
- Check "Target Membership" in File Inspector for each file

### App Groups error
- Make sure you're signed in with an Apple Developer account
- App Groups require a valid team

## Phase 7: Widget Extension Setup

Follow these additional steps to set up the iOS Widget extension.

### Step 1: Create Widget Extension Target

1. In Xcode: File → New → Target
2. Select **iOS** → **Widget Extension**
3. Configure:
   - **Product Name**: `TgTemplatesWidget`
   - **Team**: Same as main app
   - **Bundle Identifier**: `com.sitex.TgTemplates.TgTemplatesWidget` (auto-filled)
   - **Include Configuration App Intent**: Yes (checked)
4. Click "Finish"
5. When asked to activate the scheme, click "Activate"

### Step 2: Delete Default Files

Xcode creates default widget files. Delete them:
- `TgTemplatesWidgetBundle.swift` (delete)
- `TgTemplatesWidgetLiveActivity.swift` (delete)
- `AppIntent.swift` (delete)
- `TgTemplatesWidget.swift` (delete - we have our own)

### Step 3: Add Existing Widget Files

1. Right-click the `TgTemplatesWidget` folder in Project Navigator
2. Select "Add Files to TgTemplatesWidget..."
3. Navigate to `TgTemplatesWidget/` in the repo
4. Add these files:
   - `WidgetTemplate.swift`
   - `SendTemplateIntent.swift`
   - `TgTemplatesWidget.swift`
5. Make sure "Copy items if needed" is **unchecked**
6. Ensure files are added to `TgTemplatesWidget` target only

### Step 4: Configure Widget App Group

1. Select the project in Navigator
2. Select `TgTemplatesWidget` target
3. Go to "Signing & Capabilities" tab
4. Click "+ Capability"
5. Add "App Groups"
6. Enable the existing group: `group.com.sitex.TgTemplates`
   (Must match the main app's App Group)

### Step 5: Verify Target Membership

Make sure WidgetTemplate.swift is included in **both** targets:

1. Select `TgTemplatesWidget/WidgetTemplate.swift`
2. Open File Inspector (right panel)
3. Under "Target Membership", check both:
   - [ ] TgTemplates
   - [x] TgTemplatesWidget

Note: The main app already has its own WidgetTemplate reference via the UserDefaults extension, so you only need it in the widget target.

### Step 6: Build Widget Extension

1. Select `TgTemplatesWidget` scheme in the scheme selector
2. Press Cmd+B to build
3. Fix any errors (usually missing imports or target membership)

### Step 7: Test Widget

1. Select `TgTemplates` scheme (main app)
2. Run on simulator
3. Long-press home screen → "Edit Home Screen"
4. Tap "+" to add widget
5. Search for "TgTemplates"
6. Add small or medium widget

### Widget Verification Checklist

- [ ] Widget extension builds without errors
- [ ] Widget appears in widget gallery
- [ ] Widget shows template buttons (if templates exist)
- [ ] Tapping widget button opens main app
- [ ] Message sends after app opens from widget tap
- [ ] Widget updates when templates change in main app

## Next Steps

After completing Phase 1 setup, proceed to Phase 2 (Telegram Authentication) in the implementation plan:
`thoughts/shared/plans/2025-12-11-telegram-templates-app.md`
