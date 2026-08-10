import SwiftUI

struct GradeResultCard: View {
    let result: GradeResult

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(result.grade.displayName)
                    .font(.title3.bold())
                Spacer()
                Circle()
                    .fill(result.grade.tint)
                    .frame(width: 14, height: 14)
            }

            Divider()

            ForEach(result.reasons) { reason in
                HStack(spacing: 8) {
                    Text(reason.indicator.displayName)
                        .frame(width: 92, alignment: .leading)
                    Text(reason.detail)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(reason.grade.rawValue.uppercased())
                        .font(.caption2.bold())
                        .foregroundStyle(reason.grade.tint)
                }
                .font(.caption)
            }
        }
        .padding()
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
        color: ColorProfile(hue: 38, saturation: 120, brightness: 150, blushCoverage: 9),
        dimensions: Dimensions(length: 125, width: 82, height: 70),
        mass: 372
    )

    if let result = GradingEngine().evaluate(sample) {
        GradeResultCard(result: result)
            .padding()
    }
}
