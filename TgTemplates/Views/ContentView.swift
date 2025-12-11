import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "paperplane.fill")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Tg Templates")
                .font(.title)
            Text("Setup complete! Ready for Phase 2.")
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
