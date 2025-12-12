---
date: 2025-12-12T12:00:00+03:00
researcher: claude
git_commit: 6163d18bf98c41144157a42f283c93569fcdb8fd
branch: main
repository: Tg-Templates
topic: "Редактирование и удаление существующих Темплейтов"
tags: [research, templates, swiftui, swiftdata, editing, deletion]
status: complete
last_updated: 2025-12-12
last_updated_by: claude
---

# Research: Редактирование и удаление существующих Темплейтов

**Date**: 2025-12-12
**Researcher**: claude
**Git Commit**: 6163d18bf98c41144157a42f283c93569fcdb8fd
**Branch**: main
**Repository**: Tg-Templates

## Research Question
Как редактировать или удалять существующие Темплейты в приложении?

## Summary

Функциональность редактирования и удаления Темплейтов реализована в `TemplateEditView.swift`. Доступ к редактированию осуществляется через **долгое нажатие** (long press) на кнопку темплейта в списке. Удаление доступно только в режиме редактирования существующего темплейта.

## Detailed Findings

### Как открыть редактирование Темплейта

**Способ**: Долгое нажатие (Long Press) на кнопку темплейта

Реализация в `TemplateButtonView.swift:44-46`:
```swift
.onLongPressGesture {
    onLongPress()
}
```

Callback `onLongPress` передается из `TemplateListView.swift:30-31`:
```swift
TemplateButtonView(
    template: template,
    onLongPress: { templateToEdit = template }
)
```

Когда `templateToEdit` получает значение, открывается sheet с `TemplateEditView` (`TemplateListView.swift:58-60`):
```swift
.sheet(item: $templateToEdit) { template in
    TemplateEditView(template: template)
}
```

### Редактирование Темплейта

`TemplateEditView.swift` определяет режим работы через параметр `template`:
- Если `template != nil` - режим редактирования
- Если `template == nil` - режим создания нового

Проверка режима (`TemplateEditView.swift:20`):
```swift
private var isEditing: Bool { template != nil }
```

**Поля редактирования:**
1. **Name** - название темплейта (TextField)
2. **Icon** - иконка (выбор через IconPickerView)
3. **Message** - текст сообщения (TextEditor)
4. **Group** - целевая группа Telegram (выбор через GroupPickerView)
5. **Include Location** - включить локацию (Toggle)

**Сохранение изменений** (`TemplateEditView.swift:103-125`):
```swift
private func saveTemplate() {
    if let template = template {
        // Режим редактирования - обновляем существующий
        template.name = name
        template.icon = icon
        template.messageText = messageText
        template.targetGroupId = targetGroupId
        template.targetGroupName = targetGroupName
        template.includeLocation = includeLocation
        template.updatedAt = Date()
    } else {
        // Режим создания - создаем новый
        let newTemplate = Template(...)
        modelContext.insert(newTemplate)
    }
    dismiss()
}
```

SwiftData автоматически сохраняет изменения в модели при изменении её свойств.

### Удаление Темплейта

Кнопка удаления отображается **только в режиме редактирования** (`TemplateEditView.swift:62-68`):
```swift
if isEditing {
    Section {
        Button("Delete Template", role: .destructive) {
            deleteTemplate()
        }
    }
}
```

**Функция удаления** (`TemplateEditView.swift:127-132`):
```swift
private func deleteTemplate() {
    if let template = template {
        modelContext.delete(template)
    }
    dismiss()
}
```

### Data Model - Template

Модель данных определена в `Template.swift` с использованием SwiftData:

```swift
@Model
final class Template {
    var id: UUID
    var name: String
    var icon: String
    var messageText: String
    var targetGroupId: Int64?
    var targetGroupName: String?
    var includeLocation: Bool
    var createdAt: Date
    var updatedAt: Date
    var sortOrder: Int
}
```

### Синхронизация с виджетом

После изменения списка темплейтов происходит синхронизация с виджетом (`TemplateListView.swift:70-85`):
```swift
private func syncWidgetData() {
    let widgetTemplates = templates.map { template in
        WidgetTemplate(...)
    }
    UserDefaults.appGroup.widgetTemplates = widgetTemplates
    WidgetCenter.shared.reloadAllTimelines()
}
```

Синхронизация вызывается:
- При появлении `TemplateListView` (`.onAppear`)
- При изменении количества темплейтов (`.onChange(of: templates.count)`)

## Code References

- `TgTemplates/Views/Templates/TemplateEditView.swift` - UI редактирования и удаления
  - Строка 20: проверка режима редактирования
  - Строки 62-68: кнопка удаления
  - Строки 103-125: функция сохранения
  - Строки 127-132: функция удаления
- `TgTemplates/Views/Templates/TemplateListView.swift` - список темплейтов
  - Строки 30-31: передача callback для long press
  - Строки 58-60: открытие sheet редактирования
- `TgTemplates/Views/Templates/TemplateButtonView.swift` - кнопка темплейта
  - Строки 44-46: обработка долгого нажатия
- `TgTemplates/Models/Template.swift` - модель данных

## Architecture Documentation

### Паттерн взаимодействия

```
[TemplateListView]
    │
    ├── Отображает список Template через @Query
    │
    └── [TemplateButtonView]
            │
            ├── Короткое нажатие → Отправка сообщения
            │
            └── Долгое нажатие → onLongPress callback
                    │
                    └── templateToEdit = template
                            │
                            └── .sheet(item: $templateToEdit)
                                    │
                                    └── [TemplateEditView]
                                            │
                                            ├── Редактирование полей
                                            ├── Сохранение → saveTemplate()
                                            └── Удаление → deleteTemplate()
```

### SwiftData Integration

- `@Model` декоратор делает класс Template персистентным
- `@Environment(\.modelContext)` предоставляет доступ к контексту
- `modelContext.delete()` удаляет объект из базы
- Изменения свойств модели автоматически сохраняются

## Related Research

- `thoughts/shared/research/2025-12-11-telegram-templates-iphone-app.md` - общее исследование приложения
- `thoughts/shared/plans/2025-12-11-telegram-templates-app.md` - план разработки

## Open Questions

Нет открытых вопросов.
