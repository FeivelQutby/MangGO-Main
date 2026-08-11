import SwiftUI

struct iPhoneView: View {

    @Environment(StationSync.self) private var sync

    /// Dibuat sekali di sini, bukan di dalam `NavigationLink`, supaya
    /// `CameraSession` tidak dialokasi ulang tiap kali body dievaluasi.
    @State private var model = CaptureViewModel(detector: DefectDetectorFactory.make())

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("MangGO")
                    .font(.largeTitle.bold())

                VStack(alignment: .leading, spacing: 8) {
                    Label("ESP32 — belum tersambung", systemImage: "dot.radiowaves.left.and.right")
                        .foregroundStyle(.secondary)

                    Label(linkLabel, systemImage: sync.isLinked ? "ipad" : "ipad.slash")
                        .foregroundStyle(sync.isLinked ? .green : .orange)

                    if !DefectDetectorFactory.hasBundledModel {
                        Label("Model Core ML belum ada — memakai detektor mock",
                              systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                    }

                    if let error = sync.lastError {
                        Label(error, systemImage: "wifi.exclamationmark")
                            .foregroundStyle(.red)
                    }
                }
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                NavigationLink {
                    CaptureView(model: model)
                } label: {
                    Label("Mulai Capture", systemImage: "camera.viewfinder")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                #if DEBUG
                NavigationLink {
                    SimulatorPanel()
                        .navigationTitle("Simulator")
                } label: {
                    Label("Simulator Grading", systemImage: "slider.horizontal.3")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                #endif
            }
            .padding()
        }
        .onAppear { model.attach(to: sync) }
    }

    private var linkLabel: String {
        sync.isLinked ? "iPad tersambung (\(sync.peerCount))" : "Mencari iPad…"
    }
}

#Preview {
    iPhoneView()
        .environment(StationSync(role: .station))
}
