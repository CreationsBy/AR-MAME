import SwiftUI

struct TouchControls: View {
    @ObservedObject var session: EmulationSession
    @Binding var preferences: ControlPreferences
    var editing: Bool
    private var actions: [ControlDescriptor] {
        session.descriptors.filter { $0.port == 0 && $0.device == 1 && ![2,3,4,5,6,7].contains($0.code) }
    }
    var body: some View {
        HStack(alignment: .bottom, spacing: 20) {
            if !preferences.leftHanded { joystick }
            Spacer(minLength: 0)
            VStack(spacing: 12) {
                HStack {
                    control(label: "COIN", code: 2, id: "coin")
                    control(label: "START", code: 3, id: "start")
                }
                LazyVGrid(columns: [GridItem(.adaptive(minimum: preferences.buttonSize))], spacing: 12) {
                    ForEach(actions) { item in
                        control(label: item.label, code: preferences.remaps[item.id] ?? item.code, id: item.id)
                    }
                }
                .frame(maxWidth: preferences.buttonSize * 3 + 30)
            }
            if preferences.leftHanded { Spacer(minLength: 0); joystick }
        }
        .padding(.horizontal, 18).padding(.bottom, 12)
        .onDisappear { session.releaseInputs() }
    }
    private var joystick: some View {
        JoystickView(fourWay: (session.machine["fourWay"] as? NSNumber)?.boolValue ?? false,
            opacity: preferences.opacity, deadZone: preferences.deadZone, sensitivity: preferences.sensitivity) { codes in
            if !editing { session.digital(source: "joystick", codes: codes) }
        }
        .frame(width: 132, height: 132)
        .modifier(MovableControl(id: "joystick", preferences: $preferences, editing: editing))
    }
    private func control(label: String, code: UInt32, id: String) -> some View {
        Text(label.uppercased())
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .lineLimit(2).minimumScaleFactor(0.65)
            .frame(width: preferences.buttonSize, height: preferences.buttonSize)
            .foregroundStyle(.white)
            .background(.black.opacity(preferences.opacity), in: Circle())
            .overlay(Circle().stroke(.white.opacity(0.65), lineWidth: 1))
            .contentShape(Circle())
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard !editing else { return }
                    session.digital(source: id, codes: [code])
                }
                .onEnded { _ in
                    session.digital(source: id, codes: [])
                    if preferences.haptics { UIImpactFeedbackGenerator(style: .soft).impactOccurred() }
                }, including: editing ? .none : .all)
            .modifier(MovableControl(id: id, preferences: $preferences, editing: editing))
            .accessibilityLabel(label)
    }
}

private struct MovableControl: ViewModifier {
    let id: String
    @Binding var preferences: ControlPreferences
    var editing: Bool
    @GestureState private var translation = CGSize.zero
    func body(content: Content) -> some View {
        let offset = preferences.offsets[id] ?? [0,0]
        content
            .offset(x: offset[0] + translation.width, y: offset[1] + translation.height)
            .overlay { if editing { RoundedRectangle(cornerRadius: 10).stroke(.mint, style: StrokeStyle(lineWidth: 2, dash: [4])) } }
            .simultaneousGesture(DragGesture()
                .updating($translation) { value, state, _ in if editing { state = value.translation } }
                .onEnded { value in
                    if editing { preferences.offsets[id] = [offset[0]+value.translation.width, offset[1]+value.translation.height] }
                }, including: editing ? .all : .none)
    }
}

private struct JoystickView: View {
    let fourWay: Bool
    let opacity: Double, deadZone: Double, sensitivity: Double
    var changed: (Set<UInt32>) -> Void
    @State private var point = CGSize.zero
    var body: some View {
        ZStack {
            Circle().fill(.black.opacity(opacity))
            Circle().stroke(.white.opacity(0.55), lineWidth: 1)
            Image(systemName: "plus").font(.system(size: 62, weight: .ultraLight)).foregroundStyle(.white.opacity(0.4))
            Circle().fill(.white.opacity(0.45)).frame(width: 48, height: 48).offset(point)
        }
        .contentShape(Circle())
        .gesture(DragGesture(minimumDistance: 0)
            .onChanged { value in
                let x = max(-1, min(1, (value.location.x-66)/48 * sensitivity))
                let y = max(-1, min(1, (value.location.y-66)/48 * sensitivity))
                point = CGSize(width: x*35, height: y*35)
                changed(SpatialMath.directions(x: x, y: y, fourWay: fourWay, deadZone: deadZone))
            }
            .onEnded { _ in point = .zero; changed([]) })
        .accessibilityLabel(fourWay ? "Four-way joystick" : "Eight-way joystick")
    }
}
