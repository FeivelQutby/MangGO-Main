# MangGO — iOS App

Aplikasi SwiftUI untuk sistem grading mangga Harum Manis. Satu app target yang melayani dua peran:

- **iPhone** — diletakkan di dalam grading box. Menangkap gambar, menjalankan Computer Vision, membaca sensor lewat BLE.
- **iPad** — display utama untuk worker & manager. Menampilkan hasil grading dan analitik batch.

Pemilihan tampilan dilakukan otomatis di `ContentView` berdasarkan `UIDevice.current.userInterfaceIdiom`.

> **Fase saat ini:** prototype Computer Vision di iPhone. Fitur iPad, BLE, dan sinkronisasi Firebase masih berupa placeholder.

---

## Struktur Direktori

```
MangGO/MangGO/
├── App/                    # Entry point & state global
├── Core/                   # Semua logika — tanpa SwiftUI View
│   ├── Models/
│   ├── Capture/
│   ├── Vision/
│   └── Grading/
├── Features/               # Semua UI
│   ├── iPhone/
│   └── iPad/
└── Assets.xcassets/
```

---

## Aturan Dependensi

Ini aturan terpenting di project ini:

```
Features  ──►  Core  ──►  Foundation / Vision / AVFoundation
```

**Satu arah.** `Features` boleh mengimpor `Core`. `Core` **tidak pernah** mengimpor `Features`, dan tidak pernah mengimpor SwiftUI View apa pun.

Kenapa: karena UI final nanti pindah ke iPad. Kalau `Core` bersih dari View, memindahkan UI cukup dengan menulis View baru di atas `Core` yang sama persis — tidak ada logika yang perlu ditulis ulang. Kalau logika bocor ke dalam View, migrasi ke iPad berarti tulis ulang.

Cara cepat mengecek: kalau ada file di `Core/` yang punya baris `import SwiftUI` untuk mendefinisikan `View`, itu salah tempat. (`CameraPreviewView` adalah pengecualian sah — dia `UIViewRepresentable`, jembatan ke AVFoundation, bukan UI fitur.)

---

## Penjelasan Tiap Folder

### `App/`

Entry point aplikasi dan state yang dipakai lintas fitur.

| File | Fungsi |
|---|---|
| `MangGO_qApp.swift` | `@main`, mendefinisikan `WindowGroup` |
| `ContentView.swift` | Router: memilih `iPhoneView` atau `iPadView` berdasarkan device idiom |
| `AppState.swift` | `@Observable` root state — status koneksi, sesi batch yang sedang berjalan |

Folder ini sengaja tipis. Kalau isinya mulai membengkak, biasanya tanda ada logika yang seharusnya turun ke `Core/`.

### `Core/Models/`

Value type murni: `struct` dan `enum`, `Codable`, tanpa logika dan tanpa dependensi framework.

| File | Isi |
|---|---|
| `MangoSample.swift` | Satu buah mangga yang sedang/sudah diproses. Kumpulan semua hasil pengukuran |
| `DefectObservation.swift` | Satu bounding box hasil deteksi: posisi, ukuran, confidence |
| `Dimensions.swift` | Panjang, lebar (kamera) + tinggi (ToF). `volume` dihitung sebagai computed property |
| `Grade.swift` | `enum` — A, B, C, Reject |
| `GradeResult.swift` | Grade final + alasan/rincian kenapa dapat grade itu |

**Dua prinsip di folder ini:**

1. **Nilai turunan ditulis sebagai `computed property`, bukan disimpan.** `volume` diturunkan dari p×l×t; `defectAreaRatio` diturunkan dari bbox. Menyimpannya berarti suatu saat ada bug di mana sumbernya berubah tapi turunannya basi.

2. **`MangoSample` menyimpan fakta, `GradeResult` menyimpan interpretasi.** Keduanya terpisah. Kalau aturan grading berubah, grade semua data lama bisa dihitung ulang tanpa mengukur ulang buahnya.

Field pengukuran dibuat `Optional` karena grading berlangsung bertahap — saat scan sisi 1, `weight` memang belum ada. Optional membuat kondisi "belum terisi" terwakili jujur di tipe data, bukan disamarkan jadi `0`.

### `Core/Capture/`

Semua yang berurusan dengan `AVFoundation`. Tugasnya hanya menghasilkan frame — tidak tahu apa pun tentang mangga.

