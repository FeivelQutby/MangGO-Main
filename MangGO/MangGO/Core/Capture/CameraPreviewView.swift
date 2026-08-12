import SwiftUI
import AVFoundation

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    /// `resizeAspect`, bukan `resizeAspectFill`. Dengan `Fill`, layar yang lebih
    /// tinggi dari 3:4 memotong tepi frame — sementara analisis tetap memakai
    /// frame utuh, jadi bounding box hasil deteksi tidak lagi sejajar dengan apa
    /// yang dilihat operator.
    var videoGravity: AVLayerVideoGravity = .resizeAspect

    /// 90° = portrait untuk kamera belakang, pasangan dari
    /// `CameraSession.bufferOrientation == .right` yang dipakai Vision.
    var rotationAngle: CGFloat = 90

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = session
        apply(to: view)
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        apply(to: uiView)
    }

    private func apply(to view: PreviewView) {
        view.previewLayer.videoGravity = videoGravity
        view.previewLayer.connection?.videoRotationAngle = rotationAngle
    }

    final class PreviewView: UIView {
        override static var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

        var previewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer
        }
    }
}
