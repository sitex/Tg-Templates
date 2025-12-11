import SwiftUI

struct ContentView: View {
    var body: some View {
        TemplateListView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Template.self, inMemory: true)
}
