import Foundation
import HealthKit
import Combine


enum HeartRateAuthStatus: String, CaseIterable {
    case NotDetermined = "Not Determined"
}

class HeartRateViewModel: ObservableObject {
    // MARK: - Published Variables
    @Published var currentHeartRate: Int = 0
    @Published var isMonitoring: Bool = false
    @Published var errorMessage: String? = nil
    @Published var authorizationStatus: String = "Not Determined"
    
    // MARK: - Private Props
    private let healthStore = HKHealthStore()
    private var hearthRateQuery: HKQuery? = nil
    private let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!

    
    init() {
        checkAuthorizationStatus()
    }
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - Authorization
    private func checkAuthorizationStatus() {
        guard HKHealthStore.isHealthDataAvailable() else {
            errorMessage = "HealthKit Is Not Available"
            return
        }
        
        let status = healthStore.authorizationStatus(for: heartRateType)
        
        switch status {
        case .notDetermined:
            authorizationStatus = "Not Determined"
        case .sharingDenied:
            authorizationStatus = "Denied"
            errorMessage = "Please Enable Heart Rate Access In Settings"
        case .sharingAuthorized:
            authorizationStatus = "Authorized"
        @unknown default:
            authorizationStatus = "Not Determined"
        }
    }
    
    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            errorMessage = "HealthKit Is Not Available"
            return
        }
        
        healthStore.requestAuthorization(toShare: [], read: [heartRateType]) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    self?.authorizationStatus = "Authorized"
                    self?.errorMessage = nil
                } else {
                    self?.errorMessage = error?.localizedDescription ?? "Authorization Failed"
                }
            }
            
        }
    }
    
    // MARK: - Public Methods
    
    func startMonitoring() {
        guard HKHealthStore.isHealthDataAvailable() else {
            errorMessage = "HealthKit Is Not Available"
            return
        }
        
        let query = HKAnchoredObjectQuery(
            type: heartRateType,
            predicate: nil,
            anchor: nil,
            limit: 1
        ) { [weak self] _, samples, _, _, error in
            self?.processSamples(samples: samples, error: error)
        }
        
        query.updateHandler = { [weak self] _, samples, _, _, error in
            self?.processSamples(samples: samples, error: error)
        }
        
        hearthRateQuery = query
        healthStore.execute(query)
        isMonitoring = true
    }
    
    private func processSamples(samples: [HKSample]?, error: Error?) {
        guard let samples = samples as? [HKQuantitySample],
              let sample = samples.last else
        {
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                }
            }
            return
        }
        
        let hearthRateUnit = HKUnit.count().unitDivided(by: .minute()) // BPM
        let heartRate = sample.quantity.doubleValue(for: hearthRateUnit)
        
        DispatchQueue.main.async {
            self.currentHeartRate = Int(heartRate)
            self.errorMessage =  nil
        }
        
    }
    
    func stopMonitoring() {
        if let query = hearthRateQuery {
            healthStore.stop(query)
            hearthRateQuery = nil
        }
        
        isMonitoring = false
    }
}
