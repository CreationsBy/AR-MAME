# AR-MAME

A native iOS arcade emulator and experimental spatial renderer, developed from Windows and built on GitHub's macOS runners. Source repository: https://github.com/CreationsBy/AR-MAME.

**Status: initial implementation, not a validated universal 3D emulator.** The ARM64 iOS build, logic tests, native input metadata checks, and original Z80 runtime diagnostic have passed in [GitHub Actions](https://github.com/CreationsBy/AR-MAME/actions/runs/39341218165). An unsigned IPA was produced and inspected. Commercial ROM gameplay, audio accuracy, signing, and physical iPhone AR remain untested. No commercial ROMs are included. See [verified results and download](docs/VALIDATION.md).

## Start from Windows

1. Install Git, Python 3.10+, and VS Code. Clone `https://github.com/CreationsBy/AR-MAME.git` and open the folder in VS Code.
2. Run `python -m unittest discover -s tests -p 'test_*.py' -v` or the **Validate tooling** VS Code task.
3. Commit and push changes to `main`, or open **GitHub > Actions > iOS IPA > Run workflow**. GitHub performs all native compilation remotely; local Xcode and a local macOS VM are unnecessary.
4. Download **ARMAME-unsigned** from the successful run's artifacts, then extract `ARMAME-unsigned.ipa` from that artifact ZIP.
5. Follow [Windows signing and sideloading](docs/WINDOWS-SIDELOADING.md). An unsigned IPA cannot be installed directly.

## Implemented source paths

- Genuine ARM64 MAME 2003-Plus integration through the libretro ABI, locked in `mame/core.lock.json`. No JIT entitlement or downloaded executable cores.
- Files import of ZIP sets and ROM-root folders, preserving machine CHD subdirectories. Dependency filename preflight from the pinned core DAT; MAME remains responsible for content auditing.
- Real machine input-port inspection and live libretro descriptors for digital touchscreen layouts, four/eight-way input, coin/start, remapping, per-game positioning/size/opacity, and Bluetooth gamepads.
- Original audio playback, pause, reset, and save/load via the core serialization API where supported.
- Full-screen `ARSCNView` with Metal, camera behind safe-area-aware transparent controls, surface raycasts, actual AR anchors, and explicit placement confirmation.
- Indoor and outdoor visual scaling (0.1–250 meters wide), rotation, rendering-distance culling, repositioning, tracking messages, and optional LiDAR scene-mesh occlusion.
- A read-only hardware graphics adapter for **pacman** and **puckman**: separate tile/sprite identities, decoded original graphics/palette, cached meshes of colored voxel runs, raised walls and animated extruded sprites. Emulation remains authoritative.
- An original generated Z80 diagnostic (`armtest`) on the same emulated hardware, available through **Try Original Z80 Diagnostic**. Its board, colored sprite, and input response use the MAME CPU/video/input path; it contains no commercial ROM data and does not reproduce Pac-Man gameplay.
- Experimental color-component 3D reconstruction for other visible framebuffers, and a clearly labeled original flat fallback. Neither path can recover hidden levels automatically.
- Cloud build of the actual core, XcodeGen native app project, unsigned IPA packaging, native metadata checks, Swift logic tests, and Python tooling tests.

## Important boundaries

This is a development prototype. **7z is not supported** by this pinned core frontend: convert legally obtained sets to ZIP first. CHD versions must match this older core; modern MAME CHDs and sets are not interchangeable. Analog specialty touchscreen controls, twin-stick layouts, touch multiplayer, native polygon extraction, full-stage streaming, explicit GPU instancing, floating-origin rendering, adaptive quality/LOD, and machine settings UI remain unfinished. Pac-Man cockpit flipping, tunnel wrap copies, and all sprite priority edge cases require further work.

Use [compatibility and milestone status](docs/COMPATIBILITY.md) to distinguish code from validated functionality. The complete original specification is a product roadmap, not a claim that all its features are complete.

## Development structure

```text
ios/App, UI, GameLibrary       SwiftUI library and in-camera menus
ios/Bridge, Emulation         libretro host, serialized core queue, bounded audio
ios/Controls                  touchscreen layout and external controllers
ios/AR                        full-screen camera, planes, anchors, mesh occlusion
ios/Reconstruction, Shared    cached object meshes, segmentation, transforms
mame                          locked upstream revision and C graphics/input adapter
reconstruction/profiles       scoped game reconstruction profile metadata
scripts                       core fetch/build, catalog generation, IPA packaging
tests                         logic, packaging, dependency metadata checks
.github/workflows             remote native build and validation
```

Read [architecture](docs/ARCHITECTURE.md), [device testing](docs/DEVICE-TESTING.md), and [license obligations](docs/LICENSING.md) before extending or redistributing the project. The full requested roadmap is retained in [the original product specification](docs/PRODUCT-SPEC.md).

## Sources

- [MAME 2003-Plus upstream](https://github.com/libretro/mame2003-plus-libretro): pinned implementation, driver/input definitions, DAT, and license.
- [Libretro API](https://docs.libretro.com/development/cores/developing-cores/): callback contract for emulation, input, video, audio, and serialization.
- [Apple ARSCNView](https://developer.apple.com/documentation/arkit/arscnview): native camera passthrough and spatial SceneKit rendering.
- [3dSen / Geod Studio](https://geodstudio.net/): visual inspiration only; no 3dSen code, profiles, assets, or proprietary methods are included.
