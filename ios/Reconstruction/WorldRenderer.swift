import SceneKit
import UIKit

final class WorldRenderer {
    let root = SCNNode()
    private let content = SCNNode()
    private var objects: [Int: SCNNode] = [:]
    private var signatures: [Int: GeometryKey] = [:]
    private var geometryCache: [GeometryKey: SCNGeometry] = [:]
    private var fallback: SCNNode?
    private var previousMode: RenderMode?
    private struct GeometryKey: Hashable {
        var pixels: [UInt32]
        var width: Int
        var height: Int
        var sprite: Bool
    }
    init() { root.addChildNode(content) }
    func setTransform(width: Double, angle: Double, opacity: Double) {
        let scale = Float(SpatialMath.clampedWidth(width))
        root.simdScale = SIMD3(repeating: scale)
        root.eulerAngles.y = Float(angle)
        root.opacity = opacity
    }
    func update(_ frame: EmulatedFrame, mode: RenderMode, range: Double, camera: SCNVector3?) {
        if previousMode != mode {
            content.childNodes.forEach { $0.removeFromParentNode() }
            objects.removeAll(); signatures.removeAll(); geometryCache.removeAll(); fallback = nil
            previousMode = mode
        }
        switch mode {
        case .hardware: updateHardware(frame.objects)
        case .generic: updateGeneric(frame.image)
        case .original: updateOriginal(frame.image)
        }
        if let camera {
            for node in content.childNodes {
                let position = node.presentation.worldPosition
                let distance = hypot(hypot(Double(position.x-camera.x), Double(position.z-camera.z)), Double(position.y-camera.y))
                node.isHidden = distance > range
            }
        }
    }
    private func updateHardware(_ values: [VisualObject]) {
        var live = Set<Int>()
        for value in values {
            live.insert(value.id)
            let key = GeometryKey(pixels: value.pixels, width: value.width, height: value.height, sprite: value.sprite)
            let node = objects[value.id] ?? SCNNode()
            if node.parent == nil { content.addChildNode(node); objects[value.id] = node }
            if signatures[value.id] != key {
                if geometryCache.count > 2048 { geometryCache.removeAll() }
                if geometryCache[key] == nil { geometryCache[key] = makeGeometry(key) }
                node.geometry = geometryCache[key]; signatures[value.id] = key
            }
            let point = SpatialMath.pacmanPoint(x: Float(value.x), y: Float(value.y))
            node.position = SCNVector3(point.x, value.sprite ? 0.012 : 0, point.z)
            // Hardware coordinates can contain hidden/offscreen sprites.
            node.opacity = value.sprite && (value.x < 0 || value.x > 272 || value.y < 0 || value.y > 208) ? 0 : 1
        }
        for id in Set(objects.keys).subtracting(live) {
            objects.removeValue(forKey: id)?.removeFromParentNode(); signatures.removeValue(forKey: id)
        }
    }
    private func makeGeometry(_ key: GeometryKey) -> SCNGeometry {
        let group = SCNNode()
        let runs = SpatialMath.runs(pixels: key.pixels, width: key.width, height: key.height, stride: 16)
        var materials: [UInt32: SCNMaterial] = [:]
        for run in runs {
            let color = run.rgba
            let r = CGFloat(color & 255) / 255, g = CGFloat((color >> 8) & 255) / 255, b = CGFloat((color >> 16) & 255) / 255
            let isWall = !key.sprite && b > 0.35 && b > r * 1.25 && b > g * 1.15
            let height: CGFloat = key.sprite ? 0.028 : isWall ? 0.04 : 0.006
            let box = SCNBox(width: 1/224, height: height, length: CGFloat(run.length)/224, chamferRadius: 0)
            if materials[color] == nil {
                let material = SCNMaterial()
                material.diffuse.contents = UIColor(red: r, green: g, blue: b, alpha: 1)
                material.roughness.contents = 0.8; material.lightingModel = .physicallyBased
                materials[color] = material
            }
            box.materials = [materials[color]!]
            let node = SCNNode(geometry: box)
            node.position = SCNVector3((Float(run.y)+0.5)/224, Float(height)/2, -(Float(run.x)+Float(run.length)/2)/224)
            group.addChildNode(node)
        }
        return group.flattenedClone().geometry ?? SCNGeometry()
    }
    private func updateOriginal(_ image: UIImage?) {
        guard let image else { return }
        if fallback == nil {
            let plane = SCNPlane(width: 1, height: image.size.height / image.size.width)
            let material = SCNMaterial(); material.isDoubleSided = true; material.lightingModel = .constant
            material.diffuse.magnificationFilter = .nearest; plane.materials = [material]
            let node = SCNNode(geometry: plane); node.eulerAngles.x = -.pi / 2
            node.position.y = 0.002; content.addChildNode(node); fallback = node
        }
        fallback?.geometry?.firstMaterial?.diffuse.contents = image
    }
    private func updateGeneric(_ image: UIImage?) {
        guard let cg = image?.cgImage else { return }
        let width = 112, height = max(1, Int(Double(cg.height) / Double(cg.width) * 112))
        var pixels = [UInt32](repeating: 0, count: width * height)
        let drew = pixels.withUnsafeMutableBytes { raw -> Bool in
            guard let context = CGContext(data: raw.baseAddress, width: width, height: height, bitsPerComponent: 8,
                bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue) else { return false }
            context.interpolationQuality = .none; context.draw(cg, in: CGRect(x: 0, y: 0, width: width, height: height)); return true
        }
        guard drew else { return }
        let components = Segmentation.components(pixels: pixels, width: width, height: height, limit: 96)
        // These are color components, not verified semantic game objects. A bounded view of the current frame only.
        content.childNodes.forEach { $0.removeFromParentNode() }
        for component in components {
            guard let first = component.first else { continue }
            let minX = component.map { $0 % width }.min()!, maxX = component.map { $0 % width }.max()!
            let minY = component.map { $0 / width }.min()!, maxY = component.map { $0 / width }.max()!
            let shape = UIBezierPath()
            let members = Set(component)
            for y in minY...maxY {
                var x = minX
                while x <= maxX {
                    if !members.contains(y * width + x) { x += 1; continue }
                    let start = x; x += 1
                    while x <= maxX && members.contains(y * width + x) { x += 1 }
                    shape.append(UIBezierPath(rect: CGRect(x: Double(start-minX)/112, y: Double(maxY-y)/112,
                                                          width: Double(x-start)/112, height: 1/112)))
                }
            }
            let geometry = SCNShape(path: shape, extrusionDepth: 0.015)
            let color = pixels[first]
            let material = SCNMaterial()
            material.diffuse.contents = UIColor(red: CGFloat(color & 255)/255, green: CGFloat((color >> 8)&255)/255,
                blue: CGFloat((color >> 16)&255)/255, alpha: 1)
            geometry.materials = [material]
            let node = SCNNode(geometry: geometry)
            node.eulerAngles.x = -.pi / 2
            node.position = SCNVector3(Float(minX)/112 - 0.5, 0.01, Float(maxY)/112 - Float(height)/224)
            content.addChildNode(node)
        }
    }
}
