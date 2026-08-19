import SwiftUI
import UIKit

struct RejectedMangoDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State var selectedRecord: MangoRecord
    let allRecords: [MangoRecord]
    let contextTitle: String

    /// Foto yang sedang dibuka besar. `nil` = tidak ada pratinjau.
    @State private var preview: MangoPhotoPreview? = nil

    var body: some View {
        ZStack {
            Color(red: 247/255, green: 247/255, blue: 248/255)
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 20) {
                // MARK: - Header Bar
                HStack(spacing: 16) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)
                            .frame(width: 44, height: 44)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Log Mangga Reject")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.black)
                        // Ikut konteks layar pemanggil ("Data Harian" / "Tren 30
                        // Hari"), bukan lagi teks "Tren 7 Hari" yang di-hardcode.
                        Text(contextTitle)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                
                // MARK: - Action Filter Buttons
                HStack(spacing: 12) {
                    Button(action: {}) {
                        HStack(spacing: 8) {
                            Text("Filter Tanggal")
                                .font(.system(size: 14, weight: .medium))
                            Image(systemName: "calendar")
                                .font(.system(size: 14))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    }
                    
                    Button(action: {}) {
                        HStack(spacing: 8) {
                            Text("Urutkan")
                                .font(.system(size: 14, weight: .medium))
                            Image(systemName: "line.3.horizontal.decrease")
                                .font(.system(size: 14))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    }
                }
                
                // MARK: - Main Content Split Area
                HStack(alignment: .top, spacing: 20) {
                    // Left Sidebar Code List
                    VStack(spacing: 0) {
                        Text("Kode")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(red: 85/255, green: 85/255, blue: 85/255))
                        
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: 0) {
                                ForEach(allRecords) { record in
                                    Button(action: { selectedRecord = record }) {
                                        Text(record.formattedCode)
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.black)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(
                                                selectedRecord.id == record.id
                                                ? Color.blue.opacity(0.12)
                                                : Color.white
                                            )
                                    }
                                    Divider()
                                }
                            }
                        }
                    }
                    .frame(width: 180)
                    .background(Color.white)
                    .cornerRadius(18)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                    
                    // Right Detail Card
                    VStack(spacing: 24) {
                        // Judul ikut kode mangga yang sedang dibuka, supaya
                        // operator tahu baris mana yang sedang dilihat tanpa
                        // harus mencocokkan ke sidebar.
                        Text("Detail Reject Mangga \(selectedRecord.formattedCode)")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.black)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        
                        // Foto Mangga Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Foto Mangga")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.black)
                            
                            // Foto asli hasil capture, dimuat lewat id record
                            // yang sama dengan yang dipakai saat menyimpan di
                            // `iPadView.saveLatestResult`.
                            HStack(spacing: 20) {
                                MangoPhotoBox(
                                    title: "SISI A",
                                    subtitle: "Bagian Depan",
                                    recordID: selectedRecord.id,
                                    side: .a,
                                    onTap: { image in
                                        preview = MangoPhotoPreview(
                                            title: "\(selectedRecord.formattedCode) — Sisi A (Bagian Depan)",
                                            image: image
                                        )
                                    }
                                )
                                MangoPhotoBox(
                                    title: "SISI B",
                                    subtitle: "Bagian Belakang",
                                    recordID: selectedRecord.id,
                                    side: .b,
                                    onTap: { image in
                                        preview = MangoPhotoPreview(
                                            title: "\(selectedRecord.formattedCode) — Sisi B (Bagian Belakang)",
                                            image: image
                                        )
                                    }
                                )
                            }
                        }
                        
                        // Penyebab Reject Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Penyebab Reject")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.black)
                            
                            HStack(spacing: 16) {
                                weightCard
                                defectCard
                                colorCard
                            }
                        }
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.white)
                    .cornerRadius(24)
                    .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 20)
            .padding(.bottom, 24)
        }
        .navigationBarBackButtonHidden(true)
        .fullScreenCover(item: $preview) { item in
            MangoPhotoViewerView(preview: item) {
                preview = nil
            }
        }
    }

    // MARK: - Kartu Penyebab Reject
    //
    // Ambang ketiga kartu dibaca dari `GradingStandard.harumManis`, bukan
    // ditulis ulang sebagai angka baru di sini. Kalau standarnya diubah, badge
    // ikut berubah sendiri — tidak ada versi kedua yang bisa diam-diam melenceng
    // dari mesin grading yang sebenarnya memutuskan.

    private var standard: GradingStandard { .harumManis }

    private var weightCard: some View {
        let grams = selectedRecord.weightGrams
        let severity: CauseSeverity =
            grams < standard.minMassDisqualification ? .critical
            : grams < 350 ? .caution
            : .normal

        return RejectCauseCard(
            title: "berat",
            icon: "scalemass",
            value: "\(Int(grams)) gram",
            statusText: selectedRecord.weightStatus,
            severity: severity
        )
    }

    /// Kartu ini dulu berjudul "blush" padahal isinya `defectPercent` — luas
    /// bintik, bukan blush. Judulnya diluruskan supaya tidak bertabrakan dengan
    /// kartu warna di sebelahnya, yang sekarang benar-benar melaporkan blush.
    private var defectCard: some View {
        let percent = selectedRecord.defectPercent
        let severity: CauseSeverity =
            percent > standard.maxDefectDisqualification ? .critical
            : percent > 15 ? .caution
            : .normal

        let status: String
        switch severity {
        case .critical:
            status = String(
                format: "melebihi ambang %.0f%%",
                standard.maxDefectDisqualification
            )
        case .caution: status = "bintik cukup banyak"
        default: status = "dalam batas"
        }

        return RejectCauseCard(
            title: "bintik / defek",
            icon: "circle.dotted",
            value: String(format: "%.0f%%", percent),
            statusText: status,
            severity: severity
        )
    }

    @ViewBuilder
    private var colorCard: some View {
        if let color = selectedRecord.color {
            RejectCauseCard(
                title: "warna",
                icon: "circle.fill",
                // Titiknya memakai warna yang benar-benar terukur. Kalau
                // terlihat abu-abu atau biru, itu bukan bug tampilan — itu
                // tanda mask menangkap sesuatu yang bukan kulit buah.
                iconColor: color.swatch,
                value: color.displayName,
//                detail: String(format: "blush %.0f%%", color.blushCoverage),
                statusText: color.ripeness.label,
                severity: color.ripeness.isProblem ? .critical : .normal
            )
        } else {
            // Record lama, disimpan sebelum warna ikut dikirim dari iPhone.
            // Ditulis apa adanya, bukan ditebak.
            RejectCauseCard(
                title: "warna",
                icon: "circle.dashed",
                value: "—",
                statusText: "data warna belum tersedia",
                severity: .unknown
            )
        }
    }
}