| File | Fungsi |
|---|---|
| `CameraSession.swift` | Wrapper `AVCaptureSession`: konfigurasi, izin, lifecycle, output frame |
| `CameraPreviewView.swift` | `UIViewRepresentable` yang membungkus `AVCaptureVideoPreviewLayer` |

### `Core/Vision/`

Mengubah frame gambar menjadi observasi. Ini rumah dari model Core ML.

| File | Fungsi |
|---|---|
| `DefectDetecting.swift` | **Protocol.** Kontrak: terima gambar, kembalikan `[DefectObservation]` |
| `CoreMLDefectDetector.swift` | Implementasi nyata via `VNCoreMLRequest` |
| `MockDefectDetector.swift` | Implementasi palsu yang mengembalikan data statis |
| `Resources/MangoDefect.mlpackage` | Model hasil export dari Roboflow |

**Kenapa ada protocol dan mock:** kamera tidak berfungsi di Simulator maupun Xcode Preview. Tanpa mock, setiap perubahan kecil di UI harus di-deploy ke iPhone fisik dulu untuk dilihat hasilnya. Mock membuat `CaptureView` bisa di-preview dengan data deteksi palsu. Ini bukan pertimbangan teoretis — akan terasa di hari pertama.

Bonus: kalau nanti model diganti (misalnya YOLOv11n → RF-DETR), yang berubah hanya satu file implementasi. UI tidak tersentuh.

Nanti folder ini juga akan diisi `ColorAnalyzer.swift` dan `SizeEstimator.swift`.

### `Core/Grading/`

*(Belum dibuat — lihat bagian Roadmap.)*

Menggabungkan semua sinyal menjadi satu keputusan.

| File | Fungsi |
|---|---|
| `GradingEngine.swift` | Fungsi murni: masuk `MangoSample`, keluar `GradeResult` |
| `GradingRules.swift` | Kumpulan angka threshold, terpisah dari logika pembandingnya |

Engine tidak tahu kamera, tidak tahu BLE, tidak tahu SwiftUI. Konsekuensinya bisa di-unit-test penuh tanpa hardware: bikin sample palsu di test, pastikan grade-nya benar. Ini penting karena aturan grading pasti berubah berkali-kali setelah diuji di pack house.

Threshold dipisah ke file sendiri supaya mengubah aturan = mengubah angka, bukan mengubah kode.

### `Features/iPhone/`

UI untuk perangkat di dalam box.

| Path | Fungsi |
|---|---|
| `iPhoneView.swift` | Layar utama: status koneksi, entry ke mode capture |
| `Capture/CaptureView.swift` | Live preview kamera + kontrol |
| `Capture/CaptureViewModel.swift` | `@Observable`. Mengorkestrasi capture → detect → update state |
| `Capture/DetectionOverlay.swift` | Menggambar bounding box di atas preview |

`CaptureViewModel` adalah satu-satunya tempat yang menyatukan `CameraSession` dan `DefectDetecting`. View di bawahnya hanya membaca state — tidak ada View yang memanggil detector langsung.

### `Features/iPad/`

UI untuk display utama. Masih placeholder.

| File | Fungsi |
|---|---|
| `iPadView.swift` | Shell dengan segmented picker: Grading / Dashboard |
| `GradingView.swift` | Menampilkan proses & hasil grading berjalan |
| `DashboardView.swift` | Analitik batch, daftar buah yang di-reject |

---

## Alur Data

```
                      ┌─ DefectDetector ──┐
CameraSession ──frame─┤                   │
                      └─ ColorAnalyzer ───┤
                                          ├──► MangoSample ──► GradingEngine ──► GradeResult
                         SizeEstimator ───┤       (fakta)         (aturan)        (keputusan)
                                          │
                         BLEService ──────┘
                    (weight, height dari ESP32)
```

`MangoSample` adalah titik temu semua sinyal — dan ini disengaja: **batas antara CV dan UI adalah batas yang sama dengan batas antara iPhone dan iPad.** Objek `Codable` yang hari ini dibaca `CaptureView` di iPhone, nanti tinggal dikirim lewat kabel ke iPad tanpa perubahan bentuk.

---

## Roadmap Folder

