# MangGO — iOS App

SwiftUI app for the Harum Manis mango grading box.

One target, two roles. The iPhone sits inside the box and runs the camera and on-device CV. The iPad is the display. `ContentView` picks the right view from `userInterfaceIdiom`.

**Current phase:** iPhone CV pipeline. BLE, iPad connectivity, and Firebase are not built yet.

## Structure

```
MangGO/MangGO/
├── App/                 Entry point, idiom router
├── Core/                Logic only — no feature views
│   ├── Models/          Value types: MangoSample, Grade, GradeResult, …
│   ├── Grading/         Rules engine and thresholds
│   ├── Vision/          Defect detection and fruit segmentation
│   └── Capture/         AVFoundation camera
├── Features/
│   ├── iPhone/          Capture UI
│   └── iPad/            Placeholder
└── Assets.xcassets/
```

**Dependency rule:** `Features → Core`, one way. `Core` never imports `Features`. This is what makes moving the UI to iPad cheap later — the iPad gets new views over the same `Core`.

`CameraPreviewView` is the one view inside `Core`. It is a `UIViewRepresentable` bridge to AVFoundation, not feature UI.

## Grading

`GradingEngine` runs a list of independent criteria. Each returns one `Grade`; the final grade is the worst of them. Criteria with missing data are skipped, so partial grading works while measurements are still coming in.

Thresholds live in `GradingStandard.harumManis` as data, not `if` statements. Bands are checked best-grade-first, so a value on a boundary lands in the better grade, and anything outside every band becomes `rejected`.

Adding an indicator means adding one `MetricCriterion` entry — no changes to the engine.

| Indicator | A | B | C | Source |
|---|---|---|---|---|
| Spots (% of surface) | 0–5 | 5–15 | 15–30 | Core ML + segmentation |
| Blush (%) | 15–40 | 5–15 | 0.5–5 | Color analysis |
| Hue | 15–33 | 33–43 | 43–55 | Color analysis |
| Saturation | 76–255 | 64–76 | — | Color analysis |
| Brightness | 178–255 | 128–178 | 64–128 | Color analysis |
| Mass (g) | >400 | 351–400 | <351 | Load cell over BLE |
| Volume (cm³) | 350–550 | 280–350 | 200–280 | Camera + ToF |

HSV uses the OpenCV convention: H 0–179, S and V 0–255.

Spot coverage is measured against the fruit silhouette, not the frame, so `FruitSegmenting` must be real before the number means anything.

### Open questions

The source table has gaps. Current interpretation:

- Hue Grade A was written `33 ≤ H ≤ 33`; read as `15 ≤ H ≤ 33`
- Hue 55–58 → `rejected`
- Saturation 64–76 → `B`
- Blush > 40% → `rejected`
- "Not standardized in shape and size" is not implemented

## CV model

[mangotest/mango-defect-detectionv4](https://universe.roboflow.com/mangotest/mango-defect-detectionv4), CC BY 4.0. One class (`defect`), mAP@50 38.2%, 401 images. Good enough to validate the pipeline, not to calibrate thresholds.

The current Roboflow 3.0 architecture is hosted-only. Retrain the dataset as YOLOv11n or RF-DETR-nano, export to `.mlpackage`, and drop it in `Core/Vision/Resources/`.

Blush is not an output of this model. It needs a separate color path.

## Development

Everything runs without a camera or a model. `MockDefectDetector` and `MockFruitSegmenter` are the defaults, so every screen works in Xcode Previews and the Simulator.

- Xcode 26+, iOS 26.5 deployment target
- Camera permission is a build setting (`INFOPLIST_KEY_NSCameraUsageDescription`), not an Info.plist file
- Synchronized folder groups: new folders in Finder are picked up automatically
- Real camera testing needs a physical device

## Not built yet

Core ML model · real fruit segmentation · color analysis · BLE (mass, height) · pixel-to-mm calibration · iPad connectivity · Firebase sync · test target