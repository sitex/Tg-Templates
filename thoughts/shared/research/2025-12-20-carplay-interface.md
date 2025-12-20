---
date: 2025-12-20T11:33:44+10:00
researcher: Claude
git_commit: c54efd994036ccae4ea73fb93d4fcd09725832b4
branch: main
repository: Tg-Templates
topic: "CarPlay Interface for TgTemplates App"
tags: [research, codebase, carplay, multi-platform, ios, telegram]
status: complete
last_updated: 2025-12-20
last_updated_by: Claude
---

# Research: CarPlay Interface for TgTemplates App

**Date**: 2025-12-20T11:33:44+10:00
**Researcher**: Claude
**Git Commit**: c54efd994036ccae4ea73fb93d4fcd09725832b4
**Branch**: main
**Repository**: Tg-Templates

## Research Question

Как создать интерфейс для Apple CarPlay в приложении TgTemplates (Telegram шаблоны сообщений)?

## Summary

TgTemplates — это мультиплатформенное приложение для отправки шаблонных сообщений в Telegram, поддерживающее iOS, watchOS и виджеты. Добавление CarPlay потребует:
1. Получения CarPlay entitlement от Apple (категория Communication)
2. Создания CarPlaySceneDelegate
3. Настройки Info.plist для поддержки двух сцен
4. Использования CPListTemplate или CPGridTemplate для отображения шаблонов
5. Интеграции с существующим TelegramService для отправки сообщений

Приложение уже имеет архитектуру для мультиплатформенности (App Groups, shared models), что упрощает добавление CarPlay.

## Detailed Findings

### Current App Architecture

**TgTemplates** — приложение для отправки шаблонных сообщений в Telegram.

#### Существующие платформы:
- **iOS App** (`TgTemplates/`) — полнофункциональное приложение
- **iOS Widget** (`TgTemplatesWidget/`) — быстрый доступ с домашнего экрана
- **watchOS App** (`TgTemplatesWatch/`) — отправка с Apple Watch

#### Ключевые компоненты:
| Компонент | Расположение | Назначение |
|-----------|--------------|------------|
| TgTemplatesApp | `TgTemplates/TgTemplatesApp.swift` | Точка входа iOS приложения |
| TelegramService | `TgTemplates/Services/TelegramService.swift` | Интеграция с Telegram API |
| WidgetTemplate | `TgTemplates/Models/WidgetTemplate.swift` | Shared модель шаблона |
| UserDefaults+AppGroup | `TgTemplates/Extensions/UserDefaults+AppGroup.swift` | Общие данные между таргетами |

#### Существующие паттерны мультиплатформенности:
1. **App Group**: `group.com.sitex.TgTemplates` для обмена данными
2. **Shared Models**: `WidgetTemplate` дублируется в каждом таргете
3. **Pending Action Pattern**: виджет/watch сохраняют ID в UserDefaults, iOS обрабатывает
4. **WatchConnectivity**: двунаправленная связь iOS ↔ watchOS

### CarPlay Framework Overview

#### Поддерживаемые категории приложений:
- **Audio** — музыка, подкасты
- **Communication** — сообщения (подходит для TgTemplates)
- **Navigation** — карты
- **Parking, EV Charging, Fueling** — точки интереса
- **Quick Food Ordering** — заказ еды
- **Driving Task** — задачи для водителя

#### Доступные шаблоны (CPTemplate):

| Шаблон | Назначение | Подходит для TgTemplates |
|--------|------------|--------------------------|
| CPListTemplate | Список элементов | ✅ Да — список шаблонов |
| CPGridTemplate | Сетка кнопок (до 8) | ✅ Да — быстрый доступ |
| CPTabBarTemplate | Вкладки | ⚠️ Возможно — для группировки |
| CPInformationTemplate | Информация | ⚠️ Для подтверждения отправки |
| CPAlertTemplate | Алерты | ✅ Да — статус отправки |

#### Ограничения CarPlay:
- Максимум 5 шаблонов в навигационном стеке
- Root template должен быть `CPTabBarTemplate`, `CPGridTemplate` или `CPListTemplate`
- Минимальная кастомизация UI (безопасность водителя)
- Нельзя скрыть иконку после добавления entitlement

### Required Implementation Components

#### 1. CarPlay Entitlement

