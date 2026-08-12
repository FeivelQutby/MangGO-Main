import SwiftUI

struct iPhoneView: View {

    @Environment(StationSync.self) private var sync

    @State private var ble = BLEManager()

    @State private var model =
        CaptureViewModel(
            detector: DefectDetectorFactory.make()
        )

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {

                Text("MangGO")
                    .font(.largeTitle.bold())

                VStack(alignment: .leading, spacing: 8) {

                    Label(
                        ble.isConnected
                            ? "ESP32 — tersambung"
                            : "ESP32 — belum tersambung",
                        systemImage:
                            ble.isConnected
                            ? "dot.radiowaves.left.and.right"
                            : "dot.radiowaves.right"
                    )
                    .foregroundStyle(
                        ble.isConnected
                        ? .green
                        : .secondary
                    )

                    Label(
                        linkLabel,
                        systemImage:
                            sync.isLinked
                            ? "ipad"
                            : "ipad.and.arrow.forward"
                    )
                    .foregroundStyle(
                        sync.isLinked
                        ? .green
                        : .orange
                    )

                    if !DefectDetectorFactory.hasBundledModel {
                        Label(
                            "Model Core ML belum ada — memakai detektor mock",
                            systemImage: "exclamationmark.triangle"
                        )
                        .foregroundStyle(.orange)
                    }

                    if let error = sync.lastError {
                        Label(
                            error,
                            systemImage: "wifi.exclamationmark"
                        )
                        .foregroundStyle(.red)
                    }
                }
                .font(.subheadline)
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )

                Spacer()

                NavigationLink {
                    CaptureView(model: model)
                } label: {
                    Label(
                        "Mulai Capture",
                        systemImage: "camera.viewfinder"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

            }
            .padding()
        }
        .onAppear {
            model.attach(to: sync)
            model.attachBLE(ble)
            ble.start()
        }
    }

    private var linkLabel: String {
        sync.isLinked
            ? "iPad tersambung (\(sync.peerCount))"
            : "Mencari iPad…"
    }
}


#Preview {
    iPhoneView()
        .environment(
            StationSync(role: .station)
        )
}
