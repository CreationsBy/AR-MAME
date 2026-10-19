import SwiftUI
import ARKit
import SceneKit

final class ARWorld: ObservableObject {
    @Published var mode: ARMode = .miniature
    @Published var width = 0.6
    @Published var angle = 0.0
    @Published var placed = false
    @Published var tracking = "Scan a textured, well-lit surface."
    @Published var occlusion: OcclusionMode = .standard
    @Published var renderMode: RenderMode = .hardware
    @Published var range = 150.0
    @Published var resetID = UUID()
    @Published var screenshot: UIImage?
    @Published var interrupted = false
    weak var view: ARSCNView?
    func reposition() { placed = false; resetID = UUID() }
    func changeMode(_ mode: ARMode) { self.mode = mode; width = mode.defaultWidth; reposition() }
    func capture() { screenshot = view?.snapshot() }
}

struct FullscreenARView: UIViewRepresentable {
    @ObservedObject var world: ARWorld
    var frame: EmulatedFrame
    func makeCoordinator() -> Coordinator { Coordinator(world: world) }
    func makeUIView(context: Context) -> ARSCNView {
        let view = ARSCNView(frame: .zero, options: [SCNView.Option.preferredRenderingAPI.rawValue: SCNRenderingAPI.metal.rawValue])
        view.scene = SCNScene(); view.automaticallyUpdatesLighting = true
        view.autoenablesDefaultLighting = true; view.preferredFramesPerSecond = 60
        view.isMultipleTouchEnabled = true; view.session.delegate = context.coordinator
        view.session.delegateQueue = .main; view.delegate = context.coordinator
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.place(_:)))
        view.addGestureRecognizer(tap)
        world.view = view; context.coordinator.view = view
        context.coordinator.configure()
        return view
    }
    func updateUIView(_ view: ARSCNView, context: Context) {
        let coordinator = context.coordinator
        if coordinator.resetID != world.resetID {
            coordinator.resetID = world.resetID; coordinator.removePlacement()
        }
        if coordinator.occlusion != world.occlusion { coordinator.configure() }
        coordinator.renderer.setTransform(width: world.width, angle: world.angle,
            opacity: world.occlusion == .translucent ? 0.45 : 1)
        coordinator.renderer.update(frame, mode: world.renderMode, range: world.range, camera: view.pointOfView?.position)
        view.pointOfView?.camera?.zNear = 0.01
        view.pointOfView?.camera?.zFar = max(250, world.range * 2)
        if !world.placed { coordinator.updatePreview() }
    }
    static func dismantleUIView(_ view: ARSCNView, coordinator: Coordinator) {
        view.session.pause(); view.session.delegate = nil; view.delegate = nil
    }
    final class Coordinator: NSObject, ARSessionDelegate, ARSCNViewDelegate {
        let world: ARWorld
        weak var view: ARSCNView?
        let renderer = WorldRenderer()
        var resetID: UUID
        var occlusion: OcclusionMode?
        var anchor: ARAnchor?
        let preview: SCNNode
        init(world: ARWorld) {
            self.world = world; resetID = world.resetID
            let ring = SCNTorus(ringRadius: 0.08, pipeRadius: 0.002)
            ring.firstMaterial?.diffuse.contents = UIColor.systemMint
            preview = SCNNode(geometry: ring)
        }
        func configure() {
            guard let view, ARWorldTrackingConfiguration.isSupported else {
                world.tracking = "AR world tracking is unavailable on this device."; return
            }
            let config = ARWorldTrackingConfiguration()
            config.planeDetection = [.horizontal]; config.isLightEstimationEnabled = true
            let meshSupported = ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)
            if world.occlusion == .depth && meshSupported { config.sceneReconstruction = .mesh }
            if world.occlusion == .depth && !meshSupported { world.tracking = "Scene mesh occlusion requires a supported LiDAR device." }
            occlusion = world.occlusion
            view.session.run(config)
            if preview.parent == nil { view.scene.rootNode.addChildNode(preview) }
        }
        func removePlacement() {
            if let anchor { view?.session.remove(anchor: anchor) }
            anchor = nil; renderer.root.removeFromParentNode(); preview.isHidden = false
        }
        func updatePreview() {
            guard let view, let query = view.raycastQuery(from: CGPoint(x: view.bounds.midX, y: view.bounds.midY),
                allowing: .existingPlaneGeometry, alignment: .horizontal), let hit = view.session.raycast(query).first else {
                preview.isHidden = true; return
            }
            preview.isHidden = false; preview.simdTransform = hit.worldTransform
        }
        @objc func place(_ gesture: UITapGestureRecognizer) {
            guard !world.placed, let view, let state = view.session.currentFrame?.camera.trackingState,
                  case .normal = state,
                  let query = view.raycastQuery(from: gesture.location(in: view), allowing: .existingPlaneGeometry, alignment: .horizontal),
                  let hit = view.session.raycast(query).first else { return }
            removePlacement()
            let anchor = ARAnchor(name: "arcade-world", transform: hit.worldTransform)
            self.anchor = anchor; view.session.add(anchor: anchor)
            world.placed = true; preview.isHidden = true
        }
        func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
            if anchor.identifier == self.anchor?.identifier { node.addChildNode(self.renderer.root) }
            if let mesh = anchor as? ARMeshAnchor { updateMesh(mesh, node: node) }
        }
        func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
            if let mesh = anchor as? ARMeshAnchor { updateMesh(mesh, node: node) }
        }
        private func updateMesh(_ anchor: ARMeshAnchor, node: SCNNode) {
            guard world.occlusion == .depth else { node.geometry = nil; return }
            let mesh = anchor.geometry
            let source = SCNGeometrySource(buffer: mesh.vertices.buffer, vertexFormat: mesh.vertices.format,
                semantic: .vertex, vertexCount: mesh.vertices.count, dataOffset: mesh.vertices.offset, dataStride: mesh.vertices.stride)
            let data = Data(bytes: mesh.faces.buffer.contents(), count: mesh.faces.count * mesh.faces.indexCountPerPrimitive * mesh.faces.bytesPerIndex)
            let element = SCNGeometryElement(data: data, primitiveType: .triangles, primitiveCount: mesh.faces.count, bytesPerIndex: mesh.faces.bytesPerIndex)
            let geometry = SCNGeometry(sources: [source], elements: [element])
            let material = SCNMaterial(); material.colorBufferWriteMask = []
            material.writesToDepthBuffer = true; material.readsFromDepthBuffer = true
            geometry.materials = [material]; node.geometry = geometry; node.renderingOrder = -1
        }
        func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
            switch camera.trackingState {
            case .normal: world.tracking = world.placed ? "World anchored" : "Tap a detected ground or tabletop surface."
            case .notAvailable: world.tracking = "Tracking unavailable. Reposition World after tracking recovers."
            case .limited(let reason):
                world.tracking = "Tracking limited (\(reason)). Hold still, improve lighting, or Recenter World."
            }
        }
        func sessionWasInterrupted(_ session: ARSession) { world.interrupted = true; world.tracking = "AR interrupted. Gameplay paused." }
        func sessionInterruptionEnded(_ session: ARSession) { world.interrupted = false; world.reposition(); configure() }
        func session(_ session: ARSession, didFailWithError error: Error) { world.tracking = error.localizedDescription }
    }
}
