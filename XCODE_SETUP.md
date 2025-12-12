# Xcode Project Setup

This repository includes a pre-configured Xcode project. Follow these steps to get it running.

## Prerequisites

- macOS with Xcode 15.0 or later
- Apple Developer account (free or paid)
- Telegram account for API credentials

## Step 1: Open the Project

1. Double-click `TgTemplates.xcodeproj` or open it from Xcode
2. Wait for Xcode to index the project

## Step 2: Resolve Package Dependencies

1. Xcode should automatically fetch TDLibKit (~300MB download)
2. If not: File → Packages → Resolve Package Versions
3. Wait for package resolution to complete

If you see "No such module 'TDLibKit'":
- File → Packages → Reset Package Caches
- Then resolve again

## Step 3: Configure Signing

1. Select the project in Navigator (top item)
2. Select `TgTemplates` target
3. Go to "Signing & Capabilities" tab
4. Select your Team from the dropdown
5. Repeat for `TgTemplatesWidget` target

## Step 4: Configure App Groups

Both targets need the same App Group for data sharing:

**Main App (TgTemplates):**
1. Select `TgTemplates` target → "Signing & Capabilities"
2. Under "App Groups", ensure `group.com.sitex.TgTemplates` is enabled

**Widget Extension (TgTemplatesWidget):**
1. Select `TgTemplatesWidget` target → "Signing & Capabilities"
2. Add "App Groups" capability if missing (+ Capability → App Groups)
3. Enable the same group: `group.com.sitex.TgTemplates`

## Step 5: Set Deployment Target

1. Select the project in Navigator
2. Select `TgTemplates` target → "General" tab
3. Set "Minimum Deployments" → iOS 17.0
4. Repeat for `TgTemplatesWidget` target

## Step 6: Configure Telegram API Credentials

1. Go to https://my.telegram.org
2. Log in with your Telegram phone number
3. Click "API development tools"
4. Create a new application (any name/description works)
5. Copy your `api_id` (numeric) and `api_hash` (string)
6. Edit `TgTemplates/Config/TelegramConfig.swift`:
   ```swift
   enum TelegramConfig {
       static let apiId: Int32 = 12345678       // Replace 0 with your api_id
       static let apiHash = "abc123def456..."   // Replace "" with your api_hash
   }
   ```

**Note**: Keep your API credentials private. The `TelegramConfig.swift` file is gitignored by default.

## Step 7: Build and Run

1. Select `TgTemplates` scheme in the toolbar
2. Select an iOS Simulator (iPhone 15 recommended)
3. Press Cmd+B to build
4. Press Cmd+R to run

## Project Structure

```
TgTemplates/
├── TgTemplatesApp.swift           # App entry point
├── Config/
│   └── TelegramConfig.swift       # API credentials (gitignored)
├── Models/
│   ├── Template.swift             # Template data model
│   └── TelegramGroup.swift        # Group/chat data model
├── Services/
│   ├── TelegramService.swift      # TDLib wrapper
│   └── LocationService.swift      # Geolocation handling
├── Views/
│   ├── ContentView.swift          # Main view
│   ├── Auth/                      # Login flow views
│   ├── Templates/                 # Template management views
│   ├── Groups/                    # Group picker views
│   └── Settings/                  # Settings views
└── Extensions/
    └── UserDefaults+AppGroup.swift # Shared storage

TgTemplatesWidget/
├── TgTemplatesWidget.swift        # Widget entry point
├── WidgetTemplate.swift           # Widget data model
└── SendTemplateIntent.swift       # Widget tap handler
```

## Verification Checklist

- [ ] Project opens without errors
- [ ] TDLibKit package resolves successfully
- [ ] Both targets have signing configured
- [ ] App Groups enabled on both targets
- [ ] TelegramConfig.swift has your API credentials
- [ ] App builds and runs in simulator
- [ ] Widget appears in widget gallery

## Testing the Widget

1. Run the main app and log in to Telegram
2. Create at least one template
3. Long-press home screen → tap "+" (top left)
4. Search for "TgTemplates"
5. Add small or medium widget
6. Tap a template button to send

## Troubleshooting

### "No such module 'TDLibKit'"
- Wait for package resolution to complete
- File → Packages → Reset Package Caches

### Build errors about missing files
- Ensure all Swift files have correct target membership
- Select file → File Inspector → check Target Membership

### App Groups error
- Sign in with an Apple Developer account
- App Groups require a valid development team

### Widget not appearing
- Build and run the main app first
- Ensure widget target builds successfully
- Reset simulator: Device → Erase All Content and Settings

### Login issues
- Verify API credentials are correct
- Check internet connection
- TDLib logs appear in Xcode console
