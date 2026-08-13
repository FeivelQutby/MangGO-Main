import SwiftUI

struct GradeResultCard: View {
    let result: GradeResult

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(result.grade.displayName)
                        .font(.title3.bold())
                    if let disq = result.disqualificationReason {
                        Text(disq)
                            .font(.caption2.bold())
                            .foregroundStyle(.red)
                    }
                }

                Spacer()

                // Total Score Badge
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(String(format: "%.0f", result.totalScore))
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .foregroundStyle(result.grade.tint)
                    Text("/100")
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            VStack(spacing: 8) {
                ForEach(result.reasons) { reason in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(reason.indicator.displayName)
                                .font(.caption.bold())
                                .frame(width: 96, alignment: .leading)

                            Text(reason.detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Spacer()

                            Text(String(format: "%.0f", reason.score))
                                .font(.caption.bold().monospacedDigit())
                                .foregroundStyle(.primary)

                            Text(reason.grade.rawValue.uppercased())
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(reason.grade.tint, in: .capsule)
                        }

                        // Normalized Score Progress Bar
                        GeometryReader { proxy in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.secondary.opacity(0.15))
                                    .frame(height: 3)
                                Capsule()
                                    .fill(reason.grade.tint)
                                    .frame(width: proxy.size.width * CGFloat(min(max(reason.score, 0), 100) / 100.0), height: 3)
                            }
                        }
                        .frame(height: 3)
                    }
                }
            }
        }
        .padding(16)
        .background(.regularMaterial, in: .rect(cornerRadius: 16))
    }
}

extension Grade {
    var tint: Color {
        switch self {
        case .a: Color.green
        case .b: Color.yellow
        case .c: Color.orange
        case .rejected: Color.red
        }
    }
}

#Preview {
    let sample = MangoSample(
        defects: .moderate,
        fruitAreaRatio: 0.42,
        color: ColorProfile(hue: 25, saturation: 120, brightness: 150, blushCoverage: 12),
        dimensions: Dimensions(length: 125, width: 82, height: 70),
        mass: 410
    )

    if let result = GradingEngine().evaluate(sample) {
        GradeResultCard(result: result)
            .padding()
    }
}

