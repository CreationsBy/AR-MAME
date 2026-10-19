import SwiftUI
import ARKit

struct GameplayView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var session: EmulationSession
    @StateObject private var world = ARWorld()
    @State private var preferences: ControlPreferences
    @State private var showMenu = false
    @State private var hidden = false
    @State private var editing = false
    @State private var volume = 1.0
    let initialMode: ARMode
    init(game: LibraryGame, library: ROMLibrary, mode: ARMode) {
        _session = StateObject(wrappedValue: EmulationSession(game: game, library: library))
        _preferences = State(initialValue: .load(game: game.name))
        initialMode = mode
    }
    var body: some View {
        ZStack {
            FullscreenARView(world: world, frame: session.frame).ignoresSafeArea()
            if !hidden {
                VStack {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(session.game.title).font(.caption.bold())
                            Text(world.tracking).font(.caption2)
                            Text("\(world.mode.rawValue) · \(world.width, specifier: "%.1f") m wide").font(.caption2)
                            Text(world.renderMode.rawValue).font(.caption2).foregroundStyle(.mint)
                        }
                        .padding(10).background(.black.opacity(0.45), in: RoundedRectangle(cornerRadius: 12))
                        Spacer()
                        Button { showMenu = true; session.setPaused(true) } label: {
                            Image(systemName: "pause.fill").padding(14).background(.black.opacity(0.4), in: Circle())
                        }.accessibilityLabel("Pause and settings")
                    }
                    Spacer()
                    if !world.placed {
                        VStack(spacing: 8) {
                            Image(systemName: "viewfinder").font(.title)
                            Text("Scan a surface, then tap to place").font(.callout.bold())
                            if world.mode == .giant {
                                Text("Play while stationary. Virtual structures are visual only.").font(.caption)
                            }
                        }
                        .padding().background(.black.opacity(0.5), in: RoundedRectangle(cornerRadius: 16))
                        Spacer()
                    }
                    if world.placed && !showMenu {
                        TouchControls(session: session, preferences: $preferences, editing: editing)
                    }
                }.padding(.horizontal, 12).padding(.top, 6)
            } else {
                VStack { HStack { Spacer(); Button("Show Controls") { hidden = false }
                    .font(.caption).padding(10).background(.black.opacity(0.3), in: Capsule()) }; Spacer() }.padding()
            }
            if showMenu { pausePanel }
        }
        .foregroundStyle(.white)
        .toolbar(.hidden, for: .navigationBar)
        .statusBarHidden().persistentSystemOverlays(.hidden)
        .onAppear {
            world.changeMode(initialMode)
            world.renderMode = session.game.hasHardwareProfile ? .hardware : .original
            session.start()
        }
        .onDisappear { preferences.save(game: session.game.name); session.stop() }
        .onChange(of: world.placed) { placed in session.setPaused(!placed || showMenu) }
        .onChange(of: session.running) { running in if running && !world.placed { session.setPaused(true) } }
        .onChange(of: scenePhase) { phase in
            if phase != .active { session.setPaused(true); showMenu = true }
        }
        .onChange(of: world.interrupted) { interrupted in
            if interrupted { session.setPaused(true); showMenu = true }
        }
        .alert("AR-MAME", isPresented: Binding(get: { session.error != nil }, set: { if !$0 { session.error = nil } })) {
            Button("OK") { session.error = nil }
        } message: { Text(session.error ?? "") }
        .sheet(isPresented: Binding(get: { world.screenshot != nil }, set: { if !$0 { world.screenshot = nil } })) {
            if let image = world.screenshot { ShareImage(image: image) }
        }
    }
    private var pausePanel: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text("WORLD PAUSED").font(.caption.bold()).tracking(3)
                    Spacer()
                    Button("Resume") { showMenu = false; session.setPaused(!world.placed) }.buttonStyle(.borderedProminent).tint(.mint)
                }
                Text(session.game.title).font(.title2.bold())
                Picker("AR Mode", selection: Binding(get: { world.mode }, set: { world.changeMode($0) })) {
                    ForEach(ARMode.allCases) { Text($0.rawValue).tag($0) }
                }.pickerStyle(.segmented)
                Text("World width: \(world.width, specifier: "%.2f") meters").font(.headline)
                Slider(value: $world.width, in: 0.1...100)
                HStack {
                    ForEach([0.2,0.6,1,5,10,25,50,100], id: \.self) { size in
                        Button(size < 1 ? "\(size, specifier: "%.1f")" : "\(Int(size))") { world.width = size }.font(.caption)
                    }
                }
                HStack {
                    Text("Custom meters")
                    TextField("Meters", value: $world.width, format: .number).keyboardType(.decimalPad).textFieldStyle(.roundedBorder)
                        .onSubmit { world.width = SpatialMath.clampedWidth(world.width) }
                }
                Text("Rotate world").font(.caption)
                Slider(value: $world.angle, in: -.pi ... .pi)
                Button("Reposition / Recenter World") { world.reposition(); showMenu = false }
                Picker("Rendering", selection: $world.renderMode) {
                    if session.game.hasHardwareProfile { Text(RenderMode.hardware.rawValue).tag(RenderMode.hardware) }
                    Text(RenderMode.generic.rawValue).tag(RenderMode.generic)
                    Text(RenderMode.original.rawValue).tag(RenderMode.original)
                }
                Picker("Occlusion", selection: $world.occlusion) {
                    ForEach(OcclusionMode.allCases) { Text($0.rawValue).tag($0) }
                }
                Text("LiDAR mesh coverage is limited; outdoor buildings may not occlude accurately. Local tracking can drift across large distances.").font(.caption).foregroundStyle(.secondary)
                Text("Rendering range: \(Int(world.range)) m").font(.caption)
                Slider(value: $world.range, in: 10...250)
                Divider()
                Toggle("Edit control positions", isOn: $editing)
                if editing { Text("Resume, then drag controls. Open this menu again to finish.").font(.caption) }
                Toggle("Left-handed layout", isOn: $preferences.leftHanded)
                Toggle("Haptics", isOn: $preferences.haptics)
                Text("Control opacity").font(.caption); Slider(value: $preferences.opacity, in: 0.1...0.8)
                Text("Button size").font(.caption); Slider(value: $preferences.buttonSize, in: 40...85)
                Text("Dead zone").font(.caption); Slider(value: $preferences.deadZone, in: 0.05...0.6)
                Text("Joystick sensitivity").font(.caption); Slider(value: $preferences.sensitivity, in: 0.5...2)
                DisclosureGroup("Remap action buttons") {
                    ForEach(session.descriptors.filter { $0.port == 0 && ![2,3,4,5,6,7].contains($0.code) }) { item in
                        Picker(item.label, selection: Binding(get: { preferences.remaps[item.id] ?? item.code },
                            set: { preferences.remaps[item.id] = $0 })) {
                            ForEach(session.descriptors.filter { $0.port == 0 && ![2,3,4,5,6,7].contains($0.code) }) { target in
                                Text(target.label).tag(target.code)
                            }
                        }
                    }
                }
                Button("Restore Automatic Layout") { preferences = .init(); preferences.save(game: session.game.name) }
                Text("Volume").font(.caption); Slider(value: $volume, in: 0...1).onChange(of: volume) { session.volume(Float($0)) }
                HStack { Button("Save State") { session.save() }; Spacer(); Button("Load State") { session.load() } }
                Button("Reset Machine", role: .destructive) { session.reset() }
                Button("Hide Controls") { hidden = true; showMenu = false; session.setPaused(!world.placed) }
                Button("Screenshot / Share Without Controls") { world.capture() }
                Text("Input layouts come from MAME machine definitions and live libretro descriptors. Specialty analog/twin-stick touch controls and touch multiplayer are not yet implemented. Bluetooth controllers supported.").font(.caption).foregroundStyle(.secondary)
                Button("Exit Game", role: .destructive) { dismiss() }
            }.padding(22)
        }
        .frame(maxWidth: 520, maxHeight: 650)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
        .padding(16)
        .onDisappear { preferences.save(game: session.game.name) }
    }
}

private struct ShareImage: UIViewControllerRepresentable {
    let image: UIImage
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [image], applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
