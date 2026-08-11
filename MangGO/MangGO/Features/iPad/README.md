# MangGO — Layar iPad

Folder ini isinya semua tampilan yang jalan di **iPad**. iPad di proyek ini
perannya cuma **display**: dia tidak punya kamera, tidak ngitung grading, dan
tidak ngobrol sama ESP32. Semua itu kerjaan iPhone. iPad tugasnya satu:
menampilkan apa pun yang dikirim iPhone, sejelas mungkin, supaya kebaca dari
jarak beberapa meter di lantai pabrik.

Dokumen ini ditulis buat siapa pun yang mau ngerjain bagian **Dashboard**.

---

## 1. Peta file

```
Features/iPad/
├── iPadView.swift            # Shell: tab picker + overlay hasil. Jangan ditaruhin logika.
│
├── Grading/                  # Tab "Grading"
│   ├── GradingScreen.swift   # Router: mau nampilin layar yang mana
│   ├── IdleScreen.swift      # Nunggu mangga (status sensor + 3 langkah)
│   ├── ScanningScreen.swift  # Lagi proses (progress per fase)
│   ├── ResultScreen.swift    # Hasil 1 buah, warna penuh layar
│   └── DisconnectedScreen.swift
│
├── Dashboard/                # Tab "Dashboard"  ← area kerja kamu
│   ├── DashboardScreen.swift    # Layout utama, cuma nyusun section
│   ├── GradeCountRow.swift      # Kotak jumlah A / B / C / Reject
│   ├── LastResultSection.swift  # Detail buah terakhir
│   ├── MetricTile.swift         # Kotak angka tunggal (dipakai berulang)
│   └── SensorSummaryRow.swift   # Titik status sensor versi padat
│
└── Shared/                   # Dipakai dua tab
    ├── GradeDisplay.swift    # Warna & judul per grade + StationSnapshot.completedGrade
    └── SensorStatus.swift    # Warna & label status sensor
```

Aturan pembagiannya sederhana: **satu file = satu hal yang bisa dilihat**.
Kalau ada komponen yang cuma dipakai satu layar, taruh `private` di file layar
itu. Kalau dipakai lebih dari satu layar, baru naik ke `Shared/`.

---

## 2. Dari mana datanya datang

```
ESP32 ──BLE──► iPhone ──Multipeer──► iPad
                (station)             (display)
```

1. iPhone bikin `StationSnapshot` setiap kali statusnya berubah.
2. `StationSync.publish(_:)` meng-encode-nya jadi JSON dan mengirim ke iPad.
3. iPad menerima, decode, lalu update `sync.snapshot`.
4. `StationSync` itu `@Observable`, jadi semua view yang baca `sync.snapshot`
   otomatis ikut re-render. **Kamu tidak perlu nulis kode networking sama
   sekali** — cukup baca snapshot-nya.

Di `iPadView`, snapshot dioper ke bawah sebagai parameter biasa:

```swift
DashboardScreen(snapshot: snapshot)
```

Sengaja dioper eksplisit, bukan lewat `@Environment`, supaya tiap komponen bisa
di-`#Preview` sendirian tanpa nyalain koneksi.

### Isi `StationSnapshot` (di `Core/Sync/StationSnapshot.swift`)

| Field | Tipe | Catatan |
|---|---|---|
| `phase` | `Phase` | `idle`, `scanningFront`, `flipping`, `weighing`, `scanningBack`, `done`. Punya `.label`, `.progress`, `.isWorking`. |
| `lastResult` | `Result?` | **Bisa nil** kalau belum ada buah yang selesai. |
| `counts` | `[String: Int]` | Key-nya `"A"`, `"B"`, `"C"`, `"Reject"` — sama persis dengan `GradeDisplay.rawValue`. |
| `sensors` | `Sensors` | `loadCell`, `tof`, `camera`, `bluetooth`, masing-masing `ready` / `waiting` / `offline`. |
| `updatedAt` | `Date` | Dipakai buang paket basi. Jangan diandalkan buat "berapa lama sejak update terakhir" — jamnya beda device. |

`Result` isinya: `grade` (String), `reason` (String?), `weightGrams`,
`volumeCm3`, `blushPercent`, `defectPercent` — **semua angkanya `Double?`**,
karena sensor bisa gagal baca satu nilai tapi grading tetap jalan. Selalu
tangani `nil`-nya (`MetricTile` sudah, dia nampilin "—").

