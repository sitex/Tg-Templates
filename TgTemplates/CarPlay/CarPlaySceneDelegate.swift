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
        if #available(iOS 16.0, *) {
            let intent = CarPlaySendTemplateIntent(templateName: template.name)

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
}
