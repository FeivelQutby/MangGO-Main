import SwiftUI

struct iPhoneView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("MangGO")
                    .font(.largeTitle.bold())

                VStack(alignment: .leading, spacing: 8) {
                    Label("ESP32", systemImage: "dot.radiowaves.left.and.right")
                    Label("iPad", systemImage: "ipad")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                Spacer()

                NavigationLink {
                    CaptureView()
                } label: {
                    Label("Mulai Capture", systemImage: "camera.viewfinder")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding()
        }
    }
}

#Preview {
    iPhoneView()
}