// MARK: - Subviews & Components

/// Satu kotak foto dokumentasi reject. Gambarnya dibaca dari
/// `MangoImageStore` — bukan dari asset catalog: foto ini dibuat saat runtime
/// oleh iPhone dan dikirim lewat `StationSnapshot`, jadi tidak mungkin ada
/// sebagai aset yang di-bundle. Versi sebelumnya menunjuk ke nama aset
/// `mango_side_a`/`mango_side_b` yang tidak pernah ada, jadi kedua kotak selalu
/// kosong walaupun foto sebenarnya tersimpan di disk.
struct MangoPhotoBox: View {
    let title: String
    var subtitle: String? = nil
    let recordID: UUID
    let side: MangoImageStore.Side

    /// Dipanggil saat kotak ditekan, hanya kalau fotonya memang ada. Kotak
    /// kosong sengaja tidak bisa ditekan supaya tidak membuka pratinjau hampa.
    var onTap: ((UIImage) -> Void)? = nil

    @State private var image: UIImage?

    var body: some View {
        VStack(spacing: 8) {
            VStack(spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.gray)

                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.gray.opacity(0.8))
                }
            }

            photoFrame
        }
        // `id:` supaya kotak ikut memuat ulang ketika operator memilih kode
        // mangga lain di sidebar, bukan menahan foto record sebelumnya.
        .task(id: recordID) {
            image = MangoImageStore.shared.image(id: recordID, side: side)
        }
    }

    @ViewBuilder
    private var photoFrame: some View {
        if let image {
            Button {
                onTap?(image)
            } label: {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 180)
                    .clipped()
                    .overlay(alignment: .bottomTrailing) { zoomBadge }
                    .background(Color(red: 240/255, green: 240/255, blue: 243/255))
                    .cornerRadius(16)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Perbesar foto \(title)")
        } else {
            placeholder
                .frame(maxWidth: .infinity)
                .frame(height: 180)
                .background(Color(red: 240/255, green: 240/255, blue: 243/255))
                .cornerRadius(16)
        }
    }

    /// Petunjuk kecil bahwa foto bisa ditekan.
    private var zoomBadge: some View {
        Image(systemName: "arrow.up.left.and.arrow.down.right")
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(.white)
            .frame(width: 28, height: 28)
            .background(Color.black.opacity(0.45), in: Circle())
            .padding(10)
    }

    private var placeholder: some View {
        VStack(spacing: 8) {
            Image(systemName: "photo")
                .font(.system(size: 28))
                .foregroundColor(.gray.opacity(0.5))

            Text("Foto tidak tersedia")
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Photo Viewer

/// Foto yang sedang dibuka besar. `id` baru tiap kali dibuat supaya
/// `fullScreenCover(item:)` ikut berganti kalau operator langsung pindah dari
/// satu sisi ke sisi lain.
struct MangoPhotoPreview: Identifiable {
    let id = UUID()
    let title: String
    let image: UIImage
}

/// Pratinjau foto satu layar penuh. Tombol X di kanan atas mengikuti gaya yang
/// sama dengan `ResultScreen` supaya cara menutup layar konsisten di seluruh app.
struct MangoPhotoViewerView: View {

    let preview: MangoPhotoPreview
    var onClose: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.94)
                .ignoresSafeArea()
                // Ketuk di luar foto juga menutup — tombol X tetap jalur utamanya.
                .onTapGesture { onClose() }

            VStack(spacing: 20) {
                Text(preview.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Image(uiImage: preview.image)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(16)
            }
            .padding(.horizontal, 60)
            .padding(.top, 80)
            .padding(.bottom, 60)

            // MARK: - Close Button
            VStack {
                HStack {
                    Spacer()

                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.black)
                            .frame(width: 44, height: 44)
                            .background(.white.opacity(0.85))
                            .clipShape(Circle())
                    }
                    .padding(.top, 16)
                    .padding(.trailing, 20)
                    .accessibilityLabel("Tutup pratinjau foto")
                }

                Spacer()
            }
        }
    }
}

