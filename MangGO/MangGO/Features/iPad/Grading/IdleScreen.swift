import SwiftUI

struct IdleScreenView: View {
    @State private var selectedTab: Int = 0
    
    var body: some View {
        ZStack {
            // Background Color
            Color(red: 247/255, green: 247/255, blue: 248/255)
                .ignoresSafeArea()
            
            VStack(spacing: 36) {
                // Top Segmented Bar / Navigation Bar
                topTabBar
                    .padding(.top, 20)
                
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
    
    // MARK: - Top Tab Bar
    private var topTabBar: some View {
        HStack(spacing: 0) {
            tabButton(title: "Grading", index: 0)
            tabButton(title: "Data Harian", index: 1)
            tabButton(title: "Tren", index: 2)
        }
        .padding(4)
        .background(Color.white.opacity(0.8))
        .clipShape(Capsule())
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
        .frame(width: 500)
    }
    
    private func tabButton(title: String, index: Int) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = index
            }
        }) {
            Text(title)
                .font(.system(size: 15, weight: selectedTab == index ? .semibold : .medium))
                .foregroundColor(selectedTab == index ? .black : .gray)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    ZStack {
                        if selectedTab == index {
                            Capsule()
                                .fill(Color(red: 232/255, green: 234/255, blue: 238/255))
                                .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
                        }
                    }
                )
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
                    status: "Terhubung",
                    state: .connected
                )
                
                SensorCardView(
                    icon: "gearshape",
                    title: "Servo",
                    status: "Terhubung",
                    state: .connected
                )
                
                SensorCardView(
                    icon: "camera",
                    title: "Kamera",
                    status: "Gagal Terhubung",
                    state: .failed
                )
                
                SensorCardView(
                    icon: "wave.3.right",
                    title: "Bluetooth",
                    status: "Menunggu...",
                    state: .waiting
                )
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(24)
            .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 6)
        }
        .frame(maxWidth: 800)
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
    IdleScreenView()
}
