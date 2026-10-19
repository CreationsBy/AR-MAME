import Foundation

final class ROMLibrary: ObservableObject {
    @Published var games: [LibraryGame] = []
    @Published var message = ""
    let root: URL
    let system: URL
    let saves: URL
    private var catalog: [String: MachineRecord] = [:]
    init() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        root = documents.appendingPathComponent("ROMs", isDirectory: true)
        system = documents.appendingPathComponent("System", isDirectory: true)
        saves = documents.appendingPathComponent("Saves", isDirectory: true)
        for path in [root, system, saves] { try? FileManager.default.createDirectory(at: path, withIntermediateDirectories: true) }
        if let url = Bundle.main.url(forResource: "machines", withExtension: "json"),
           let data = try? Data(contentsOf: url), let records = try? JSONDecoder().decode([MachineRecord].self, from: data) {
            catalog = Dictionary(records.map { ($0.name, $0) }, uniquingKeysWith: { a, _ in a })
        }
        refresh()
    }
    func refresh() {
        let files = (try? FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)) ?? []
        games = files.filter { $0.pathExtension.lowercased() == "zip" }.map {
            LibraryGame(url: $0, record: catalog[$0.deletingPathExtension().lastPathComponent.lowercased()])
        }.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
    }
    func installDiagnostic() -> LibraryGame? {
        let target = root.appendingPathComponent("armtest.zip")
        if !FileManager.default.fileExists(atPath: target.path),
           let source = Bundle.main.url(forResource: "armtest", withExtension: "zip") {
            do { try FileManager.default.copyItem(at: source, to: target) }
            catch { message = error.localizedDescription; return nil }
        }
        refresh()
        return games.first { $0.name == "armtest" }
    }
    func importItems(_ urls: [URL]) {
        var imported = 0
        var failures: [String] = []
        for url in urls {
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            do {
                var directory: ObjCBool = false
                guard FileManager.default.fileExists(atPath: url.path, isDirectory: &directory) else { continue }
                if directory.boolValue {
                    // A selected folder is the ROM root; preserve all child CHD machine folders.
                    let children = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
                    for child in children { try copy(child, to: root.appendingPathComponent(child.lastPathComponent)); imported += 1 }
                } else {
                    if url.pathExtension.lowercased() == "7z" {
                        throw LibraryError.detail("7z is not supported by this core. Convert to ZIP without changing the ROM contents.")
                    }
                    if url.pathExtension.lowercased() == "chd" {
                        throw LibraryError.detail("Import CHDs inside their machine folder using Import Folder; a loose CHD cannot identify its machine.")
                    }
                    guard url.pathExtension.lowercased() == "zip" else {
                        throw LibraryError.detail("Import a ZIP ROM set or a folder containing ZIP sets and CHD subfolders.")
                    }
                    try copy(url, to: root.appendingPathComponent(url.lastPathComponent)); imported += 1
                }
            } catch { failures.append("\(url.lastPathComponent): \(error.localizedDescription)") }
        }
        refresh()
        message = (["Imported \(imported) items."] + failures).joined(separator: "\n")
    }
    private func copy(_ source: URL, to destination: URL) throws {
        guard !FileManager.default.fileExists(atPath: destination.path) else {
            throw LibraryError.detail("Already imported: \(destination.lastPathComponent). Manage existing files in Files > AR-MAME.")
        }
        try FileManager.default.copyItem(at: source, to: destination)
    }
    func dependencyWarnings(_ game: LibraryGame) -> [String] {
        guard let record = game.record else { return ["Unknown to the pinned core catalog; the emulator will perform the final audit."] }
        var warnings = record.dependencies.filter {
            !FileManager.default.fileExists(atPath: root.appendingPathComponent($0 + ".zip").path)
        }.map { "Dependency may be missing: \($0).zip (merged sets may already contain it)." }
        warnings += record.disks.filter {
            !FileManager.default.fileExists(atPath: root.appendingPathComponent(game.name).appendingPathComponent($0 + ".chd").path)
        }.map { "CHD may be missing: \(game.name)/\($0).chd. Parent disk directories may also be searched by the core." }
        return warnings
    }
}
enum LibraryError: LocalizedError {
    case detail(String)
    var errorDescription: String? { if case .detail(let message) = self { return message }; return nil }
}
