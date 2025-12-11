import SwiftUI

struct GroupPickerView: View {
    @ObservedObject var telegram = TelegramService.shared
    @Binding var selectedGroupId: Int64?
    @Binding var selectedGroupName: String?
    @Environment(\.dismiss) private var dismiss

    @State private var isLoading = true
    @State private var searchText = ""

    var filteredGroups: [TelegramGroup] {
        if searchText.isEmpty {
            return telegram.groups
        }
        return telegram.groups.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading groups...")
                } else if telegram.groups.isEmpty {
                    ContentUnavailableView(
                        "No Groups",
                        systemImage: "person.3",
                        description: Text("You're not a member of any groups")
                    )
                } else {
                    List(filteredGroups) { group in
                        Button {
                            selectedGroupId = group.id
                            selectedGroupName = group.title
                            dismiss()
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(group.title)
                                        .foregroundColor(.primary)
                                    Text("\(group.memberCount) members")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if selectedGroupId == group.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                    .searchable(text: $searchText, prompt: "Search groups")
                }
            }
            .navigationTitle("Select Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .task {
            do {
                try await telegram.fetchGroups()
            } catch {
                print("Error fetching groups: \(error)")
            }
            isLoading = false
        }
    }
}

#Preview {
    GroupPickerView(
        selectedGroupId: .constant(nil),
        selectedGroupName: .constant(nil)
    )
}
