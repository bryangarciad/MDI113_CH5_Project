import SwiftUI

/// View that shows a simulated noisy signal (raw) and the same signal after
/// applying a moving-window average filter, so students can see the smoothing effect.
struct SimulatedMotionView: View {
    @StateObject private var viewModel = SimulatedMotionViewModel()

    var body: some View {
        VStack(spacing: 8) {
            Text("Simulated Motion Data")
                .font(.headline)

            VStack(alignment: .leading, spacing: 4) {
                Text("Raw")
                    .font(.caption2)
                    .foregroundColor(.red)

                LineChart(values: viewModel.rawValues, color: .red, lineWidth: 1.5)
                    .frame(height: 40)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Filtered (Moving Avg)")
                    .font(.caption2)
                    .foregroundColor(.green)

                LineChart(values: viewModel.filteredValues, color: .green, lineWidth: 1.5)
                    .frame(height: 40)
            }
        }
        .padding(8)
        .onAppear {
            viewModel.start()
        }
        .onDisappear {
            viewModel.stop()
        }
    }
}

#Preview {
    SimulatedMotionView()
}