Необходимо запросить entitlement на [developer.apple.com/carplay](https://developer.apple.com/carplay):

```
Категория: Communication
Entitlement: com.apple.developer.carplay-communication
```

После одобрения добавить в `TgTemplates.entitlements`:
```xml
<key>com.apple.developer.carplay-communication</key>
<true/>
```

#### 2. CarPlaySceneDelegate

Создать новый файл `TgTemplates/CarPlay/CarPlaySceneDelegate.swift`:

```swift
import CarPlay

class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    var interfaceController: CPInterfaceController?

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        self.interfaceController = interfaceController

        // Загрузить шаблоны из shared UserDefaults
        let templates = UserDefaults.appGroup.widgetTemplates

        // Создать список
        let listItems = templates.map { template in
            let item = CPListItem(
                text: template.name,
                detailText: template.targetGroupName ?? "No group",
                image: UIImage(systemName: template.icon)
            )
            item.handler = { [weak self] _, completion in
                self?.sendTemplate(template)
                completion()
            }
            return item
        }

        let section = CPListSection(items: listItems)
        let listTemplate = CPListTemplate(
            title: "Templates",
            sections: [section]
        )

        interfaceController.setRootTemplate(listTemplate, animated: true)
    }

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnect interfaceController: CPInterfaceController
    ) {
        self.interfaceController = nil
    }

    private func sendTemplate(_ template: WidgetTemplate) {
        Task { @MainActor in
            do {
                try await TelegramService.shared.sendTemplateMessage(template)
                showSuccess()
            } catch {
                showError(error.localizedDescription)
            }
        }
    }

    private func showSuccess() {
        let alert = CPAlertTemplate(
            titleVariants: ["Sent!"],
            actions: [
                CPAlertAction(title: "OK", style: .default) { _ in
                    self.interfaceController?.dismissTemplate(animated: true)
                }
            ]
        )
        interfaceController?.presentTemplate(alert, animated: true)
    }

    private func showError(_ message: String) {
        let alert = CPAlertTemplate(
            titleVariants: ["Error: \(message)"],
            actions: [
                CPAlertAction(title: "OK", style: .cancel) { _ in
                    self.interfaceController?.dismissTemplate(animated: true)
                }
            ]
        )
        interfaceController?.presentTemplate(alert, animated: true)
    }
}
```

#### 3. Info.plist Configuration

Добавить в `TgTemplates/Info.plist`:

```xml
<key>UIApplicationSceneManifest</key>
<dict>
    <key>UIApplicationSupportsMultipleScenes</key>
    <true/>
    <key>UISceneConfigurations</key>
    <dict>
        <!-- CarPlay Scene -->
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
        <!-- iPhone Scene -->
        <key>UIWindowSceneSessionRoleApplication</key>
        <array>
            <dict>
                <key>UISceneClassName</key>
                <string>UIWindowScene</string>
                <key>UISceneConfigurationName</key>
                <string>Default Configuration</string>
            </dict>
        </array>
    </dict>
</dict>
```

#### 4. Build Settings

В Xcode:
1. Build Settings → "Application Scene Manifest (Generation)" → **Disabled**
2. Это предотвращает перезапись Info.plist

### Proposed CarPlay UI Structure

```
CarPlay Interface
├── Root: CPListTemplate "TgTemplates"
│   ├── Section: "Templates"
│   │   ├── CPListItem: Template 1 → tap → send → CPAlertTemplate "Sent!"
│   │   ├── CPListItem: Template 2
│   │   ├── CPListItem: Template 3
│   │   └── ...
│   └── Section: "Settings" (optional)
│       └── CPListItem: "Open on iPhone"
│
└── Alternative: CPGridTemplate (до 8 кнопок)
    ├── CPGridButton: Template 1 (icon + name)
    ├── CPGridButton: Template 2
    └── ...
```

### Integration with Existing Architecture

#### Data Flow (CarPlay → Telegram):

```
1. CarPlay connects → CarPlaySceneDelegate.didConnect()
2. Load templates from UserDefaults.appGroup.widgetTemplates
3. Display in CPListTemplate
4. User taps template → handler called
5. TelegramService.shared.sendTemplateMessage()
6. Show result via CPAlertTemplate
```

#### Синхронизация данных:

CarPlay будет использовать тот же механизм, что и виджет:
- Чтение из `UserDefaults.appGroup.widgetTemplates`
- Данные синхронизируются при изменении в iOS app (`syncWidgetData()`)

### File Structure for CarPlay Target

```
TgTemplates/
├── CarPlay/
│   ├── CarPlaySceneDelegate.swift      # Основной делегат
│   └── CarPlayTemplateManager.swift    # (опционально) Управление шаблонами
├── TgTemplatesApp.swift                # Без изменений (SwiftUI @main)
├── Info.plist                          # + Scene manifest
└── TgTemplates.entitlements            # + CarPlay entitlement
```

### Testing CarPlay

#### Xcode CarPlay Simulator:
1. Window → Devices and Simulators
2. External Displays → CarPlay
3. Или: I/O → External Displays → CarPlay

#### Ограничения симулятора:
- Не все функции доступны
- Реальное тестирование в автомобиле рекомендуется

## Code References

- `TgTemplates/TgTemplatesApp.swift:1-88` — Точка входа iOS приложения
- `TgTemplates/Services/TelegramService.swift:192-230` — Отправка сообщений
- `TgTemplates/Models/WidgetTemplate.swift:1-10` — Модель шаблона
- `TgTemplates/Extensions/UserDefaults+AppGroup.swift:1-39` — Shared данные
- `TgTemplatesWatch/WatchConnectivityManager.swift:1-95` — Паттерн для нового таргета

## Architecture Documentation

### Существующий паттерн мультиплатформенности

```
                    ┌─────────────────┐
                    │   iOS App       │
                    │ (TgTemplates)   │
                    └────────┬────────┘
                             │
            ┌────────────────┼────────────────┐
            │                │                │
            ▼                ▼                ▼
    ┌───────────┐    ┌───────────┐    ┌───────────┐
    │  Widget   │    │  watchOS  │    │  CarPlay  │ ← NEW
    │ Extension │    │   App     │    │  Scene    │
    └─────┬─────┘    └─────┬─────┘    └─────┬─────┘
          │                │                │
          └────────────────┼────────────────┘
                           │
                           ▼
                ┌─────────────────────┐
                │    App Group        │
                │ UserDefaults        │
                │ widgetTemplates     │
                └─────────────────────┘
                           │
                           ▼
                ┌─────────────────────┐
                │  TelegramService    │
                │  (singleton)        │
                └─────────────────────┘
```

### CarPlay отличается от watchOS:
- **watchOS**: Отдельный таргет, коммуникация через WatchConnectivity
- **CarPlay**: Дополнительная сцена в том же iOS таргете

## Historical Context (from thoughts/)

Существующие исследования:
- `thoughts/shared/research/2025-12-11-telegram-templates-iphone-app.md` — Основное iOS приложение
- `thoughts/shared/research/2025-12-12-apple-watch-app-templates.md` — Паттерн добавления watchOS
- `thoughts/shared/plans/2025-12-12-apple-watch-app.md` — План реализации watch app

Проект следует паттерну постепенного добавления платформ с использованием shared данных через App Group.

## Related Research

- [Apple CarPlay Framework Documentation](https://developer.apple.com/documentation/carplay)
- [CPTemplateApplicationSceneDelegate](https://developer.apple.com/documentation/carplay/cptemplateapplicationscenedelegate)
- [Requesting CarPlay Entitlements](https://developer.apple.com/documentation/carplay/requesting-carplay-entitlements)
- [Creating CarPlay apps within a SwiftUI app lifecycle](https://www.createwithswift.com/creating-carplay-apps-within-a-swiftui-app-lifecyle/)
- [WWDC22 - Get more mileage out of your app with CarPlay](https://developer.apple.com/videos/play/wwdc2022/10016/)

## Open Questions

1. **Entitlement Approval**: Сколько времени занимает одобрение CarPlay entitlement от Apple?
2. **Communication Category**: Подходит ли категория "Communication" для приложения отправки шаблонов, или нужна другая?
3. **TelegramService Lifecycle**: Нужно ли запускать TelegramService при подключении CarPlay, если iOS app не активен?
4. **Location Services**: Как работает `includeLocation` для шаблонов в CarPlay сценарии?
5. **Voice Control**: Нужна ли интеграция с Siri для hands-free отправки?
