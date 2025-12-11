import SwiftUI
import SwiftData

struct TemplateEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let template: Template?

    @State private var name = ""
    @State private var icon = "paperplane.fill"
    @State private var messageText = ""
    @State private var targetGroupId: Int64?
    @State private var targetGroupName: String?
    @State private var includeLocation = false

    @State private var showingIconPicker = false
    @State private var showingGroupPicker = false

    private var isEditing: Bool { template != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Template Info") {
                    TextField("Name", text: $name)

                    Button {
                        showingIconPicker = true
                    } label: {
                        HStack {
                            Text("Icon")
                            Spacer()
                            Image(systemName: icon)
                                .foregroundColor(.accentColor)
                        }
                    }
                }

                Section("Message") {
                    TextEditor(text: $messageText)
                        .frame(minHeight: 100)
                }

                Section("Target Group") {
                    Button {
                        showingGroupPicker = true
                    } label: {
                        HStack {
                            Text("Group")
                            Spacer()
                            Text(targetGroupName ?? "Select...")
                                .foregroundColor(targetGroupName == nil ? .secondary : .primary)
                        }
                    }
                }

                Section("Options") {
                    Toggle("Include Location", isOn: $includeLocation)
                }

                if isEditing {
                    Section {
                        Button("Delete Template", role: .destructive) {
                            deleteTemplate()
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Template" : "New Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveTemplate() }
                        .disabled(name.isEmpty || messageText.isEmpty || targetGroupId == nil)
                }
            }
            .sheet(isPresented: $showingIconPicker) {
                IconPickerView(selectedIcon: $icon)
            }
            .sheet(isPresented: $showingGroupPicker) {
                GroupPickerView(
                    selectedGroupId: $targetGroupId,
                    selectedGroupName: $targetGroupName
                )
            }
            .onAppear {
                if let template = template {
                    name = template.name
                    icon = template.icon
                    messageText = template.messageText
                    targetGroupId = template.targetGroupId
                    targetGroupName = template.targetGroupName
                    includeLocation = template.includeLocation
                }
            }
        }
    }

    private func saveTemplate() {
        if let template = template {
            template.name = name
            template.icon = icon
            template.messageText = messageText
            template.targetGroupId = targetGroupId
            template.targetGroupName = targetGroupName
            template.includeLocation = includeLocation
            template.updatedAt = Date()
        } else {
            let newTemplate = Template(
                name: name,
                icon: icon,
                messageText: messageText,
                targetGroupId: targetGroupId,
                targetGroupName: targetGroupName,
                includeLocation: includeLocation
            )
            modelContext.insert(newTemplate)
        }

        dismiss()
    }

    private func deleteTemplate() {
        if let template = template {
            modelContext.delete(template)
        }
        dismiss()
    }
}

#Preview {
    TemplateEditView(template: nil)
        .modelContainer(for: Template.self, inMemory: true)
}
