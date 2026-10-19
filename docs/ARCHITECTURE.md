# Runtime and extension points

The original ROM executes only in the pinned MAME core. The frontend does not simulate Pac-Man or replace its collision, score, AI, physics, or timing. Reconstructed objects are read-only visual interpretations of actual graphics hardware state.

## Emulation ownership

`EmulationSession` owns one serial DispatchQueue. Core load/run/input/reset/serialization/unload happen on that queue. A timer uses the core-reported FPS, independently of AR display cadence. Rendering receives immutable graphics snapshots at roughly half that cadence; at most one frame update awaits presentation. No multiple concurrent `retro_run` calls or deliberate catch-up bursts occur. Slow devices can still run below game speed; there is no claim of universal full-speed emulation.

The libretro bridge implements system/save/content paths, log callbacks, v0 core options, pixel formats, original video, audio batches, input descriptors, and core state serialization. Unsupported environment requests return false. Rotation is delegated back to MAME for the flat framebuffer; the Pac-Man hardware profile applies its own explicit native-coordinate transform.

Digital touch and external-controller sources are combined before delivery, so lifting one source cannot release a button still held by another. Pause, disconnect, backgrounding, and exit release input. Audio uses bounded AVAudioPlayerNode scheduling and the original reported sample rate. Route-change recovery and underrun/overrun instrumentation still need device validation.

## Spatial interpretation

For the scoped Pac-Man sets, `ARCore.c` reads the driver's tilemap mapping, generic sprite RAM, decoded gfx planes, and palette. Each tile/sprite has a stable ID. The renderer builds cached geometry from contiguous runs of equal-color opaque pixels. Blue-dominant tile runs become tall walls; other tile content is shallow; sprite content becomes separate animated extruded objects. This classification is experimental and can misclassify text.

`scripts/make_diagnostic.py` also generates an original Z80 program, board, and solid-color glyphs. The build registers a separate `armtest` machine on this hardware using ROM_FILL entries. The diagnostic moves a yellow sprite by reading the actual emulated input port. Its ZIP is only an original description container, with no required commercial ROM members. This provides a ROM-free test of CPU execution, controls, video/audio callbacks, state restore, and hardware extraction; it is not a substitute for testing original games. The frontend bypasses MAME's blocking flat startup panels so they cannot invisibly block hardware AR presentation; ROM audit/load failures still propagate.

The 288x224 native hardware coordinates map into a horizontal normalized world:

```text
world.x = (native.y - 112) / 224
world.z = (144 - native.x) / 224
world.y = reconstructed object elevation
AR transform = surface anchor * visual rotation * selected width in meters
```

Changing visual width never modifies a CPU value, collision coordinate, or input interval. The upright board is one normalized unit wide, so 25m means 25 meters across its width (its length is proportionately larger). Scale is clamped to 0.1–250m to bound this prototype's local scene; drift remains possible.

Generic reconstruction quantizes colors and finds connected components in a downsampled current frame. Components become separate extruded paths. This is a bounded heuristic, without reliable semantic recognition, persistent actor tracking, hidden level discovery, or verified animation correspondence. Its mesh regeneration is expensive; use the hardware profile or original fallback for performance.

## AR and camera

The camera view is the root background and ignores all safe-area insets. Only overlays honor safe areas. Game aspect ratio affects reconstructed content, never camera view dimensions. Menus overlay the existing live camera. Screenshots capture the ARSCNView alone, excluding SwiftUI controls.

Placement requires a detected horizontal surface and normal tracking. An ARAnchor owns the world transform. Mode changes remove placement, pause gameplay, set an appropriate visual width, and require a fresh tap while preserving core progress. No GPS placement or walking requirement is introduced.

LiDAR mesh occlusion uses the reconstructed local mesh as a depth-only SceneKit geometry. Standard and always-visible currently both omit real-world occlusion; reduced-opacity changes virtual content alpha. Mesh coverage and outdoor accuracy depend on the device and surroundings. This does not reconstruct entire buildings or provide unlimited alignment.

Distance culling, a bounded geometry cache, shared geometry, and an adjustable far plane are implemented. Explicit GPU instancing, scene streaming, floating origin, LOD, and adaptive quality are future work. Large widths alone do not provide those optimizations.

## Adding a profile/core

Add and validate a read-only graphics adapter for its exact machine/hardware, then register a scoped profile and renderer. Never apply the Pac-Man RAM layout to a different machine. Profile metadata must record bounds, orientation, interpretation, scale, and limitations. Additional genres have no verified profiles yet.

To replace the emulator, update its lock, build adapter, core-specific options, graphics adapters, generated dependency catalog, ROM compatibility matrix, and licenses together. A current MAME core is a separate integration effort, especially for iOS performance and restricted JIT.
