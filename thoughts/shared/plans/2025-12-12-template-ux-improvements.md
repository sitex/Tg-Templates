# Template UX Improvements - Context Menu Implementation Plan

## Overview

Add context menu support to template buttons for improved discoverability of edit/delete actions, plus a new duplicate feature. Replace the current long-press-only interaction with a standard iOS context menu pattern.

## Current State Analysis

**Current interaction model:**
- **Tap** → Send message (working well)
- **Long press** → Opens edit sheet directly (not discoverable)
- **Delete** → Only available inside edit view, no confirmation

**Problems:**
1. Long press to edit is not discoverable - users may not know it exists
2. No way to delete without opening edit view first
3. Delete has no confirmation (risky for destructive action)
4. No duplicate functionality

### Key Discoveries:
- Templates displayed in `LazyVGrid` - can't use `.swipeActions` (List-only)
- App already uses `.confirmationDialog` for logout (`SettingsView.swift:49-61`)
- App uses `.sensoryFeedback(.success)` pattern for haptics (`TemplateButtonView.swift:47`)
- Delete currently calls `modelContext.delete()` directly without confirmation

## Desired End State

After implementation:
1. **Long press on template** → Shows context menu with Edit, Delete, Duplicate options
2. **Edit option** → Opens edit sheet (same as before)
3. **Delete option** → Shows confirmation dialog, then deletes with animation
4. **Duplicate option** → Creates copy with "(Copy)" suffix
5. **Haptic feedback** → Warning haptic on delete confirmation
6. **Animation** → Smooth removal animation when template deleted

### Verification:
- Long press shows context menu with 3 options
- Edit opens the edit sheet
- Delete shows confirmation, then removes template with animation
- Duplicate creates a new template immediately visible in grid
- Widget syncs after delete/duplicate operations

## What We're NOT Doing

- Swipe actions (not supported on LazyVGrid)
- Drag-to-reorder (separate feature)
- Bulk selection/deletion
- Undo functionality

## Implementation Approach

Replace the callback-based long press with SwiftUI's native `.contextMenu` modifier. Move delete logic from `TemplateEditView` to `TemplateListView` with confirmation dialog. Add duplicate functionality in `TemplateListView`.

---

## Phase 1: Add Context Menu to TemplateButtonView

### Overview
Replace `.onLongPressGesture` with `.contextMenu` modifier. Change callback signature to support multiple actions.

### Changes Required:

#### 1. TemplateButtonView.swift
**File**: `TgTemplates/Views/Templates/TemplateButtonView.swift`

**Change 1**: Update callback properties (line 5)

Replace:
```swift
let onLongPress: () -> Void
```

With:
```swift
let onEdit: () -> Void
let onDelete: () -> Void
let onDuplicate: () -> Void
```

**Change 2**: Replace `.onLongPressGesture` with `.contextMenu` (lines 44-46)

Replace:
```swift
.onLongPressGesture {
    onLongPress()
}
```

With:
```swift
.contextMenu {
    Button {
        onEdit()
    } label: {
        Label("Edit", systemImage: "pencil")
    }

    Button {
        onDuplicate()
    } label: {
        Label("Duplicate", systemImage: "doc.on.doc")
    }

    Divider()

    Button(role: .destructive) {
        onDelete()
    } label: {
        Label("Delete", systemImage: "trash")
    }
}
```

### Success Criteria:

#### Automated Verification:
- [ ] Project builds without errors: `xcodebuild -scheme TgTemplates -destination 'platform=iOS Simulator,name=iPhone 16' build`

#### Manual Verification:
- [ ] Long press on template shows context menu
- [ ] Menu displays Edit, Duplicate, and Delete options
- [ ] Delete option appears in red (destructive style)

---

## Phase 2: Update TemplateListView for New Callbacks

### Overview
Update `TemplateListView` to provide all three callbacks and handle the actions.

### Changes Required:

#### 1. TemplateListView.swift
**File**: `TgTemplates/Views/Templates/TemplateListView.swift`

**Change 1**: Add new state variables (after line 10)

Add after `@State private var templateToEdit: Template?`:
```swift
@State private var templateToDelete: Template?
```

**Change 2**: Update TemplateButtonView instantiation (lines 29-32)

Replace:
```swift
TemplateButtonView(
    template: template,
    onLongPress: { templateToEdit = template }
)
```

With:
```swift
TemplateButtonView(
    template: template,
    onEdit: { templateToEdit = template },
    onDelete: { templateToDelete = template },
    onDuplicate: { duplicateTemplate(template) }
)
```

**Change 3**: Add confirmation dialog (after line 60, after the `.sheet(item:)` modifier)

