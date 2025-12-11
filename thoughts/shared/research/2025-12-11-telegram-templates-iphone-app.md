---
date: 2025-12-11T18:32:59+11:00
researcher: Claude
git_commit: null
branch: null
repository: Tg-Templates
topic: "iPhone app for sending messages to Telegram groups from templates by tapping a button"
tags: [research, codebase, ios, telegram, templates, greenfield]
status: complete
last_updated: 2025-12-11
last_updated_by: Claude
last_updated_note: "Added GitHub repository information"
github_repo: https://github.com/sitex/Tg-Templates
---

# Research: iPhone App for Telegram Group Message Templates

**Date**: 2025-12-11 18:32:59 AEST
**Researcher**: Claude
**Git Commit**: N/A (not yet pushed)
**Branch**: N/A
**Repository**: Tg-Templates
**GitHub**: https://github.com/sitex/Tg-Templates

## Research Question

Document the current state of the codebase for an iPhone app that sends messages to Telegram groups from templates by tapping a button.

## Summary

This is a **greenfield project** with no application code implemented. The directory `/home/rocky/web/Tg-Templates` contains only Claude Code configuration files. No iOS application, Telegram integration, or template management system exists yet.

## GitHub Repository

**URL**: https://github.com/sitex/Tg-Templates

| Property | Value |
|----------|-------|
| Owner | sitex |
| Visibility | Public |
| Stars | 0 |
| Forks | 0 |
| Issues | 0 |
| Status | **Empty** - no code pushed yet |

The remote repository is set up and ready for initial commit.

## User Requirements

### Core Use Case

- **Template icons on home screen** (Поездка/Trip, Пробуждение/Awakening, etc.)
- **1 tap → message sent** to Telegram group "Место" (Location)

### Example Flow

```
[Home Screen]
   │
   ├── 🚗 Поездка (Trip)      ──tap──→  Message to "Место 📝"
   ├── 🌅 Пробуждение (Wake)  ──tap──→  Message to "Место 📝"
   ├── 📍 Локация (Location)  ──tap──→  Message to "Место 📝"
   └── ...
```

### Design Questions (To Be Decided)

#### 1. Template Configuration
| Option | Description |
|--------|-------------|
| **Fixed list** | Hardcoded templates: Поездка, Пробуждение, Локация, etc. |
| **Editable in-app** | User can add/edit/delete templates |

#### 2. Target Groups
| Option | Description |
|--------|-------------|
| **Single group** | Only "Место 📝" (Location) |
| **Multiple groups** | Different groups per template (Idea, Finance, Inbox...) |

#### 3. Additional Features
| Feature | Description |
|---------|-------------|
| **Auto geolocation** | Attach current GPS coordinates to message |
| **Free text input** | Optional text field before sending |
| **Message history** | View log of sent messages |

#### 4. iOS Widgets
| Option | Description |
|--------|-------------|
| **App only** | Must open app to send |
| **Home screen widgets** | Buttons directly on iOS home screen (WidgetKit) |

## Detailed Findings

### Project Structure

The project directory contains only configuration files:

```
Tg-Templates/
├── .claude/
│   ├── agents/
│   │   ├── codebase-analyzer.md
│   │   ├── codebase-locator.md
│   │   ├── codebase-pattern-finder.md
│   │   ├── thoughts-analyzer.md
│   │   ├── thoughts-locator.md
│   │   └── web-search-researcher.md
│   ├── commands/
│   │   └── [27 slash command templates]
│   └── settings.json
├── .gitignore
└── thoughts/
    └── shared/
        └── research/
            └── [this document]
```

### iOS Application Components

**Status**: Not implemented

No Swift source files, Xcode project files, or iOS-related assets exist:
- No `.xcodeproj` or `.xcworkspace`
- No `.swift` files
- No `Info.plist`
- No storyboards or SwiftUI views
- No asset catalogs

### Telegram Integration

**Status**: Not implemented

No Telegram-related code exists:
- No Telegram Bot API client
- No TDLib integration
- No authentication flow
- No message sending functionality
- No group management

### Template Management System

**Status**: Not implemented

No template system exists:
- No data models for templates
- No persistence layer (CoreData, SQLite, UserDefaults)
- No template CRUD operations
- No UI for template management

### User Interface

**Status**: Not implemented

No UI components exist:
- No button-based message sending interface
- No template selection views
- No group selection views
- No settings or configuration screens

## Code References

No code references available - this is a greenfield project.

## Architecture Documentation

No architecture has been implemented. Based on the project name and description, the intended architecture would likely include:

1. **iOS App Layer**
   - SwiftUI or UIKit views
   - Template list/grid view
   - One-tap send buttons per template
   - Group/chat selector

2. **Data Layer**
   - Template model (text, target group, metadata)
   - Local persistence (CoreData or SwiftData)
   - Telegram credentials storage (Keychain)

3. **Telegram Integration Layer**
   - Bot API client OR TDLib wrapper
   - Authentication handling
   - Message sending API
   - Group enumeration

## Historical Context (from thoughts/)

No prior research or documentation exists in the thoughts directory. This is the first research document for this project.

## Related Research

None - this is the initial research document.

## Open Questions

### Technical Questions

1. **Telegram Integration Approach**: Should the app use:
   - Telegram Bot API (simpler, requires bot token, messages appear from bot)
   - TDLib (complex, full client, messages appear from user)
   - URL schemes (limited, opens Telegram app)

2. **Authentication Flow**: How will users authenticate with Telegram?

3. **Template Storage**: Local-only or cloud-synced templates?

4. **Target Platform**: iOS only, or also macOS/iPadOS with Catalyst?

5. **Minimum iOS Version**: What iOS version to target?

6. **Distribution**: App Store or ad-hoc/TestFlight only?

### Product Questions (User Input Needed)

7. **Template Configuration**: Fixed list or editable in-app?

8. **Target Groups**: Single group ("Место 📝") or multiple groups per template?

9. **Additional Features**:
   - Auto geolocation?
   - Free text input before sending?
   - Message history?

10. **iOS Widgets**: Home screen widgets (WidgetKit) for 1-tap sending without opening app?
