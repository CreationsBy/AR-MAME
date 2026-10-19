# Compatibility and milestone status

No ROM gameplay or physical iPhone AR validation has been performed by this workspace. A build artifact proves compilation and packaging only. Tests using synthetic frames or machine metadata do not prove a game runs.

| Area | Present implementation | Remaining validation/work |
| --- | --- | --- |
| Genuine emulation | Pinned MAME 2003-Plus, ARM64 native host | Successful cloud compile and original ROM gameplay on iPhone |
| ROM import | ZIP files and folder trees, DAT dependency filenames | Core audit/error behavior, large transfers, merged/clone arrangements |
| 7z | Explicitly rejected with conversion instructions | Core/archive adapter supporting 7z |
| CHD/BIOS | Preserved directory trees, core reader | Version-specific CHDs and machine dependency testing |
| Digital controls | Machine definitions + live descriptors, four/eight-way, customization | Per-game ergonomics and device multitouch |
| Specialty controls | Analog requirement detected; limitations shown | Spinner, trackball, lightgun, steering, pedals, twin-stick, touch multiplayer |
| Full-screen camera | Edge-to-edge native AR camera view | Physical orientation, safe areas, interruption and rotation tests |
| Hardware 3D | Pac-Man / Puck Man read-only tile and sprite extraction, cached real meshes | Visual parity, palette, transform, sprite priorities, cocktail flip, tunnel copies |
| Generic 3D | Bounded color-component extrusion | Semantic object identification, temporal tracking, performance |
| Other games | Original flat fallback available | Verified genre/hardware reconstruction profiles |
| Indoor/outdoor | Surface anchors, confirmation, width/rotation/reposition | Physical device measurements and long-distance drift |
| Occlusion | Optional local LiDAR depth-only mesh | Real device support and outdoor mesh accuracy |
| Optimization | Cached/shared meshes, distance culling, bounded update queue | LOD, streaming, floating origin, instancing, adaptive quality |
| Audio/states | Core sample-rate playback and serialize/unserialize | Per-machine timing, audio interruptions, reliable state restoration |
| IPA | macOS CI build and unsigned package scripts | Successful run, Windows re-sign/install, phone launch |

Game expectations are source-level intentions only:

| Set | Expected digital input | 3D status |
| --- | --- | --- |
| armtest | Four-way, original emulated input diagnostic | Experimental hardware profile; no commercial ROMs |
| pacman / puckman | Four-way + Coin + Start | Experimental hardware profile |
| sf2 | Eight-way, core-labeled six actions | Generic experiment / flat fallback |
| mslug | Eight-way, core-labeled actions | Generic experiment / flat fallback |
| galaga / dkong | Driver-reported digital controls | Generic experiment / flat fallback |
| centiped / arkanoid / outrun | Analog requirements detected | Specialty touchscreen controls unfinished |

No claim is made that every machine in the generated catalog boots or performs adequately on iOS. Parent/BIOS preflight detects filenames, not ROM hashes or correct merged contents. Core errors are authoritative. Save states are bound to the exact core revision and machine; the API can report success without guaranteeing the machine's state is reliable.
