import SwiftUI
import UniformTypeIdentifiers

struct LibraryView: View {
    @StateObject private var library = ROMLibrary()
    @State private var importer = false
    @State private var folderImporter = false
    @State private var mode: ARMode = .miniature
    @State private var selected: LibraryGame?
    @State private var search = ""
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [Color(red: 0.025, green: 0.07, blue: 0.13), .black], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        HStack {
                            Image(systemName: "cube.transparent.fill").font(.system(size: 36)).foregroundStyle(.mint)
                            VStack(alignment: .leading) {
                                Text("AR-MAME").font(.system(size: 34, weight: .black, design: .rounded))
                                Text("YOUR ARCADE. A NEW DIMENSION.").font(.system(size: 9, weight: .bold)).tracking(2).foregroundStyle(.mint)
                            }
                            Spacer()
                        }
                        VStack(alignment: .leading, spacing: 12) {
                            Text("An arcade world,\nwherever you are.").font(.system(size: 30, weight: .bold, design: .rounded))
                            Text("Place a miniature on your table or scale it across an outdoor space.").font(.callout).foregroundStyle(.secondary)
                            Picker("World mode", selection: $mode) {
                                ForEach(ARMode.allCases) { Text($0.rawValue).tag($0) }
                            }.pickerStyle(.segmented)
                        }.padding(22).background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 24))
                        HStack {
                            Button { importer = true } label: { Label("Import ROM", systemImage: "plus.circle.fill") }
                                .buttonStyle(.borderedProminent).tint(.mint).foregroundStyle(.black)
                            Button { folderImporter = true } label: { Label("Import Folder", systemImage: "folder") }.buttonStyle(.bordered)
                        }
                        Button { selected = library.installDiagnostic() } label: {
                            Label("Try Original Z80 Diagnostic", systemImage: "cpu")
                        }.font(.callout)
                        Text("A generated test board with an input-controlled sprite, running on MAME. No commercial ROM required.")
                            .font(.caption).foregroundStyle(.secondary)
                        if !library.message.isEmpty { Text(library.message).font(.caption).foregroundStyle(.secondary) }
                        HStack { Text("GAME LIBRARY").font(.caption.bold()).tracking(2); Spacer(); Text("\(library.games.count) sets").font(.caption).foregroundStyle(.secondary) }
                        if library.games.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "square.stack.3d.up").font(.largeTitle).foregroundStyle(.mint)
                                Text("Your collection starts here").font(.headline)
                                Text("Import your own MAME 2003-Plus ZIP sets. No commercial ROMs are included.").font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
                            }.frame(maxWidth: .infinity).padding(30).background(.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 20))
                        } else {
                            TextField("Find a game", text: $search).padding(12).background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
                            ForEach(library.games.filter { search.isEmpty || $0.title.localizedCaseInsensitiveContains(search) }) { game in
                                Button { selected = game } label: {
                                    HStack(spacing: 14) {
                                        Image(systemName: game.hasHardwareProfile ? "cube.fill" : "arcade.stick.console.fill")
                                            .font(.title2).foregroundStyle(.mint).frame(width: 48, height: 56)
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(game.title).font(.headline).foregroundStyle(.white)
                                            Text([game.record?.year, game.record?.manufacturer].compactMap { $0 }.joined(separator: " · "))
                                                .font(.caption).foregroundStyle(.secondary)
                                            Text(game.hasHardwareProfile ? "EXPERIMENTAL HARDWARE 3D" : "ORIGINAL + EXPERIMENTAL GENERIC 3D")
                                                .font(.system(size: 8, weight: .bold)).tracking(1).foregroundStyle(.mint)
                                        }
                                        Spacer(); Image(systemName: "chevron.right").foregroundStyle(.secondary)
                                    }.padding(12).background(.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 16))
                                }
                            }
                        }
                        DisclosureGroup("Compatibility & prototype status") {
                            Text("MAME 2003-Plus is the current core. ZIP sets and core-compatible CHDs/BIOS are supported by the integration; 7z must be converted to ZIP. Only pacman and puckman have a hardware 3D prototype. Other games start in a labeled flat fallback. Generic color segmentation is experimental and cannot infer full levels or game semantics. No iPhone compatibility is claimed until tested on hardware.")
                                .font(.caption).foregroundStyle(.secondary).padding(.top, 8)
                        }
                    }.padding(22)
                }
            }
            .navigationDestination(item: $selected) { game in
                GameDetailView(game: game, library: library, mode: mode)
            }
            .fileImporter(isPresented: $importer, allowedContentTypes: [.item], allowsMultipleSelection: true) { result in
                if case .success(let urls) = result { library.importItems(urls) }
                if case .failure(let error) = result { library.message = error.localizedDescription }
            }
            .fileImporter(isPresented: $folderImporter, allowedContentTypes: [.folder], allowsMultipleSelection: false) { result in
                if case .success(let urls) = result { library.importItems(urls) }
                if case .failure(let error) = result { library.message = error.localizedDescription }
            }
        }.preferredColorScheme(.dark).tint(.mint)
    }
}

private struct GameDetailView: View {
    let game: LibraryGame
    @ObservedObject var library: ROMLibrary
    let mode: ARMode
    @State private var play = false
    var body: some View {
        List {
            Section(game.title) {
                LabeledContent("Set", value: game.name)
                LabeledContent("Year", value: game.record?.year ?? "Unknown")
                LabeledContent("Manufacturer", value: game.record?.manufacturer ?? "Unknown")
                LabeledContent("ROM compatibility", value: "Core audit at launch")
                LabeledContent("3D profile", value: game.hasHardwareProfile ? "Experimental Pac-Man hardware" : "Experimental generic / flat fallback")
                LabeledContent("Indoor / Outdoor", value: "Available; device testing required")
                Text("Players, buttons, and screen orientation are read from the machine definition at launch.").font(.caption)
            }
            Section("Dependencies") {
                let warnings = library.dependencyWarnings(game)
                if warnings.isEmpty { Text("No missing dependency filenames detected. MAME performs the content audit.") }
                ForEach(warnings, id: \.self) { Text($0).foregroundStyle(.orange) }
            }
            Section {
                Button("Play · \(mode.rawValue)") { play = true }
                Text("Use a clear space. You can play while stationary. World placement is local visual-inertial AR; large scenes can drift.").font(.caption)
            }
        }.navigationTitle("Game Details")
            .fullScreenCover(isPresented: $play) { GameplayView(game: game, library: library, mode: mode) }
    }
}

extension LibraryGame: Hashable {
    static func == (lhs: LibraryGame, rhs: LibraryGame) -> Bool { lhs.url == rhs.url }
    func hash(into hasher: inout Hasher) { hasher.combine(url) }
}
