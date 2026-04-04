import Foundation
import Combine

/// View model that generates simulated motion data so students can see
/// the effect of a moving-window average filter without needing real sensors.
final class SimulatedMotionViewModel: ObservableObject {
    // MARK: - Published data for the charts
    @Published var rawValues: [Double] = []
    @Published var filteredValues: [Double] = []

    // MARK: - Private properties
    private let windowSize: Int = 10              // moving average window
    private let maxSampleCount: Int = 5

    private var timerCancellable: AnyCancellable?
    private var time: Double = 0                 // simple time counter for the sine wave

    // MARK: - Public control
    func start() {
        // Avoid starting multiple timers
        guard timerCancellable == nil else { return }

        // Reset state when starting so every lesson starts from a clean slate
        time = 0
        rawValues.removeAll()
        filteredValues.removeAll()

        timerCancellable = Timer
            .publish(every: 0.1, on: .main, in: .common) // ~10 Hz
            .autoconnect()
            .sink { [weak self] _ in
                self?.step()
            }
    }

    func stop() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    // MARK: - Simulation step
    private func step() {
        // Move time forward
        time += 0.1

        // Base signal: smooth sine wave (period ~4 seconds)
        let baseSignal = sin(time * 2 * .pi / 4.0)

        // Random noise to make the raw signal jittery
        let noise = Double.random(in: -0.3...0.3)

        let rawSample = baseSignal + noise

        // Append to raw values and keep only the last maxSampleCount
        rawValues.append(rawSample)
        if rawValues.count > maxSampleCount {
            rawValues.removeFirst()
        }

        // Compute moving-window average on the raw values
        let filteredSample = movingAverage(of: rawValues, windowSize: windowSize)

        filteredValues.append(filteredSample)
        if filteredValues.count > maxSampleCount {
            filteredValues.removeFirst()
        }
    }

    // MARK: - Moving average helper
    private func movingAverage(of values: [Double], windowSize: Int) -> Double {
        guard !values.isEmpty else { return 0.0 }

        let count = values.count
        let startIndex = max(0, count - windowSize)
        let window = values[startIndex..<count]

        let sum = window.reduce(0.0, +)
        return sum / Double(window.count)
    }
}
