
import Foundation
import CoreMotion
import Combine

class MotionViewModel: ObservableObject {
    // MARK: - Published Properties (Raw Data)
    @Published var accelerationX: Double = 0.0
    @Published var accelerationY: Double = 0.0
    @Published var accelerationZ: Double = 0.0
    @Published var rotationX: Double = 0.0
    @Published var rotationY: Double = 0.0
    @Published var rotationZ: Double = 0.0
    @Published var isTracking: Bool = false
    @Published var errorMessage: String?

    // MARK: - Published Properties (Filtered Data)
    @Published var filteredAccelX: Double = 0.0
    @Published var filteredAccelY: Double = 0.0
    @Published var filteredAccelZ: Double = 0.0

    // MARK: - Published Properties (Moving Average)
    @Published var avgAccelX: Double = 0.0
    @Published var avgAccelY: Double = 0.0
    @Published var avgAccelZ: Double = 0.0

    // MARK: - Published Properties (Shake Detection)
    @Published var shakeCount: Int = 0
    @Published var magnitude: Double = 0.0
    @Published var filteredMagnitude: Double = 0.0

    // MARK: - Published Properties (Filter Controls)
    @Published var showFiltered: Bool = false
    @Published var windowSize: Int = 5

    // MARK: - Private Properties
    private let motionManager = CMMotionManager()
    private let queue = OperationQueue()

    // MARK: - Data Processing Properties
    // Moving Average Window
    private var accelXWindow: [Double] = []
    private var accelYWindow: [Double] = []
    private var accelZWindow: [Double] = []

    // Low-pass filter (alpha = 0.1 means heavy filtering)
    private let lowPassAlpha: Double = 0.1

    // Shake detection
    private let shakeThreshold: Double = 2.5
    private var lastShakeTime: Date = Date.distantPast
    
    // MARK: - Initialization
    init() {
        setupMotionManager()
    }

    // MARK: - Setup
    private func setupMotionManager() {
        motionManager.deviceMotionUpdateInterval = 0.1 // 10 Hz
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .userInteractive
    }

    // MARK: - Data Processing Methods

    /// Low-pass filter: smooths out high-frequency noise
    /// Formula: filtered = alpha * raw + (1 - alpha) * previousFiltered
    /// Lower alpha = more smoothing, higher alpha = more responsive
    private func applyLowPassFilter(raw: Double, previousFiltered: Double) -> Double {
        return lowPassAlpha * raw + (1 - lowPassAlpha) * previousFiltered
    }

    /// Moving average: averages last N samples from window
    /// Reduces noise by averaging multiple readings
    private func calculateMovingAverage(window: [Double]) -> Double {
        guard !window.isEmpty else { return 0.0 }
        return window.reduce(0, +) / Double(window.count)
    }

    /// Add value to window and maintain window size
    private func addToWindow(_ value: Double, window: inout [Double]) {
        window.append(value)
        if window.count > windowSize {
            window.removeFirst()
        }
    }

    /// Calculate magnitude (total acceleration vector length)
    /// Formula: magnitude = √(x² + y² + z²)
    private func calculateMagnitude(x: Double, y: Double, z: Double) -> Double {
        return sqrt(x * x + y * y + z * z)
    }

    /// Detect shake based on magnitude threshold
    /// Prevents duplicate detection within 0.5 seconds
    private func detectShake(magnitude: Double) {
        let now = Date()
        let timeSinceLastShake = now.timeIntervalSince(lastShakeTime)

        // Check if magnitude exceeds threshold and enough time has passed
        if magnitude > shakeThreshold && timeSinceLastShake > 0.5 {
            shakeCount += 1
            lastShakeTime = now
        }
    }

    /// Reset shake counter
    func resetShakeCount() {
        shakeCount = 0
    }

    /// Update window size for moving average
    func updateWindowSize(_ size: Int) {
        windowSize = max(1, min(size, 20)) // Limit between 1 and 20
    }
    
    // MARK: - Public Methods
    func startTracking() {
        guard motionManager.isDeviceMotionAvailable else {
            errorMessage = "Motion data not available"
            return
        }

        motionManager.startDeviceMotionUpdates(to: queue) { [weak self] motion, error in
            guard let self = self else { return }

            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                }
                return
            }

            guard let motion = motion else { return }

            // Extract raw acceleration values
            let rawX = motion.userAcceleration.x
            let rawY = motion.userAcceleration.y
            let rawZ = motion.userAcceleration.z

            // Calculate raw magnitude
            let rawMag = self.calculateMagnitude(x: rawX, y: rawY, z: rawZ)

            // Apply low-pass filter to smooth data
            let filtX = self.applyLowPassFilter(raw: rawX, previousFiltered: self.filteredAccelX)
            let filtY = self.applyLowPassFilter(raw: rawY, previousFiltered: self.filteredAccelY)
            let filtZ = self.applyLowPassFilter(raw: rawZ, previousFiltered: self.filteredAccelZ)

            // Calculate filtered magnitude
            let filtMag = self.calculateMagnitude(x: filtX, y: filtY, z: filtZ)

            // Add to moving average windows
            self.addToWindow(rawX, window: &self.accelXWindow)
            self.addToWindow(rawY, window: &self.accelYWindow)
            self.addToWindow(rawZ, window: &self.accelZWindow)

            // Calculate moving averages
            let avgX = self.calculateMovingAverage(window: self.accelXWindow)
            let avgY = self.calculateMovingAverage(window: self.accelYWindow)
            let avgZ = self.calculateMovingAverage(window: self.accelZWindow)

            // Detect shakes using filtered magnitude
            self.detectShake(magnitude: filtMag)

            DispatchQueue.main.async {
                // Update raw values
                self.accelerationX = rawX
                self.accelerationY = rawY
                self.accelerationZ = rawZ
                self.rotationX = motion.rotationRate.x
                self.rotationY = motion.rotationRate.y
                self.rotationZ = motion.rotationRate.z

                // Update filtered values
                self.filteredAccelX = filtX
                self.filteredAccelY = filtY
                self.filteredAccelZ = filtZ

                // Update moving averages
                self.avgAccelX = avgX
                self.avgAccelY = avgY
                self.avgAccelZ = avgZ

                // Update magnitudes
                self.magnitude = rawMag
                self.filteredMagnitude = filtMag

                self.isTracking = true
                self.errorMessage = nil
            }
        }
    }

    func stopTracking() {
        motionManager.stopDeviceMotionUpdates()
        isTracking = false

        // Clear windows when stopping
        accelXWindow.removeAll()
        accelYWindow.removeAll()
        accelZWindow.removeAll()
    }
    
    // MARK: - Cleanup
    deinit {
        stopTracking()
    }
}


