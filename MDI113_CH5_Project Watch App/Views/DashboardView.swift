import SwiftUI

struct DashboardView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    // Motion Card
                    NavigationLink(destination: MotionView()) {
                        DashboardCard(
                            icon: "figure.walk.motion",
                            title: "Motion",
                            subtitle: "Track Movement",
                            gradientColors: [.blue, .cyan]
                        )
                    }

                    // Simulated Data Card
                    NavigationLink(destination: SimulatedMotionView()) {
                        DashboardCard(
                            icon: "waveform.path.ecg",
                            title: "Simulated Filter",
                            subtitle: "Raw vs Smoothed",
                            gradientColors: [.purple, .pink]
                        )
                    }
                }
            }
        }
    }
}

#Preview {
    DashboardView()
}
