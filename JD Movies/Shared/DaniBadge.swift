import SwiftUI

/// The "Dani Approved" stamp drawn over posters.
struct DaniBadge: View {
    var size: CGFloat = 40

    var body: some View {
        Image(.dani)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityLabel("Dani Approved")
    }
}

/// The full-size drawing with its credit, shown when the badge is tapped.
struct DaniSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(.dani)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 300)
                Text("Drawing Credit: Phoebe Torres")
                    .font(.footnote)
                    .foregroundStyle(.appAccent)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .screenBackground()
            .navigationTitle("Dani Approved")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
