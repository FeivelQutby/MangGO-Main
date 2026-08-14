import SwiftUI

struct IdleScreenView: View {
    let snapshot: StationSnapshot
    @State private var selectedTab: Int = 0
    @Environment(StationSync.self) private var sync
    private var sensors: StationSnapshot.Sensors {
        sync.snapshot.sensors
    }
    
    var body: some View {
        ZStack {
            // Background Color
            Color(red: 247/255, green: 247/255, blue: 248/255)
                .ignoresSafeArea()
            
            VStack(spacing: 36) {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 40) {
                        // Section 1: Status Sensor
                        sensorStatusSection
                        
                        // Section 2: Mulai Grading Mangga
                        gradingStepsSection
                    }
                    .padding(.bottom, 40)
                }
            }
            .padding(.horizontal, 40)
        }
    }
    
    // MARK: - Sensor Status Section
    private var sensorStatusSection: some View {
        VStack(spacing: 20) {
            Text("Status Sensor")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.black)
            
            HStack(spacing: 16) {

                SensorCardView(
                    icon: "scale.3d",
                    title: "Load Cell",
                    status: sensorStatus(sensors.loadCell),
                    state: sensorState(sensors.loadCell)
                )

                SensorCardView(
                    icon: "gearshape",
                    title: "Servo",
                    status: sensorStatus(sensors.servo),
                    state: sensorState(sensors.servo)
                )

                SensorCardView(
                    icon: "camera",
                    title: "Kamera",
                    status: sensorStatus(sensors.camera),
                    state: sensorState(sensors.camera)
                )

                SensorCardView(
                    icon: "wave.3.right",
                    title: "Bluetooth",
                    status: sensorStatus(sensors.bluetooth),
                    state: sensorState(sensors.bluetooth)
                )
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(24)
            .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 6)
        }
        .frame(maxWidth: 800)
    }
    
    private func sensorState(
        _ state: StationSnapshot.Sensors.State
    ) -> SensorState {

        switch state {

        case .ready:
            return .connected

        case .waiting:
            return .waiting

        case .offline:
            return .failed
        }
    }
    
    private func sensorStatus(
        _ state: StationSnapshot.Sensors.State
    ) -> String {

        switch state {
        case .ready:
            return "Terhubung"

        case .waiting:
            return "Menunggu..."

        case .offline:
            return "Gagal Terhubung"
        }
    }
    
    // MARK: - Grading Steps Section
    private var gradingStepsSection: some View {
        VStack(spacing: 24) {
            Text("Mulai Grading Mangga")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.black)
            
            HStack(spacing: 24) {
                StepCardView(
                    imageName: "step_place",
                    description: "Letakkan mangga yang sudah dikeringkan di atas alat"
                )
                
                StepCardView(
                    imageName: "step_press",
                    description: "Tekan tombol untuk mulai grading setiap mangga"
                )
                
                StepCardView(
                    imageName: "step_result",
                    description: "Tunggu dan lihat\nhasil grading"
                )
            }
        }
        .frame(maxWidth: 900)
    }
}

// MARK: - Sensor Card Component
enum SensorState {
    case connected, failed, waiting
    
    var backgroundColor: Color {
        switch self {
        case .connected: return Color(red: 236/255, green: 248/255, blue: 241/255)
        case .failed: return Color(red: 253/255, green: 238/255, blue: 240/255)
        case .waiting: return Color(red: 254/255, green: 248/255, blue: 235/255)
        }
    }
    
    var borderColor: Color {
        switch self {
        case .connected: return Color(red: 163/255, green: 228/255, blue: 189/255)
        case .failed: return Color(red: 242/255, green: 175/255, blue: 182/255)
        case .waiting: return Color(red: 237/255, green: 218/255, blue: 168/255)
        }
    }
    
    var statusColor: Color {
        switch self {
        case .connected: return Color(red: 15/255, green: 110/255, blue: 45/255)
        case .failed: return Color(red: 168/255, green: 25/255, blue: 38/255)
        case .waiting: return Color(red: 138/255, green: 98/255, blue: 12/255)
        }
    }
    
    var badgeIcon: String {
        switch self {
        case .connected: return "checkmark.circle"
        case .failed: return "xmark.circle"
        case .waiting: return "arrow.clockwise"
        }
    }
    
    private func sensorState(
        _ state: StationSnapshot.Sensors.State
    ) -> SensorState {

        switch state {
        case .ready:
            return .connected

        case .waiting:
            return .waiting

        case .offline:
            return .failed
        }
    }
}

struct SensorCardView: View {
    let icon: String
    let title: String
    let status: String
    let state: SensorState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                    Text(title)
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundColor(.black)
                
                Spacer()
                
                Image(systemName: state.badgeIcon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(state.statusColor)
            }
            
            Text(status)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(state.statusColor)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(state.backgroundColor)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(state.borderColor, lineWidth: 1.5)
        )
        .cornerRadius(14)
    }
}

// MARK: - Step Card Component
struct StepCardView: View {
    let imageName: String
    let description: String
    
    var body: some View {
        VStack(spacing: 16) {
            VStack {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 140)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 200)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
            
            Text(description)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color.black.opacity(0.8))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Preview
#Preview(traits: .landscapeLeft) {
    IdleScreenView(
        snapshot: StationSnapshot(
            sensors: .allReady
        )
    )
    .environment(StationSync(role: .display))
}
