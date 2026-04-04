import SwiftUI

struct MotionView: View {
    @StateObject private var viewModel = MotionViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Status Section
                VStack(spacing: 8) {
                    Image(systemName: viewModel.isTracking ? "figure.walk.motion" : "figure.stand")
                        .font(.system(size: 40))
                        .foregroundColor(viewModel.isTracking ? .green : .gray)
                        .symbolEffect(.pulse, isActive: viewModel.isTracking)

                    Text(viewModel.isTracking ? "Tracking" : "Not Tracking")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)

                // Shake Counter
                if !viewModel.isTracking {
                    VStack(spacing: 4) {
                        HStack {
                            Image(systemName: "arrow.triangle.swap")
                                .foregroundColor(.orange)
                            Text("Shakes: \(viewModel.shakeCount)")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.orange)
                            Button(action: { viewModel.resetShakeCount() }) {
                                Image(systemName: "arrow.counterclockwise.circle.fill")
                                    .font(.system(size: 14))
                            }
                            .buttonStyle(.plain)
                        }

                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Raw")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text(String(format: "%.2f", viewModel.magnitude))
                                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Filtered")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text(String(format: "%.2f", viewModel.filteredMagnitude))
                                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                                    .foregroundColor(.green)
                            }
                        }
                        .font(.caption)
                    }
                    .padding(8)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }

                // Filter Toggle
                if viewModel.isTracking {
                    Toggle(isOn: $viewModel.showFiltered) {
                        HStack {
                            Image(systemName: "waveform.path")
                                .foregroundColor(.purple)
                            Text("Show Filtered")
                                .font(.caption)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Acceleration Section
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(viewModel.showFiltered ? "Filtered Accel" : "Raw Acceleration")
                            .font(.headline)
                            .foregroundColor(.blue)

                        if viewModel.showFiltered {
                            Image(systemName: "sparkles")
                                .font(.caption)
                                .foregroundColor(.purple)
                        }
                    }

                    if viewModel.showFiltered {
                        // Show filtered data
                        MotionDataRow(label: "X", value: viewModel.filteredAccelX, color: .red)
                        MotionDataRow(label: "Y", value: viewModel.filteredAccelY, color: .green)
                        MotionDataRow(label: "Z", value: viewModel.filteredAccelZ, color: .blue)

                        Text("Low-pass Filter (α=0.1)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        // Show raw data
                        MotionDataRow(label: "X", value: viewModel.accelerationX, color: .red)
                        MotionDataRow(label: "Y", value: viewModel.accelerationY, color: .green)
                        MotionDataRow(label: "Z", value: viewModel.accelerationZ, color: .blue)
                    }
                }
                .padding(.horizontal)

                // Moving Average Section (if tracking)
                if viewModel.isTracking {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Moving Average")
                                .font(.headline)
                                .foregroundColor(.cyan)

                            Spacer()

                            Text("n=\(viewModel.windowSize)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        MotionDataRow(label: "X", value: viewModel.avgAccelX, color: .red)
                        MotionDataRow(label: "Y", value: viewModel.avgAccelY, color: .green)
                        MotionDataRow(label: "Z", value: viewModel.avgAccelZ, color: .blue)

                        Text("Average of last \(viewModel.windowSize) samples")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                    .padding(.horizontal)
                }

                Divider()
                
                // Rotation Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Rotation Rate")
                        .font(.headline)
                        .foregroundColor(.purple)
                    
                    MotionDataRow(label: "X", value: viewModel.rotationX, color: .orange)
                    MotionDataRow(label: "Y", value: viewModel.rotationY, color: .pink)
                    MotionDataRow(label: "Z", value: viewModel.rotationZ, color: .cyan)
                }
                .padding(.horizontal)
                
                // Error Message
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption2)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Control Button
                Button(action: {
                    if viewModel.isTracking {
                        viewModel.stopTracking()
                    } else {
                        viewModel.startTracking()
                    }
                }) {
                    Label(
                        viewModel.isTracking ? "Stop" : "Start",
                        systemImage: viewModel.isTracking ? "stop.fill" : "play.fill"
                    )
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .tint(viewModel.isTracking ? .red : .green)
                .padding(.horizontal)

                // Data Processing Info
                if viewModel.isTracking {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Learning Points")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.purple)

                        InfoRow(
                            title: "Low-Pass Filter",
                            description: "Removes noise, smooths signal"
                        )

                        InfoRow(
                            title: "Moving Average",
                            description: "Averages last N readings"
                        )

                        InfoRow(
                            title: "Shake Detection",
                            description: "Threshold: 2.5g, cooldown: 0.5s"
                        )
                    }
                    .padding(8)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, 8)
        }
        .navigationTitle("Motion")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct InfoRow: View {
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 4) {
            Text("•")
                .foregroundColor(.purple)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct MotionDataRow: View {
    let label: String
    let value: Double
    let color: Color
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(color)
                .frame(width: 20)
            
            // Visual bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                    
                    // Value bar
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: abs(value) * geometry.size.width / 2)
                        .offset(x: value < 0 ? geometry.size.width / 2 - abs(value) * geometry.size.width / 2 : geometry.size.width / 2)
                    
                    // Center line
                    Rectangle()
                        .fill(Color.white.opacity(0.5))
                        .frame(width: 1)
                        .offset(x: geometry.size.width / 2)
                }
            }
            .frame(height: 20)
            
            // Numeric value
            Text(String(format: "%.2f", value))
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 50, alignment: .trailing)
        }
    }
}

#Preview {
    NavigationStack {
        MotionView()
    }
}


