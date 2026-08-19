import SwiftUI
import UIKit

struct RejectedMangoDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State var selectedRecord: MangoRecord
    let allRecords: [MangoRecord]
    let contextTitle: String
    
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
                                    side: .a
                                )
                                MangoPhotoBox(
                                    title: "SISI B",
                                    subtitle: "Bagian Belakang",
                                    recordID: selectedRecord.id,
                                    side: .b
                                )
                            }
                        }
                        
                        // Penyebab Reject Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Penyebab Reject")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.black)
                            
                            HStack(spacing: 16) {
                                RejectCauseCard(
                                    title: "berat",
                                    icon: "scalemass",
                                    value: "\(Int(selectedRecord.weightGrams)) gram",
                                    statusIcon: "xmark.circle.fill",
                                    statusText: selectedRecord.weightStatus,
                                    badgeColor: Color(red: 253/255, green: 238/255, blue: 240/255),
                                    textColor: Color(red: 180/255, green: 40/255, blue: 50/255)
                                )
                                
                                RejectCauseCard(
                                    title: "blush",
                                    icon: "flag.fill",
                                    value: "\(Int(selectedRecord.defectPercent))%",
                                    statusIcon: "arrow.up.right",
                                    statusText: "bintik/defek terlalu tinggi",
                                    badgeColor: Color(red: 253/255, green: 238/255, blue: 240/255),
                                    textColor: Color(red: 180/255, green: 40/255, blue: 50/255)
                                )
                                
                                RejectCauseCard(
                                    title: "warna",
                                    icon: "circle.fill",
                                    iconColor: .yellow,
                                    value: "kuning",
                                    statusIcon: "exclamationmark.triangle.fill",
                                    statusText: "mangga terlalu matang",
                                    badgeColor: Color(red: 253/255, green: 238/255, blue: 240/255),
                                    textColor: Color(red: 180/255, green: 40/255, blue: 50/255)
                                )
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

            Group {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    placeholder
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 180)
            .background(Color(red: 240/255, green: 240/255, blue: 243/255))
            .cornerRadius(16)
            .clipped()
        }
        // `id:` supaya kotak ikut memuat ulang ketika operator memilih kode
        // mangga lain di sidebar, bukan menahan foto record sebelumnya.
        .task(id: recordID) {
            image = MangoImageStore.shared.image(id: recordID, side: side)
        }
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

struct RejectCauseCard: View {
    let title: String
    let icon: String
    var iconColor: Color = .gray
    let value: String
    let statusIcon: String
    let statusText: String
    let badgeColor: Color
    let textColor: Color
    
    var body: some View {
        VStack(spacing: 10) {
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.gray)
            
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(iconColor)
                
                Text(value)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.black)
            }
            
            HStack(spacing: 4) {
                Image(systemName: statusIcon)
                    .font(.system(size: 10, weight: .bold))
                Text(statusText)
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundColor(textColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(badgeColor)
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