Add:
```swift
.confirmationDialog(
    "Delete Template",
    isPresented: Binding(
        get: { templateToDelete != nil },
        set: { if !$0 { templateToDelete = nil } }
    ),
    titleVisibility: .visible
) {
    Button("Delete", role: .destructive) {
        if let template = templateToDelete {
            deleteTemplate(template)
        }
    }
} message: {
    if let template = templateToDelete {
        Text("Are you sure you want to delete \"\(template.name)\"?")
    }
}
.sensoryFeedback(.warning, trigger: templateToDelete)
```

**Change 4**: Add helper functions (before `syncWidgetData()`, around line 69)

Add:
```swift
private func deleteTemplate(_ template: Template) {
    withAnimation {
        modelContext.delete(template)
    }
}

private func duplicateTemplate(_ template: Template) {
    let copy = Template(
        name: "\(template.name) (Copy)",
        icon: template.icon,
        messageText: template.messageText,
        targetGroupId: template.targetGroupId,
        targetGroupName: template.targetGroupName,
        includeLocation: template.includeLocation
    )
    withAnimation {
        modelContext.insert(copy)
    }
}
```

### Success Criteria:

#### Automated Verification:
- [ ] Project builds without errors: `xcodebuild -scheme TgTemplates -destination 'platform=iOS Simulator,name=iPhone 16' build`

#### Manual Verification:
- [ ] Context menu Edit option opens edit sheet
- [ ] Context menu Delete option shows confirmation dialog
- [ ] Confirmation dialog shows template name
- [ ] Confirming delete removes template with animation
- [ ] Canceling delete keeps template
- [ ] Duplicate creates new template with "(Copy)" suffix
- [ ] Widget updates after delete/duplicate

---

## Phase 3: Keep Delete in TemplateEditView (Optional Cleanup)

### Overview
The delete button in `TemplateEditView` can remain as an alternative way to delete. For consistency, add confirmation there too.

### Changes Required:

#### 1. TemplateEditView.swift
**File**: `TgTemplates/Views/Templates/TemplateEditView.swift`

**Change 1**: Add state for confirmation (after line 18)

Add:
```swift
@State private var showingDeleteConfirm = false
```

**Change 2**: Update delete button (lines 64-66)

Replace:
```swift
Button("Delete Template", role: .destructive) {
    deleteTemplate()
}
```

With:
```swift
Button("Delete Template", role: .destructive) {
    showingDeleteConfirm = true
}
```

**Change 3**: Add confirmation dialog (after line 89, after `.sheet(isPresented: $showingGroupPicker)`)

Add:
```swift
.confirmationDialog(
    "Delete Template",
    isPresented: $showingDeleteConfirm,
    titleVisibility: .visible
) {
    Button("Delete", role: .destructive) {
        deleteTemplate()
    }
} message: {
    Text("Are you sure you want to delete this template?")
}
.sensoryFeedback(.warning, trigger: showingDeleteConfirm)
```

### Success Criteria:

#### Automated Verification:
- [ ] Project builds without errors: `xcodebuild -scheme TgTemplates -destination 'platform=iOS Simulator,name=iPhone 16' build`

#### Manual Verification:
- [ ] Delete button in edit view shows confirmation
- [ ] Confirming deletes template and dismisses sheet
- [ ] Canceling keeps template and stays in edit view
- [ ] Haptic feedback plays when confirmation appears

---

## Testing Strategy

### Unit Tests:
- Not applicable (UI changes only)

### Integration Tests:
- Not applicable

### Manual Testing Steps:
1. Create a test template
2. Long press on template - verify context menu appears
3. Tap "Edit" - verify edit sheet opens
4. Cancel edit, long press again
5. Tap "Duplicate" - verify copy appears in grid with "(Copy)" suffix
6. Long press on original template
7. Tap "Delete" - verify confirmation dialog appears with template name
8. Tap "Cancel" - verify template still exists
9. Tap "Delete" again, confirm - verify template removed with smooth animation
10. Open remaining template for editing
11. Tap "Delete Template" button - verify confirmation appears
12. Confirm deletion - verify template deleted and sheet dismissed
13. Verify widget shows updated templates

## Performance Considerations

- `withAnimation` wrapping delete/insert operations ensures smooth transitions
- No performance impact - context menus are native iOS components

## Migration Notes

None - this is additive functionality with no data model changes.

## References

- Research: `thoughts/shared/research/2025-12-12-template-edit-delete.md`
- Logout confirmation pattern: `TgTemplates/Views/Settings/SettingsView.swift:49-61`
- Existing haptic pattern: `TgTemplates/Views/Templates/TemplateButtonView.swift:47`
