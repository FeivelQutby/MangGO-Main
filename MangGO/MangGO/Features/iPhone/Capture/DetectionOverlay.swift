import SwiftUI

struct DetectionOverlay: View {
    let detections: [DefectObservation]

    var body: some View {
        GeometryReader { geometry in
            ForEach(detections) { detection in
                let box = rect(for: detection, in: geometry.size)

                ZStack(alignment: .topLeading) {
                    Rectangle()
                        .stroke(.red, lineWidth: 2)

                    Text(verbatim: "\(Int(detection.confidence * 100))%")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(.red, in: .rect(cornerRadius: 4))
                        .fixedSize()
                        .offset(y: -18)
                }
                .frame(width: box.width, height: box.height)
                .offset(x: box.minX, y: box.minY)
            }
        }
        .allowsHitTesting(false)
    }

    /// Vision memakai origin kiri-bawah, SwiftUI kiri-atas, jadi sumbu Y dibalik.
    private func rect(for detection: DefectObservation, in size: CGSize) -> CGRect {
        let box = detection.boundingBox
        return CGRect(
            x: box.minX * size.width,
            y: (1 - box.maxY) * size.height,
            width: box.width * size.width,
            height: box.height * size.height
        )
    }
}

#Preview {
    ZStack {
        Color.gray
        DetectionOverlay(detections: .moderate)
    }
    .frame(width: 320, height: 480)
}