---

## 3. Cara nambah section baru di Dashboard

Contoh: mau nambah grafik tren grade per jam.

1. Bikin file baru `Dashboard/GradeTrendChart.swift`.
2. Bikin `struct GradeTrendChart: View` yang terimanya **data mentah**, bukan
   `StationSnapshot` utuh — makin sempit input-nya makin gampang di-preview.
   ```swift
   struct GradeTrendChart: View {
       let counts: [String: Int]
       // ...
   }
   ```
3. Kasih `#Preview` dengan data dummy di file yang sama. Wajib — ini yang bikin
   kamu bisa kerja tanpa nyalain alat.
4. Panggil dari `DashboardScreen.body`:
   ```swift
   Text("Tren").font(.title3.weight(.bold))
   GradeTrendChart(counts: snapshot.counts)
   ```

`DashboardScreen` idealnya tetap tipis — cuma nyusun urutan section. Kalau
badan-nya mulai lewat ~50 baris, berarti ada yang harusnya jadi file sendiri.

**File baru otomatis kebaca Xcode.** Project ini pakai *file system
synchronized groups*, jadi nggak perlu drag-drop atau nyentuh `.pbxproj`.

---

## 4. Aturan main

**Warna jangan di-hardcode.**
Warna grade ambil dari `GradeDisplay.color`, warna status sensor dari
`state.color` (extension di `Shared/SensorStatus.swift`). Kalau kamu nulis
`.green` langsung di Dashboard, cepat atau lambat hijau-nya beda sama hijau di
tab Grading, dan operator bakal ngira artinya beda.

**Teks minimal `.title3` untuk angka penting.**
iPad-nya dipasang agak jauh dari operator. `.caption` nggak kebaca.

**Selalu sediakan tampilan kosong.**
Dashboard hidup dari awal shift waktu `counts` masih kosong dan `lastResult`
masih `nil`. Lihat `LastResultSection` sebagai contoh — ada cabang `else`-nya.

**Jangan bikin animasi yang jalan terus.**
Tab Dashboard dipakai buat baca angka. Angka yang gerak-gerak susah dibaca.
Animasi cuma dipakai di transisi fase (`iPadView` sudah handle).

**Angka basi lebih bahaya dari layar kosong.**
Kalau kamu bikin fitur yang nunjukkin data lama, kasih penanda jelas. Tab
Grading sudah nerapin ini: begitu link putus, dia langsung ganti ke
`DisconnectedScreen`, bukan nahan tampilan terakhir.

---

## 5. Cara ngetes tanpa alat

**Preview per komponen** — cara paling cepat. Tiap file di `Dashboard/` sudah
punya `#Preview` dengan data dummy. Buka file-nya, tekan
<kbd>⌥</kbd><kbd>⌘</kbd><kbd>↩</kbd>, langsung kelihatan.

**Simulator dua device** — kalau mau lihat alurnya utuh:

1. Jalankan app di **iPhone simulator** dan **iPad simulator** barengan.
2. Di iPhone ada `SimulatorPanel` (`Core/Sync/StationSimulator.swift`, cuma ada
   di build DEBUG) — tombol A / B / C / Reject.
3. Tekan salah satu, iPhone bakal jalan lewat semua fase dengan angka acak, dan
   iPad ikut update.

Kalau iPad nggak nyambung-nyambung: cek izin **Local Network** dan pastikan
`NSBonjourServices` di `Info.plist` isinya `manggo-sync`. Error-nya muncul di
`sync.lastError` dan ditampilkan di `DisconnectedScreen`.

---

## 6. Yang belum ada

Silakan ambil kalau relevan sama kerjaan Dashboard:

- Riwayat per buah — sekarang cuma disimpan yang terakhir, `counts` juga hilang
  kalau app di-restart. Belum ada persistensi sama sekali.
- Statistik turunan: rata-rata berat, persentase reject, throughput per jam.
- Ekspor / rekap sesi.
- Penanda "data terakhir diterima X detik lalu".

---

## 7. Kalau nabrak sesuatu

Sebelum ubah file di luar `Features/iPad/`, ngobrol dulu — `Core/` dipakai
bareng sama sisi iPhone, jadi perubahan di situ gampang bikin orang lain
ke-block. Nambah field di `StationSnapshot` khususnya harus disepakati dua
sisi, karena yang ngisi field-nya iPhone.
