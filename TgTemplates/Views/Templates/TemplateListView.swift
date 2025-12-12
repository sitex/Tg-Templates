import SwiftUI
import SwiftData
import WidgetKit

struct TemplateListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Template.sortOrder) private var templates: [Template]

    @State private var showingAddTemplate = false
    @State private var templateToEdit: Template?
    @State private var templateToDelete: Template?

    let columns = [
        GridItem(.adaptive(minimum: 100), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                if templates.isEmpty {
                    ContentUnavailableView(
                        "No Templates",
                        systemImage: "doc.badge.plus",
                        description: Text("Tap + to create your first template")
                    )
                    .padding(.top, 100)
                } else {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(templates) { template in
                            TemplateButtonView(
                                template: template,
                                onEdit: { templateToEdit = template },
                                onDelete: { templateToDelete = template },
                                onDuplicate: { duplicateTemplate(template) }
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Templates")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddTemplate = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showingAddTemplate) {
                TemplateEditView(template: nil)
            }
            .sheet(item: $templateToEdit) { template in
                TemplateEditView(template: template)
            }
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
            .onAppear {
                syncWidgetData()
            }
            .onChange(of: templates.count) {
                syncWidgetData()
            }
        }
    }

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

        // Send to Watch via WatchConnectivity
        WatchConnectivityManager.shared.sendTemplates(widgetTemplates)

        WidgetCenter.shared.reloadAllTimelines()
    }
}

#Preview {
    TemplateListView()
        .modelContainer(for: Template.self, inMemory: true)
}
