import Foundation

struct MockFruitSegmenter: FruitSegmenting {
    var areaRatio: Double = 0.42

    func fruitAreaRatio(in input: VisionInput) async throws -> Double {
        areaRatio
    }
}
