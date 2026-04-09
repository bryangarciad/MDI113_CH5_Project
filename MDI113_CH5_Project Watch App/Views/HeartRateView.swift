import SwiftUI

struct HeartRateView: View {
    @StateObject private var viewModel = HeartRateViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Heart Rate Display
                VStack(spacing: 8) {
                    Image(systemName: "hearth.fill")
                        .font(.system(size: 40))
                        .foregroundColor(heartRateColor)
                        .symbolEffect(.pulse, value: viewModel.isMonitoring)
                    
                    if viewModel.isMonitoring {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(viewModel.currentHeartRate)")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundStyle(heartRateColor)
                            
                            Text("BPM")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                        .contentTransition(.numericText())
                    } else {
                        Text("--")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.gray)
                    }
                    
                    Text(viewModel.isMonitoring ? "Monitoring" : "Not Monitoring")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
                
                // Heart Rate Zone Indicator
                if viewModel.isMonitoring && viewModel.currentHeartRate > 0 {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            HStack(spacing: 0) {
                                Rectangle().fill(Color.blue.opacity(0.3))
                                Rectangle().fill(Color.green.opacity(0.3))
                                Rectangle().fill(Color.yellow.opacity(0.3))
                                Rectangle().fill(Color.orange.opacity(0.3))
                                Rectangle().fill(Color.red.opacity(0.3))
                            }
                            .cornerRadius(4)
                            
                            Circle()
                                .fill(Color.white)
                                .frame(width: 8, height: 8)
                                .overlay(Circle().stroke(Color.primary, lineWidth: 2))
                                .offset(x: calculateZonePosition(for: viewModel.currentHeartRate, in: geometry.size.width))
                        }
                    }
                    .frame(height: 8)
                }
                
                if viewModel.authorizationStatus != "Authorized" {
                    VStack(spacing: 8) {
                        Text("Status: \(viewModel.authorizationStatus)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button("Request Access") {
                            viewModel.requestAuthorization()
                        }
                        .buttonStyle(.bordered)
                        .tint(.blue)
                    }
                }
                
                Button(action: {
                    if viewModel.isMonitoring {
                        viewModel.stopMonitoring()
                    } else {
                        viewModel.startMonitoring()
                    }
                }) {
                    Label(
                        viewModel.isMonitoring ? "Stop" : "Start",
                        systemImage: viewModel.isMonitoring ? "stop.fill" : "play.fill"
                    )
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .tint(viewModel.isMonitoring ? .red : .pink)
                .padding(.horizontal)
                .disabled(viewModel.authorizationStatus != "Authorized")
            }
            .padding(.bottom, 8)
        }
        .navigationTitle("Heart Rate")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func calculateZonePosition(for bpm: Int, in width: CGFloat) -> CGFloat {
        let maxBPM: CGFloat = 200
        let postion = (CGFloat(bpm) / maxBPM) * width
        return min(max(postion - 4, 0), width - 8)
    }
    
    // MARK: - Computed View Props
    private var heartRateColor: Color {
        guard viewModel.currentHeartRate > 0 else { return .gray}
        
        switch viewModel.currentHeartRate {
        case 0..<60: return .blue
        case 60..<100: return .green
        case 100..<140: return .yellow
        case 140..<170: return .orange
        default: return .red
        }
        
    }
}
