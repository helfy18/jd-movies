import SwiftUI

/// An outlined capsule label, the site's `Chip`.
struct ChipLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(.appAccent)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .overlay(Capsule().stroke(Color.appAccent.opacity(0.7), lineWidth: 1))
            .contentShape(Capsule())
    }
}

/// A chip that pushes a route (a filtered grid or a person).
struct ChipLink: View {
    let text: String
    let route: Route

    var body: some View {
        NavigationLink(value: route) {
            ChipLabel(text: text)
        }
        .buttonStyle(.plain)
    }
}

/// Lays children out left to right, wrapping onto new lines as needed.
struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width.flatMap { $0.isFinite ? $0 : nil } ?? .greatestFiniteMagnitude
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var usedWidth: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            usedWidth = max(usedWidth, x - spacing)
        }
        let width = proposal.width.flatMap { $0.isFinite ? $0 : nil } ?? usedWidth
        return CGSize(width: width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
