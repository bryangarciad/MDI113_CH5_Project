import Foundation
import AVFoundation
import Combine
import SwiftUI

class AudioRecorderViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var isRecording: Bool = false
    @Published var recordingTime: TimeInterval = 0
    @Published var recordings: [Recording] = []
    @Published var errorMessage: String?
    @Published var permissionGranted: Bool = false
    
    // MARK: - Private Properties
    private var audioRecorder: AVAudioRecorder?
    private var recordingTimer: Timer?
    private var recordingStartTime: Date?
    
    // MARK: - Initialization
    init() {
        checkPermission()
        loadRecordings()
    }
    
    // MARK: - Permission
    func checkPermission() {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            permissionGranted = true
        case .denied:
            permissionGranted = false
            errorMessage = "Microphone access denied"
        case .undetermined:
            requestPermission()
        @unknown default:
            permissionGranted = false
        }
    }
    
    func requestPermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                self?.permissionGranted = granted
                if !granted {
                    self?.errorMessage = "Microphone permission required"
                }
            }
        }
    }
    
    // MARK: - Recording Methods
    func startRecording() {
        guard permissionGranted else {
            errorMessage = "Microphone permission required"
            return
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
            
            let fileName = "recording_\(Date().timeIntervalSince1970).m4a"
            let fileURL = getDocumentsDirectory().appendingPathComponent(fileName)
            
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder?.record()
            
            isRecording = true
            recordingStartTime = Date()
            startTimer()
            errorMessage = nil
        } catch {
            errorMessage = "Failed to start recording: \(error.localizedDescription)"
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        stopTimer()
        
        if let startTime = recordingStartTime, let url = audioRecorder?.url {
            let duration = Date().timeIntervalSince(startTime)
            let recording = Recording(url: url, duration: duration, date: Date())
            recordings.insert(recording, at: 0)
            saveRecordings()
        }
        
        recordingTime = 0
        recordingStartTime = nil
    }
    
    func deleteRecording(at offsets: IndexSet) {
        for index in offsets {
            let recording = recordings[index]
            try? FileManager.default.removeItem(at: recording.url)
        }
        recordings.remove(atOffsets: offsets)
        saveRecordings()
    }
    
    // MARK: - Timer
    private func startTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.recordingStartTime else { return }
            self.recordingTime = Date().timeIntervalSince(startTime)
        }
    }
    
    private func stopTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
    
    // MARK: - Persistence
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private func saveRecordings() {
        let recordingData = recordings.map { ["url": $0.url.path, "duration": $0.duration, "date": $0.date.timeIntervalSince1970] }
        UserDefaults.standard.set(recordingData, forKey: "recordings")
    }
    
    private func loadRecordings() {
        guard let recordingData = UserDefaults.standard.array(forKey: "recordings") as? [[String: Any]] else { return }
        
        recordings = recordingData.compactMap { data in
            guard let urlPath = data["url"] as? String,
                  let duration = data["duration"] as? TimeInterval,
                  let dateInterval = data["date"] as? TimeInterval else { return nil }
            
            let url = URL(fileURLWithPath: urlPath)
            let date = Date(timeIntervalSince1970: dateInterval)
            return Recording(url: url, duration: duration, date: date)
        }
    }
}

// MARK: - Recording Model
struct Recording: Identifiable {
    let id = UUID()
    let url: URL
    let duration: TimeInterval
    let date: Date
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}


