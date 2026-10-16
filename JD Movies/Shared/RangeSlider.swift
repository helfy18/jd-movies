import SwiftUI

/// A two-thumb slider for selecting a closed range, used for score and runtime filters.
struct RangeSlider: View {
    @Binding var range: ClosedRange<Double>
    let bounds: ClosedRange<Double>
    var step: Double = 1

    private let thumbSize: CGFloat = 26
    private let trackHeight: CGFloat = 4
    private let spaceName = "RangeSliderTrack"

    var body: some View {
        GeometryReader { geometry in
            let trackWidth = max(geometry.size.width - thumbSize, 1)
            let lowerX = position(of: range.lowerBound, trackWidth: trackWidth)
            let upperX = position(of: range.upperBound, trackWidth: trackWidth)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.appMuted.opacity(0.4))
                    .frame(height: trackHeight)
                    .padding(.horizontal, thumbSize / 2)
                Capsule()
                    .fill(Color.appAccent)
                    .frame(width: max(0, upperX - lowerX), height: trackHeight)
                    .offset(x: lowerX + thumbSize / 2)
                thumb
                    .offset(x: lowerX)
                    .gesture(drag(trackWidth: trackWidth) { value in
                        range = min(value, range.upperBound)...range.upperBound
                    })
                    .accessibilityLabel("Minimum")
                    .accessibilityValue(Text(range.lowerBound.formatted()))
                thumb
                    .offset(x: upperX)
                    .gesture(drag(trackWidth: trackWidth) { value in
                        range = range.lowerBound...max(value, range.lowerBound)
                    })
                    .accessibilityLabel("Maximum")
                    .accessibilityValue(Text(range.upperBound.formatted()))
            }
            .coordinateSpace(name: spaceName)
        }
        .frame(height: thumbSize)
    }

    private var thumb: some View {
        Circle()
            .fill(Color.appAccent)
            .frame(width: thumbSize, height: thumbSize)
            .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
    }

    private var span: Double {
        max(bounds.upperBound - bounds.lowerBound, 1)
    }

    private func position(of value: Double, trackWidth: CGFloat) -> CGFloat {
        let fraction = (value - bounds.lowerBound) / span
        return CGFloat(min(max(fraction, 0), 1)) * trackWidth
    }

    private func drag(trackWidth: CGFloat, update: @escaping (Double) -> Void) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named(spaceName))
            .onChanged { gesture in
                let fraction = Double((gesture.location.x - thumbSize / 2) / trackWidth)
                let raw = bounds.lowerBound + min(max(fraction, 0), 1) * span
                let stepped = (raw / step).rounded() * step
                update(min(max(stepped, bounds.lowerBound), bounds.upperBound))
            }
    }
}