| Folder | Status | Menunggu |
|---|---|---|
| `Core/Models/` | 🔨 sekarang | — |
| `Core/Capture/` | 🔨 sekarang | — |
| `Core/Vision/` | 🔨 sekarang | — |
| `Core/Grading/` | ⏸ ditunda | minimal 2 sinyal nyata (defect + weight) |
| `Core/Bluetooth/` | ⏸ ditunda | firmware ESP32 punya BLE peripheral |
| `Core/Connectivity/` | ⏸ ditunda | pipeline CV iPhone stabil |
| `Core/Persistence/` | ⏸ ditunda | grading loop lengkap; lalu tambah Firebase via SPM |
| `DesignSystem/` | ⏸ ditunda | UI final dipindah ke iPad |

`Core/Grading/` ditunda bukan karena tidak penting, tapi karena rule engine dengan satu input hanya akan jadi `if defect > x` yang pasti dibuang begitu weight masuk.

---

## Konvensi

**Menambah file.** Project ini memakai `objectVersion = 77` dengan *synchronized folder groups* — folder yang dibuat di Finder otomatis terbaca Xcode. Tidak perlu drag-and-drop manual, dan `project.pbxproj` tidak ikut berubah (artinya jauh lebih sedikit merge conflict).

**Izin kamera.** Build setting `GENERATE_INFOPLIST_FILE = YES`, jadi tidak ada file `Info.plist`. Izin ditambahkan lewat Build Settings sebagai `INFOPLIST_KEY_NSCameraUsageDescription`.

**State management.** `@Observable` (bukan `ObservableObject`). Satu ViewModel per layar, ditaruh bersebelahan dengan View-nya di dalam `Features/`.

**Penamaan.** Protocol pakai bentuk `-ing` atau `-able` (`DefectDetecting`), implementasinya menyebut teknologinya (`CoreMLDefectDetector`, `MockDefectDetector`).

---

## Catatan Model CV

Model defect detection berasal dari [Roboflow Universe: mango-defect-detectionv4](https://universe.roboflow.com/mangotest/mango-defect-detectionv4) (CC BY 4.0).

Tiga hal yang perlu diketahui sebelum mengandalkan model ini:

**Hanya 1 kelas: `defect`.** Blush (semburat merah penanda ripeness) **bukan** output model ini — itu sinyal warna dan butuh jalur analisis terpisah.

**Metrik masih rendah.** mAP@50 38.2%, precision 43.6%, recall 42.0%, dataset 401 gambar. Cukup untuk memvalidasi bahwa pipeline berjalan, **tidak cukup** untuk mengkalibrasi threshold grading. Jangan menyetel aturan grading berdasarkan output model versi ini.

**Perlu re-train untuk Core ML.** Versi yang ter-train saat ini memakai arsitektur "Roboflow 3.0 Object Detection (Fast)" yang khusus hosted API dan tidak punya jalur export Core ML. Untuk on-device, dataset yang sama perlu di-train ulang sebagai **YOLOv11n** atau **RF-DETR-nano**, lalu di-export ke `.mlpackage`.

Karena output model adalah bounding box (bukan sekadar label), sinyal grading yang sebenarnya berguna adalah **geometri**-nya: jumlah bercak, rasio luas defect terhadap luas buah, dan posisi bercak. Itu yang masuk ke `GradingEngine`, bukan label mentahnya.

---

## Indikator Grading

| Indikator | Sumber | Status |
|---|---|---|
| Defect | Core ML (Roboflow) — dari bbox | 🔨 dikerjakan |
| Color / Blush | Analisis warna kamera | ❓ masih eksplorasi |
| Size (p × l) | Kamera | ⏸ belum |
| Height | Sensor ToF (VL53L0X) via ESP32 | ⏸ belum |
| Weight | Load cell + HX711 via ESP32 | ⏸ belum |

Untuk pengukuran size: karena interior box tetap dan geometrinya diketahui, kalibrasi piksel→mm dengan objek referensi berukuran pasti akan lebih akurat sekaligus lebih murah daripada memakai ARKit.

---

## Requirements

- Xcode 26+
- iOS 26.5+ (`IPHONEOS_DEPLOYMENT_TARGET` — cukup tinggi, membatasi pilihan device untuk testing; pertimbangkan diturunkan)
- Device fisik untuk semua pengujian kamera — Simulator tidak punya kamera
