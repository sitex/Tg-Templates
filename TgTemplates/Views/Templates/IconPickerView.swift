import SwiftUI

struct IconPickerView: View {
    @Binding var selectedIcon: String
    @Environment(\.dismiss) private var dismiss

    let icons = [
        "paperplane.fill", "location.fill", "car.fill", "bed.double.fill",
        "fork.knife", "cup.and.saucer.fill", "figure.walk", "figure.run",
        "bicycle", "tram.fill", "airplane", "house.fill",
        "building.2.fill", "cart.fill", "bag.fill", "creditcard.fill",
        "phone.fill", "envelope.fill", "calendar", "clock.fill",
        "sun.max.fill", "moon.fill", "cloud.fill", "bolt.fill",
        "heart.fill", "star.fill", "flag.fill", "bookmark.fill",
        "tag.fill", "folder.fill", "doc.fill", "pencil",
        "checkmark.circle.fill", "xmark.circle.fill", "exclamationmark.triangle.fill", "info.circle.fill"
    ]

    let columns = [GridItem(.adaptive(minimum: 50))]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(icons, id: \.self) { icon in
                        Button {
                            selectedIcon = icon
                            dismiss()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(selectedIcon == icon ? Color.accentColor : Color.gray.opacity(0.2))
                                    .frame(width: 50, height: 50)

                                Image(systemName: icon)
                                    .font(.title2)
                                    .foregroundColor(selectedIcon == icon ? .white : .primary)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Choose Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    IconPickerView(selectedIcon: .constant("paperplane.fill"))
}
