import Foundation
import Combine
import CoreMotion

class MotionViewModel: ObservableObject {
    //MARK: - Published Variables
    @Published var rawAcceleration: (Double, Double, Double) = (0.0, 0.0, 0.0)
    @Published var rawRotation: (Double, Double, Double) = (0.0, 0.0, 0.0)
    
    @Published var windowFilteredAcceleration: (Double, Double, Double) = (0.0, 0.0, 0.0)
    @Published var windowFilteredRotation: (Double, Double, Double) = (0.0, 0.0, 0.0)
    
    @Published var isTracking: Bool = false
    @Published var error: String? = nil
    
    private var windowSize: Int = 5
    private var accelWindow: [(Double, Double, Double)] = []
    private var rotationWindow: [(Double, Double, Double)] = []
    
    private let motionManager = CMMotionManager()
    private let queue = OperationQueue()
    
    init() {
        setUpMotionManager()
    }
    
    private func setUpMotionManager() {
        motionManager.deviceMotionUpdateInterval = 0.1 // 10 hz = 10 readings per second
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .userInteractive
    }
    
    // MARK: - Moving Windows Filter Funcs
    private func addToWindow(data: (Double, Double, Double), target: String) {
        var windows = target == "acc" ? self.accelWindow : self.rotationWindow
        windows.append(data)
        if (windows.count >= windowSize) {
            windows.removeFirst()
        }
    }
    
    private func calculateMovingWindowAvg(target: String) -> (Double, Double, Double) {
        var window = target == "acc" ? self.accelWindow : self.rotationWindow
        
        guard !window.isEmpty else { return (0.0, 0.0, 0.0) }
        
        var xAvg = 0.0
        var yAvg = 0.0
        var zAvg = 0.0
        for data in window {
            xAvg = (xAvg + data.0)
            yAvg = (yAvg + data.1)
            zAvg = (zAvg + data.2)
        }
        
        return (xAvg / Double(window.count), yAvg / Double(window.count), zAvg / Double(window.count))
    }
    
    
    
    // MARK: - Motion Tracking Funcs
    
    func startTrackingWithAccelerometerUpdates() {
        guard motionManager.isDeviceMotionAvailable else {
            error = "Motion Data is Not Available"
            return
        }
    }
    
    func startTrackingWithDeviceMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else {
            error = "Motion Data is Not Available"
            return
        }
        
        motionManager.startDeviceMotionUpdates(to: queue) { [weak self] motion, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.error = error.localizedDescription
                }
                
                return
            }
            
            guard let motion = motion else { return }
            
            DispatchQueue.main.async {
                let rawAcc = (
                    motion.userAcceleration.x,
                    motion.userAcceleration.y,
                    motion.userAcceleration.z
                )
                let rawRotation = (
                    motion.rotationRate.x,
                    motion.rotationRate.y,
                    motion.rotationRate.z
                )
                
                self.addToWindow(data: rawAcc, target: "acc")
                self.addToWindow(data: rawRotation, target: "rotation")
                
                self.rawAcceleration = rawAcc
                self.rawRotation = rawRotation
                
                self.windowFilteredAcceleration = self.calculateMovingWindowAvg(target: "acc")
                self.windowFilteredRotation = self.calculateMovingWindowAvg(target: "rotation")
            }
        }
    }
}
