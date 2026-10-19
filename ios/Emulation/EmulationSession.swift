import Foundation
import UIKit
import GameController

struct VisualObject {
    let id: Int, x: Int, y: Int, width: Int, height: Int
    let sprite: Bool
    let pixels: [UInt32]
    init?(_ raw: [String: Any]) {
        guard let id = raw["id"] as? Int, let x = raw["x"] as? Int, let y = raw["y"] as? Int,
              let width = raw["width"] as? Int, let height = raw["height"] as? Int,
              let sprite = raw["sprite"] as? NSNumber, let data = raw["pixels"] as? Data else { return nil }
        self.id = id; self.x = x; self.y = y; self.width = width; self.height = height
        self.sprite = sprite.boolValue
        pixels = data.withUnsafeBytes { Array($0.bindMemory(to: UInt32.self)) }
    }
}
struct EmulatedFrame {
    var image: UIImage?
    var objects: [VisualObject]
}

final class EmulationSession: ObservableObject {
    @Published var running = false
    @Published var paused = false
    @Published var error: String?
    @Published var descriptors: [ControlDescriptor] = []
    @Published var machine: [String: Any] = [:]
    @Published var frame = EmulatedFrame(image: nil, objects: [])
    let game: LibraryGame
    private let core = EmulatorBridge()
    private let queue = DispatchQueue(label: "AR-MAME.emulation", qos: .userInteractive)
    private let audio = AudioOutput()
    private var timer: DispatchSourceTimer?
    private var frameNumber = 0
    private var presenting = false
    private var generation = 0
    private var inputs: [String: Set<UInt32>] = [:]
    private var controllerObserver: NSObjectProtocol?
    private var controllerDisconnectObserver: NSObjectProtocol?
    private var saveURL: URL
    private let systemURL: URL
    private let savesURL: URL
    init(game: LibraryGame, library: ROMLibrary) {
        self.game = game; systemURL = library.system; savesURL = library.saves
        saveURL = library.saves.appendingPathComponent(game.name + ".state")
    }
    func start() {
        guard !running else { return }
        let path = game.url.path, system = systemURL.path, saves = savesURL.path
        let token = generation
        queue.async { [self] in
            let info = core.machine(game.name)
            let ok = core.loadROM(path, systemDirectory: system, saveDirectory: saves)
            let fps = core.framesPerSecond, rate = core.sampleRate
            let message = core.lastMessage
            let controls = core.inputDescriptors().compactMap(ControlDescriptor.init)
            DispatchQueue.main.async { [self] in
                guard generation == token else { return }
                machine = info; descriptors = controls
                guard ok, fps.isFinite, fps > 0, rate > 0 else {
                    error = message.isEmpty ? "MAME could not load this set. Check the ROM version, BIOS, parent sets, and CHDs." : message
                    return
                }
                do { try audio.start(rate: rate) } catch { self.error = "Audio unavailable: \(error.localizedDescription)" }
                core.audioHandler = { [weak audio] samples in audio?.append(samples) }
                running = true; paused = false
                installController(); schedule(fps: fps)
            }
        }
    }
    private func schedule(fps: Double) {
        let token = generation
        let clock = DispatchSource.makeTimerSource(queue: queue)
        clock.schedule(deadline: .now(), repeating: 1 / fps, leeway: .microseconds(300))
        clock.setEventHandler { [weak self] in
            guard let self else { return }
            self.core.runFrame(); self.frameNumber += 1
            // At most one presentation update may await the main thread. No catch-up burst.
            guard !self.presenting, self.frameNumber % 2 == 0 else { return }
            self.presenting = true
            let value = EmulatedFrame(image: self.core.frameImage(), objects: self.core.visualObjects().compactMap(VisualObject.init))
            DispatchQueue.main.async {
                if self.generation == token { self.frame = value }
                self.queue.async { self.presenting = false }
            }
        }
        timer = clock; clock.resume()
    }
    func setPaused(_ value: Bool) {
        guard running, paused != value else { return }
        paused = value; releaseInputs()
        if value {
            timer?.cancel(); timer = nil
            queue.async { [audio] in audio.stop() }
        } else {
            queue.async { [self] in
                do { try audio.start(rate: core.sampleRate) } catch { }
                let fps = core.framesPerSecond
                DispatchQueue.main.async { if self.running && !self.paused { self.schedule(fps: fps) } }
            }
        }
    }
    func stop() {
        generation += 1; running = false; paused = false
        timer?.cancel(); timer = nil; releaseInputs()
        if let controllerObserver { NotificationCenter.default.removeObserver(controllerObserver) }
        if let controllerDisconnectObserver { NotificationCenter.default.removeObserver(controllerDisconnectObserver) }
        for controller in GCController.controllers() { controller.extendedGamepad?.valueChangedHandler = nil }
        queue.async { [core, audio] in core.stop(); audio.stop(); core.audioHandler = nil }
    }
    func digital(source: String, codes: Set<UInt32>) {
        guard running, !paused else { return }
        let previous = inputs.values.reduce(into: Set<UInt32>()) { $0.formUnion($1) }
        inputs[source] = codes
        let next = inputs.values.reduce(into: Set<UInt32>()) { $0.formUnion($1) }
        queue.async { [core] in
            for code in previous.union(next) {
                core.setInputPort(0, device: 1, index: 0, identifier: code, value: next.contains(code) ? 1 : 0)
            }
        }
    }
    func releaseInputs() { inputs.removeAll(); queue.async { [core] in core.releaseInputs() } }
    func save() {
        queue.async { [self] in
            do {
                guard let state = core.saveState() else { throw LibraryError.detail("This machine cannot serialize a state.") }
                try state.write(to: saveURL, options: .atomic)
                DispatchQueue.main.async { self.error = "Save state written. Machine reliability still requires testing." }
            } catch { DispatchQueue.main.async { self.error = error.localizedDescription } }
        }
    }
    func load() {
        releaseInputs()
        queue.async { [self] in
            do {
                let state = try Data(contentsOf: saveURL)
                guard core.restoreState(state) else { throw LibraryError.detail("State rejected by this machine/core revision.") }
                let next = EmulatedFrame(image: core.frameImage(), objects: core.visualObjects().compactMap(VisualObject.init))
                DispatchQueue.main.async { self.frame = next }
            } catch { DispatchQueue.main.async { self.error = error.localizedDescription } }
        }
    }
    func reset() { releaseInputs(); queue.async { [core] in core.reset() } }
    func volume(_ value: Float) { queue.async { [audio] in audio.setVolume(value) } }
    private func installController() {
        func connect(_ controller: GCController) {
            controller.extendedGamepad?.valueChangedHandler = { [weak self] pad, _ in
                var codes = Set<UInt32>()
                let pairs: [(GCControllerButtonInput, UInt32)] = [
                    (pad.dpad.up,4), (pad.dpad.down,5), (pad.dpad.left,6), (pad.dpad.right,7),
                    (pad.buttonA,8), (pad.buttonB,0), (pad.buttonX,9), (pad.buttonY,1),
                    (pad.leftShoulder,10), (pad.rightShoulder,11), (pad.buttonMenu,3)
                ]
                for (button, code) in pairs where button.isPressed { codes.insert(code) }
                if pad.buttonOptions?.isPressed == true { codes.insert(2) }
                codes.formUnion(SpatialMath.directions(x: Double(pad.leftThumbstick.xAxis.value),
                    y: -Double(pad.leftThumbstick.yAxis.value), fourWay: false, deadZone: 0.2))
                Task { @MainActor in
                    guard let self else { return }
                    if (self.machine["fourWay"] as? NSNumber)?.boolValue == true {
                        let directions = codes.intersection([4,5,6,7])
                        if directions.count > 1 {
                            let first = directions.sorted().first!
                            codes.subtract([4,5,6,7]); codes.insert(first)
                        }
                    }
                    self.digital(source: "controller", codes: codes)
                }
            }
        }
        GCController.controllers().forEach(connect)
        controllerObserver = NotificationCenter.default.addObserver(forName: .GCControllerDidConnect, object: nil, queue: .main) { notification in
            if let controller = notification.object as? GCController { connect(controller) }
        }
        controllerDisconnectObserver = NotificationCenter.default.addObserver(forName: .GCControllerDidDisconnect, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.digital(source: "controller", codes: []) }
        }
    }
}
