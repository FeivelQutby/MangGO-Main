import SwiftUI

struct IdleScreenView: View {
    let snapshot: StationSnapshot
    @State private var selectedTab: Int = 0
    @State private var showErrorPopup: Bool = false // State untuk mengontrol pop-up error
    
    // Contoh data status sensor
    private let sensorStates: [SensorState] = [.connected, .connected, .failed, .waiting]
    
    var body: some View {
        ZStack {
            // Background Color
            Color(red: 247/255, green: 247/255, blue: 248/255)
                .ignoresSafeArea()
            
            VStack(spacing: 125) {
                // Top Segmented Bar / Navigation Bar
                topTabBar
                    .padding(.top, 20)
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 64) {
                        // Section 1: Status Sensor
                        sensorStatusSection
                        
                        // Section 2: Mulai Grading Mangga
                        gradingStepsSection
                    }
                    .padding(.bottom, 40)
                }
            }
            .padding(.horizontal, 40)
            
            // Overlap Background Dimming & Pop-up Error
            if showErrorPopup {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        withAnimation {
                            showErrorPopup = false
                        }
                    }
                
                SensorErrorPopupView(
                    imageName: "mango error", // Ganti dengan nama aset gambar Anda
                    onDismiss: {
                        withAnimation {
                            showErrorPopup = false
                        }
                    },
                    onCall: {
                        showErrorPopup = false
                        // Aksi panggil teknisi
                        if let url = URL(string: "tel://081234567890") {
                            UIApplication.shared.open(url)
                        }
                    }
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
        .onAppear {
            // Cek otomatis jika ada sensor yang gagal
            if sensorStates.contains(.failed) {
                showErrorPopup = true
            }
        }
    }
    
    // MARK: - Sensor Status Section
    private var sensorStatusSection: some View {
        VStack(spacing: 24) {
            Text("Status Sensor")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.black)
            
            HStack(spacing: 20) {
                SensorCardView(
                    icon: "scalemass",
                    title: "Load Cell",
                    status: "Terhubung",
                    state: sensorStates[0]
                )

                SensorCardView(
                    icon: "gear",
                    title: "Servo",
                    status: "Terhubung",
                    state: sensorStates[1]
                )

                SensorCardView(
                    icon: "camera",
                    title: "Kamera",
                    status: sensorStatus(sensors.camera),
                    state: sensorState(sensors.camera)
                )

                SensorCardView(
                    icon: "sensor.tag.radiowaves.forward",
                    title: "Bluetooth",
                    status: "Menunggu...",
                    state: sensorStates[3]
                )
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(24)
            .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 6)
        }
        .frame(maxWidth: 906)
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

// MARK: - Error Pop-up Component
struct SensorErrorPopupView: View {
    let imageName: String
    var onDismiss: () -> Void
    var onCall: () -> Void
    
    var body: some View {
        VStack(spacing: 28) {
            // Area Ilustrasi / Gambar
            ZStack {
                Color(red: 250/255, green: 250/255, blue: 250/255)
                
                Image("mango error")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 180)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 220)
            .cornerRadius(20)
            
            // Pesan Teks
            Text("Jika sensor gagal terhubung dalam 2 menit, silakan hubungi teknisi")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 16)
            
            // Tombol CTA
            HStack(spacing: 16) {
                // Tombol Nanti
                Button(action: onDismiss) {
                    Text("Nanti")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(red: 238/255, green: 238/255, blue: 238/255))
                        .cornerRadius(30)
                }
                
                // Tombol Telepon
                Button(action: onCall) {
                    HStack(spacing: 8) {
                        Image(systemName: "phone.fill")
                            .font(.system(size: 18, weight: .medium))
                        Text("Telepon")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(red: 0/255, green: 122/255, blue: 255/255))
                    .cornerRadius(30)
                }
            }
        }
        .padding(28)
        .frame(width: 460)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.15), radius: 25, x: 0, y: 10)
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
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(.black)
                
                Spacer()
                
                Image(systemName: state.badgeIcon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(state.statusColor)
            }
            
            Text(status)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(state.statusColor)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(state.backgroundColor)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(state.borderColor, lineWidth: 1.5)
        )
        .cornerRadius(16)
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
            .cornerRadius(22)
            .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
            
            Text(description)
                .font(.system(size: 20, weight: .regular))
                .foregroundColor(Color.black.opacity(0.8))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
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
