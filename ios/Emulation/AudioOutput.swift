import AVFoundation

/// Bounded audio scheduling; emulation cadence always comes from the core's reported FPS.
final class AudioOutput {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var format: AVAudioFormat?
    private let lock = NSLock()
    private var pending = 0
    private var generation = 0
    init() { engine.attach(player) }
    func start(rate: Double) throws {
        stop()
        try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try AVAudioSession.sharedInstance().setActive(true)
        guard let format = AVAudioFormat(standardFormatWithSampleRate: rate, channels: 2) else { return }
        self.format = format
        engine.connect(player, to: engine.mainMixerNode, format: format)
        try engine.start(); player.play()
    }
    func append(_ data: Data) {
        guard let format, engine.isRunning else { return }
        lock.lock()
        guard pending < 6 else { lock.unlock(); return }
        pending += 1; let token = generation; lock.unlock()
        let count = data.count / 4
        guard count > 0, let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(count)),
              let channels = buffer.floatChannelData else { complete(token); return }
        buffer.frameLength = AVAudioFrameCount(count)
        data.withUnsafeBytes { raw in
            let samples = raw.bindMemory(to: Int16.self)
            for i in 0..<count { channels[0][i] = Float(samples[i*2]) / 32768; channels[1][i] = Float(samples[i*2+1]) / 32768 }
        }
        player.scheduleBuffer(buffer, completionCallbackType: .dataPlayedBack) { [weak self] _ in self?.complete(token) }
    }
    private func complete(_ token: Int) {
        lock.lock(); defer { lock.unlock() }
        if generation == token { pending = max(0, pending - 1) }
    }
    func stop() {
        player.stop(); engine.stop()
        lock.lock(); generation += 1; pending = 0; lock.unlock()
    }
    func setVolume(_ volume: Float) { player.volume = volume }
}