/// Seberapa serius satu indikator, dan bagaimana badge-nya terlihat.
///
/// Dulu tiap kartu dititipi `badgeColor`, `textColor`, dan `statusIcon` sendiri,
/// dan ketiganya selalu diisi merah — jadi indikator yang nilainya baik pun
/// tampil seperti penyebab reject. Sekarang tampilannya turunan dari datanya.
enum CauseSeverity {
    /// Nilai di dalam standar.
    case normal
    /// Masih diterima tapi mendekati batas.
    case caution
    /// Melewati batas — inilah yang benar-benar menolak buah.
    case critical
    /// Tidak ada datanya. Bukan bagus, bukan jelek.
    case unknown

    var icon: String {
        switch self {
        case .normal: "checkmark.circle.fill"
        case .caution: "arrow.up.right"
        case .critical: "xmark.circle.fill"
        case .unknown: "questionmark.circle"
        }
    }

    var textColor: Color {
        switch self {
        case .normal: Color(red: 15/255, green: 110/255, blue: 45/255)
        case .caution: Color(red: 138/255, green: 98/255, blue: 12/255)
        case .critical: Color(red: 180/255, green: 40/255, blue: 50/255)
        case .unknown: Color(red: 114/255, green: 114/255, blue: 114/255)
        }
    }

    var badgeColor: Color {
        switch self {
        case .normal: Color(red: 236/255, green: 248/255, blue: 241/255)
        case .caution: Color(red: 254/255, green: 248/255, blue: 235/255)
        case .critical: Color(red: 253/255, green: 238/255, blue: 240/255)
        case .unknown: Color(red: 242/255, green: 242/255, blue: 247/255)
        }
    }
}

struct RejectCauseCard: View {
    let title: String
    let icon: String
    var iconColor: Color = .gray
    let value: String

    /// Baris kecil di bawah nilai utama, untuk angka pendamping seperti blush.
    var detail: String? = nil

    let statusText: String
    let severity: CauseSeverity

    var body: some View {
        VStack(spacing: 10) {
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.gray)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            VStack(spacing: 2) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(iconColor)

                    Text(value)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }

                if let detail {
                    Text(detail)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }

            HStack(spacing: 4) {
                Image(systemName: severity.icon)
                    .font(.system(size: 10, weight: .bold))
                Text(statusText)
                    .font(.system(size: 11, weight: .semibold))
                    .multilineTextAlignment(.center)
            }
            .foregroundColor(severity.textColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(severity.badgeColor)
            .cornerRadius(8)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.18), lineWidth: 1)
        )
    }
}

#Preview("Reject Detail", traits: .landscapeLeft) {
    let records = DummyDataStore.generateDummyRecords()
    let rejectedRecords = records.filter { $0.grade == .reject }
    
    if let selectedRecord = rejectedRecords.first {
        RejectedMangoDetailView(
            selectedRecord: selectedRecord,
            allRecords: rejectedRecords,
            contextTitle: "Data Harian"
        )
    }
}
