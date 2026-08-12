import SwiftUI

struct CaptureView: View {
    @State private var model: CaptureViewModel

    init(model: CaptureViewModel = CaptureViewModel()) {
        _model = State(initialValue: model)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if model.phase == .accessDenied {
                accessDenied
            } else {
                viewfinder

                VStack(spacing: 12) {
                    statusBadge
                    Spacer()
                    if let result = model.result {
                        GradeResultCard(result: result)
                    }
                    actions
                }
                .padding()
            }
        }
        .navigationTitle("Capture")
        .navigationBarTitleDisplayMode(.inline)
        .task { await model.startCamera() }
        .onDisappear { model.stopCamera() }
    }

    /// Preview dan overlay berbagi satu kontainer dengan rasio frame kamera.
    /// Selama keduanya di kotak yang sama, bounding box ternormalisasi jatuh
    /// tepat di atas piksel yang menghasilkannya — tidak ada lagi koreksi
    /// crop `resizeAspectFill` yang harus ditebak.
    private var viewfinder: some View {
        ZStack {
            CameraPreviewView(session: model.camera.session)
            DetectionOverlay(detections: model.detections)
        }
        .aspectRatio(model.camera.capabilities.uprightAspectRatio, contentMode: .fit)
    }

    private var statusBadge: some View {
        VStack(spacing: 4) {
            Text(statusText)
                .font(.subheadline.weight(.medium))

            if let detail = detailText {
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let errorMessage = model.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .multilineTextAlignment(.center)
            }

            if !zoomWarning.isEmpty {
                Text(zoomWarning)
                    .font(.caption2)
                    .foregroundStyle(.yellow)
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.black.opacity(0.55), in: .capsule)
    }

    private var actions: some View {
        HStack(spacing: 12) {
            if model.phase == .finished {
                Button("Reset") { model.reset() }
                    .buttonStyle(.bordered)
                    .tint(.white)
            }

            Button {
                Task { await model.analyze() }
            } label: {
                Label("Analisis", systemImage: "viewfinder")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(model.phase == .analyzing || model.phase == .starting)
        }
        .controlSize(.large)
    }

    private var accessDenied: some View {
        ContentUnavailableView(
            "Izin kamera ditolak",
            systemImage: "camera.fill",
            description: Text("Aktifkan akses kamera di Pengaturan untuk menjalankan deteksi.")
        )
    }

    private var statusText: String {
        switch model.phase {
        case .starting:
            return "Menyiapkan kamera…"
        case .accessDenied:
            return "Izin kamera ditolak"
        case .ready:
            return "Siap — tekan Analisis"
        case .analyzing:
            return "Classifying…"
        case .finished:
            return model.detections.isEmpty ? "Tidak ada bintik terdeteksi" : "Selesai"
        }
    }

    /// Jumlah deteksi yang dibuang filter mask. Ditampilkan supaya kalau ada
    /// kabel atau dudukan yang tertangkap detektor, itu terlihat sebagai angka
    /// dan bukan diam-diam masuk ke persentase bintik.
    private var detailText: String? {
        guard model.phase == .finished, model.rejectedDetections > 0 else { return nil }
        return "\(model.rejectedDetections) deteksi di luar buah dibuang"
    }

    private var zoomWarning: String {
        let capabilities = model.camera.capabilities
        guard capabilities.requestedDisplayZoom < 1, !capabilities.isUltraWideActive,
              model.phase != .starting else { return "" }
        return "0.5x tidak tersedia — perangkat ini tanpa lensa ultra-wide"
    }
}

#Preview {
    NavigationStack {
        CaptureView()
    }
}
