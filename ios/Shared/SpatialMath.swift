import Foundation

struct PixelRun: Equatable {
    var x: Int
    var y: Int
    var length: Int
    var rgba: UInt32
}

enum SpatialMath {
    /// A normalized native Pac-Man hardware plane (288 x 224), rotated to upright 224 x 288.
    static func pacmanPoint(x: Float, y: Float) -> (x: Float, z: Float) {
        ((y - 112) / 224, (144 - x) / 224)
    }

    static func clampedWidth(_ value: Double) -> Double {
        value.isFinite ? min(250, max(0.1, value)) : 0.6
    }

    static func directions(x: Double, y: Double, fourWay: Bool, deadZone: Double) -> Set<UInt32> {
        var result = Set<UInt32>()
        let dx = abs(x) >= deadZone ? x : 0
        let dy = abs(y) >= deadZone ? y : 0
        if dx != 0 && (!fourWay || abs(dx) > abs(dy)) { result.insert(dx < 0 ? 6 : 7) }
        if dy != 0 && (!fourWay || abs(dy) >= abs(dx)) { result.insert(dy < 0 ? 4 : 5) }
        return result
    }

    static func runs(pixels: [UInt32], width: Int, height: Int, stride: Int) -> [PixelRun] {
        guard width > 0, height > 0, stride >= width, pixels.count >= stride * height else { return [] }
        var result: [PixelRun] = []
        for y in 0..<height {
            var x = 0
            while x < width {
                let color = pixels[y * stride + x]
                let start = x
                x += 1
                while x < width && pixels[y * stride + x] == color { x += 1 }
                if color >> 24 != 0 { result.append(.init(x: start, y: y, length: x - start, rgba: color)) }
            }
        }
        return result
    }
}

/// Bounded connected-component analysis for the explicitly experimental framebuffer path.
enum Segmentation {
    static func components(pixels: [UInt32], width: Int, height: Int, limit: Int = 128) -> [[Int]] {
        guard width > 0, height > 0, pixels.count == width * height else { return [] }
        var visited = [Bool](repeating: false, count: pixels.count)
        var result: [[Int]] = []
        func key(_ color: UInt32) -> UInt32 {
            // Quantized color separates touching foreground objects when possible.
            color & 0x00E0E0E0
        }
        for seed in pixels.indices where !visited[seed] {
            visited[seed] = true
            let color = key(pixels[seed])
            if color == 0 || pixels[seed] >> 24 == 0 { continue }
            var queue = [seed]
            var head = 0
            while head < queue.count {
                let point = queue[head]; head += 1
                let x = point % width, y = point / width
                let neighbors = [(x-1,y), (x+1,y), (x,y-1), (x,y+1)]
                for (nx,ny) in neighbors where nx >= 0 && nx < width && ny >= 0 && ny < height {
                    let next = ny * width + nx
                    if !visited[next] && key(pixels[next]) == color {
                        visited[next] = true; queue.append(next)
                    }
                }
            }
            if queue.count >= 2 { result.append(queue) }
        }
        return Array(result.sorted { $0.count > $1.count }.prefix(max(0, limit)))
    }
}
