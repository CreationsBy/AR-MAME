import Foundation

/// Profiles are scoped data; the matching core graphics adapter must also be present.
struct ReconstructionProfile: Decodable {
    var schemaVersion: Int
    var id: String
    var status: String
    var games: [String]
    var nativeBounds: [Int]
    var displayRotationDegrees: Int
    var worldPlane: String
    var indoorWidthMeters: Double
    var outdoorWidthMeters: Double
    var wallHeightNormalized: Double
    var spriteHeightNormalized: Double
    var surfaceHeightNormalized: Double
    var limitations: [String]

    static func load(game: String) -> Self? {
        let files = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: nil) ?? []
        for file in files {
            guard file.lastPathComponent != "machines.json", let data = try? Data(contentsOf: file),
                  let value = try? JSONDecoder().decode(Self.self, from: data), value.schemaVersion == 1,
                  value.games.contains(game), value.nativeBounds == [288,224],
                  value.displayRotationDegrees == 90, value.worldPlane == "horizontal",
                  value.wallHeightNormalized > 0, value.wallHeightNormalized <= 1,
                  value.spriteHeightNormalized > 0, value.spriteHeightNormalized <= 1,
                  value.surfaceHeightNormalized > 0, value.surfaceHeightNormalized <= 1 else { continue }
            return value
        }
        return nil
    }
}
