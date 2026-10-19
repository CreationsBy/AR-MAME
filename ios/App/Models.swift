import Foundation

enum ARMode: String, CaseIterable, Identifiable {
    case miniature = "Indoor Miniature"
    case giant = "Outdoor Giant World"
    var id: String { rawValue }
    var defaultWidth: Double { self == .miniature ? 0.6 : 25 }
}
enum RenderMode: String, CaseIterable, Identifiable {
    case hardware = "Pac-Man hardware profile (experimental)"
    case generic = "Generic 3D segmentation (experimental)"
    case original = "Original rendering (flat fallback)"
    var id: String { rawValue }
}
enum OcclusionMode: String, CaseIterable, Identifiable {
    case standard = "Standard"
    case depth = "Scene mesh occlusion (LiDAR)"
    case visible = "Always visible"
    case translucent = "Reduced opacity"
    var id: String { rawValue }
}
struct MachineRecord: Codable, Identifiable {
    var name: String
    var title: String
    var year: String
    var manufacturer: String
    var parent: String
    var dependencies: [String]
    var disks: [String]
    var id: String { name }
}
struct LibraryGame: Identifiable {
    var url: URL
    var record: MachineRecord?
    var id: String { url.lastPathComponent }
    var name: String { url.deletingPathExtension().lastPathComponent }
    var title: String { record?.title ?? name }
    var hasHardwareProfile: Bool { ["pacman", "puckman"].contains(name) }
}
struct ControlDescriptor: Identifiable {
    var port: UInt32
    var device: UInt32
    var index: UInt32
    var code: UInt32
    var label: String
    var id: String { "\(port):\(device):\(index):\(code)" }
    init?(_ raw: [String: Any]) {
        guard let port = raw["port"] as? NSNumber, let device = raw["device"] as? NSNumber,
              let index = raw["index"] as? NSNumber, let code = raw["id"] as? NSNumber,
              let label = raw["label"] as? String else { return nil }
        self.port = port.uint32Value; self.device = device.uint32Value
        self.index = index.uint32Value; self.code = code.uint32Value; self.label = label
    }
}
struct ControlPreferences: Codable {
    var opacity = 0.45
    var buttonSize = 58.0
    var deadZone = 0.2
    var sensitivity = 1.0
    var leftHanded = false
    var haptics = true
    var offsets: [String: [Double]] = [:]
    var remaps: [String: UInt32] = [:]
    static func load(game: String) -> Self {
        guard let data = UserDefaults.standard.data(forKey: "controls.\(game)"),
              let prefs = try? JSONDecoder().decode(Self.self, from: data) else { return .init() }
        return prefs
    }
    func save(game: String) {
        if let data = try? JSONEncoder().encode(self) { UserDefaults.standard.set(data, forKey: "controls.\(game)") }
    }
}
