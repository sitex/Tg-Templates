import SwiftUI

struct TemplateListView: View {
    @ObservedObject private var connectivity = WatchConnectivityManager.shared

    var body: some View {
        NavigationStack {
            Group {
                if connectivity.templates.isEmpty {
                    emptyStateView
                } else {
                    templateList
                }
            }
            .navigationTitle("Templates")
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "doc.text")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text("No Templates")
                .font(.headline)
            Text("Add templates in the iPhone app")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private var templateList: some View {
        List(connectivity.templates) { template in
            NavigationLink(value: template) {
                TemplateRowView(template: template)
            }
        }
        .navigationDestination(for: WidgetTemplate.self) { template in
            TemplateDetailView(template: template)
        }
    }
}

#Preview {
    TemplateListView()
}
