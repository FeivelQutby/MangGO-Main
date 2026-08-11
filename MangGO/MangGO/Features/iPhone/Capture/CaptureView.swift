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
                CameraPreviewView(session: model.camera.session)
                    .ignoresSafeArea()

                DetectionOverlay(detections: model.detections)
                    .ignoresSafeArea()

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

    private var statusBadge: some View {
        VStack(spacing: 4) {
            Text(statusText)
                .font(.subheadline.weight(.medium))

            if let errorMessage = model.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .multilineTextAlignment(.center)
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
}

#Preview {
    NavigationStack {
        CaptureView()
    }
}
