import SwiftUI

/// Very lightweight line chart for watchOS that plots an array of Double values.
/// Used to compare raw vs filtered simulated motion data.
struct LineChart: View {
    let values: [Double]
    let color: Color
    let lineWidth: CGFloat

    init(values: [Double], color: Color = .blue, lineWidth: CGFloat = 2) {
        self.values = values
        self.color = color
        self.lineWidth = lineWidth
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Optional subtle background
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.15))

                if let path = makePath(in: geometry.size) {
                    path
                        .stroke(color, lineWidth: lineWidth)
                }
            }
        }
    }

    // MARK: - Path construction
    private func makePath(in size: CGSize) -> Path? {
        guard values.count >= 2,
              let minValue = values.min(),
              let maxValue = values.max(),
              maxValue - minValue > 0
        else {
            return nil
        }

        let width = size.width
        let height = size.height
        let count = values.count

        let stepX = width / CGFloat(max(count - 1, 1))

        var path = Path()

        for (index, value) in values.enumerated() {
            let x = CGFloat(index) * stepX

            // Normalize to 0...1 then flip vertically so higher values are at the top
            let normalized = (value - minValue) / (maxValue - minValue)
            let y = height * (1 - CGFloat(normalized))

            if index == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        return path
    }
}
