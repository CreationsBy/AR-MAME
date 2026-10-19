# Build a Universal MAME 3D AR Emulator for iOS — Miniature and Giant Outdoor Worlds

## Main Objective

Create a fully functional MAME arcade emulator for iOS that transforms supported arcade ROM games into playable 3D environments using a visual conversion approach inspired by 3dSen.

The application must allow users to import their own MAME ROM files, run the original games through genuine MAME emulation, convert supported 2D arcade graphics into real 3D geometry, and display those environments in augmented reality using the iPhone's camera.

Include two primary AR gameplay experiences:

1. **Indoor Miniature Mode:** Transform the arcade game into a small, playable 3D world placed on a table, desk, or floor.
2. **Outdoor Giant World Mode:** Transform the arcade game into a massive, playable 3D environment that can be larger than my entire house, with virtual structures, characters, and scenery extending across the real outdoor environment.

Both modes must use an actual 3D environment rather than simply displaying a flat game screen.

The entire application must use a full-screen, edge-to-edge camera presentation, with transparent touchscreen controls overlaid on the live camera feed.

The project must be developed using Visual Studio Code on Windows and packaged as an IPA for sideloading onto an iPhone, without requiring me to own a Mac or operate a local macOS virtual machine.

---

## 1. Development Environment and Restrictions

My development setup:

- Windows PC
- Visual Studio Code
- PowerShell / Windows Terminal
- Git and GitHub
- iPhone for testing
- No personal Mac
- No local macOS virtual machine

Keep all local development inside Visual Studio Code.

Use GitHub Actions or another remote macOS build service to compile the native iOS application and export the IPA.

The complete workflow should be:

1. Write and edit code in VS Code on Windows.
2. Commit and push the project to GitHub.
3. Trigger the remote iOS build.
4. Download the resulting IPA file.
5. Sign or re-sign the IPA using an appropriate supported process.
6. Sideload the IPA onto my iPhone using compatible Windows software such as Sideloadly or AltStore.

Include the necessary certificates, provisioning, Developer Mode, and signing instructions.

Do not require local Xcode or a local Mac.

---

## 2. Genuine MAME Emulation

Use a suitable MAME implementation or compatible MAME-based Libretro core.

Support the widest practical range of arcade games while recognizing that not every MAME-supported machine can necessarily run successfully on iOS.

Implement support for compatible:

- ZIP ROM sets
- 7z ROM sets
- CHD files
- BIOS dependencies
- Parent and clone ROMs
- Device ROM dependencies
- Arcade hardware definitions

Allow the user to import their legally obtained ROM files through the iOS Files application.

Automatically identify the game, arcade machine, required dependencies, supported controls, and native screen orientation.

Preserve original gameplay, timing, audio, scoring, physics, input processing, and collision logic.

The emulator must remain the authoritative source of game state.

The 3D conversion system must not replace original gameplay mechanics.

Do not include copyrighted commercial ROMs.

---

## 3. 3dSen-Inspired 3D Reconstruction

Create a custom graphics interpretation and reconstruction engine inspired by 3dSen.

Reference: https://geodstudio.net/

The goal is to convert supported 2D arcade games into fully three-dimensional environments while keeping the original games playable.

Investigate graphics information available from different MAME hardware drivers, including:

- Sprites
- Tile maps
- Background layers
- Foreground layers
- Framebuffer output
- Palette information
- Object positions
- Animation frames
- Scrolling
- Rendering priority
- Hardware graphics data
- Existing polygon geometry where accessible

Use this information to generate:

- 3D voxel characters
- Extruded sprites
- Raised platforms
- Solid walls
- Floors
- Obstacles
- Animated enemies
- Projectiles
- Environmental objects
- 3D scenery
- Recognizable game-specific structures

Do not simply extrude every framebuffer pixel into a single surface.

Separate meaningful objects and assign appropriate depth, thickness, material properties, and animation.

### Game-specific conversion profiles

Create a system of per-game and per-hardware conversion profiles.

Profiles should describe how the original game's graphics are interpreted, how objects are tracked, what shapes they become, and how the resulting 3D scene behaves.

Allow shared graphics rules across related arcade hardware.

For unsupported games, provide experimental generic reconstruction using segmentation, sprite tracking, extrusion, and depth heuristics.

Clearly label experimental and partially supported reconstruction.

Do not claim that every MAME ROM can automatically become a complete, accurate 3D environment.

For games originally rendered using 3D polygons, investigate extracting existing geometry rather than rebuilding it from framebuffer pixels.

---

# 4. Full-Screen Camera Presentation — Mandatory

**This requirement applies to the entire AR gameplay experience.**

The iPhone camera must occupy the entire usable screen.

Do not display the AR camera inside:

- A small rectangular box
- A centered game window
- A bordered preview
- A phone-shaped mockup
- A picture-in-picture panel
- A reduced-size viewport
- A permanently letterboxed gameplay region

The app should look like a real, full-screen mobile augmented-reality application.

### Correct screen design

The live camera feed must:

- Fill the entire iPhone screen.
- Extend behind the touchscreen buttons.
- Extend to the screen edges.
- Adapt properly to the iPhone's display dimensions.
- Account for safe areas, Dynamic Island, and other cutouts.
- Remain visible behind transparent UI elements.
- Support portrait and landscape orientation where appropriate.

The rendered 3D MAME environment must appear naturally integrated into this camera view.

The original arcade game's aspect ratio must not restrict the camera feed to a matching rectangle.

### Touch controls

Overlay the virtual controls directly on the camera.

Use semi-transparent buttons positioned near the edges and corners of the screen.

For example:

- Virtual joystick at the lower left.
- Action buttons at the lower right.
- Coin and Start in an accessible location.
- Pause/settings near the upper edge.
- AR scale and placement controls in collapsible menus.

The user should still see the physical room or outdoor scenery between and underneath these controls.

**Never shrink the AR camera to make room for the controller.**

Instead, adapt the controller to the full-screen camera view.

### Immersive display

Provide a Hide Controls option that removes most interface elements while leaving the game running.

Provide an optional screenshot mode for capturing the 3D world without controller overlays.

Make the AR camera experience the visual centerpiece of the application.

---

# 5. Indoor Miniature AR Mode

Create a mode where supported arcade games appear as miniature, playable 3D dioramas inside my home.

### Setup

1. Open the full-screen iPhone camera.
2. Scan the room.
3. Detect a table, desk, or floor.
4. Display a 3D placement preview.
5. Let me tap the surface.
6. Anchor the miniature game to that location.
7. Begin playing.

### Miniature interactions

Allow the player to:

- Physically walk around the miniature game.
- Look down from above.
- Observe characters from different sides.
- Move closer to inspect objects.
- Move farther away to see the entire level.
- Rotate the game world.
- Scale the world.
- Reposition the world.
- Recenter AR tracking.

Provide Tiny, Small, Medium, Large, and Custom scaling presets.

Use ARKit world anchors to keep the miniature environment stable.

Preserve original game logic and movement when scaling.

### Example: Pac-Man

Pac-Man becomes a miniature 3D maze on my table.

The walls become raised 3D structures, while Pac-Man and the ghosts become animated 3D characters moving through the maze.

The entire game remains playable through the original MAME emulation.

---

# 6. Outdoor Giant World Mode — New Primary Feature

Implement a second AR gameplay mode called **Outdoor Giant World**.

This feature should let me take supported MAME arcade games outside and transform their reconstructed 3D environments into massive worlds occupying real outdoor space.

The environments must be capable of appearing significantly larger than my house.

Instead of seeing a small arcade world sitting on a table, I should see giant arcade scenery, characters, structures, and environments extending across my yard or another suitable open area.

### Example: Giant Pac-Man World

When loading Pac-Man and selecting Outdoor Giant World:

1. My iPhone displays a full-screen live outdoor camera feed.
2. The app scans the ground and surrounding environment.
3. I select where the giant arcade world should appear.
4. Pac-Man's maze becomes an enormous 3D structure positioned on the outdoor ground.
5. The maze walls may visually rise above the height of my house.
6. Pac-Man and the ghosts become large animated 3D characters.
7. The maze extends beyond my immediate physical location.
8. I can move around safely with my iPhone and see the gigantic game from different perspectives.
9. The original Pac-Man game continues running through MAME.
10. I can control Pac-Man using the automatically generated touchscreen controller.

The physical location is the viewing environment, while the arcade ROM continues controlling the game.

### Example: Giant Donkey Kong World

Convert Donkey Kong's platforms, ladders, barrels, characters, and scenery into an enormous vertical 3D arcade structure.

The structure can appear taller than a house.

I should be able to look upward with my iPhone to see the upper platforms, watch moving barrels, and control Mario as the original game runs.

The 3D structure should remain anchored to the selected outdoor location.

### Example: Giant Galaga World

Convert the player's spacecraft and enemy formations into giant 3D objects appearing above an outdoor playing field.

The arcade gameplay remains synchronized with the original MAME emulation.

Keep the enemies, projectiles, and visual effects within a coherent giant 3D scene.

### Example: Giant Metal Slug World

Convert platforms, scenery, buildings, characters, vehicles, projectiles, and environmental objects into a large-scale reconstructed 3D side-scrolling environment.

The virtual environment may extend well beyond the dimensions of my house.

Maintain the original 2D gameplay plane even while displaying the environment in 3D.

---

## 7. Outdoor World Scaling

Develop a scalable AR world system with the following presets:

- Miniature — tabletop-sized
- Room — room-sized
- House — approximately house-sized
- Giant — larger than a house
- Massive — large outdoor environment
- Custom — manually adjustable

These are visual scaling categories, not fixed physical measurements.

### Custom physical dimensions

Allow users to adjust the apparent physical size of the reconstructed world in meters.

Include configurable presets such as:

- 1 meter
- 5 meters
- 10 meters
- 25 meters
- 50 meters
- 100 meters
- Custom

Support larger values where the scene, device, and tracking system can accommodate them.

### Scaling implementation

Apply a consistent transformation between the original game coordinates and the rendered AR world.

For example:

Original arcade coordinates → 3D reconstruction coordinates → AR world coordinates → User-selected scale.

Scaling must change only the rendered environment.

It must not modify original game physics, movement speed, hitboxes, or input timing.

If a character moves one game-space unit, the reconstructed 3D character should move according to the selected visual scale.

Avoid altering the underlying emulator state.

---

## 8. Outdoor AR Tracking and Large-World Stability

Use ARKit world tracking, ground-plane detection, and appropriate spatial-anchor techniques.

Large worlds introduce additional tracking and numerical-precision challenges.

Design for:

- Large scene dimensions
- Camera movement
- Outdoor lighting
- Ground anchoring
- Changing tracking conditions
- Device movement and rotation
- Long viewing distances
- Anchor stability
- Camera near/far clipping behavior
- Depth-buffer precision
- Tracking recovery

Use camera-relative rendering or floating-origin techniques where helpful.

For extended environments, use logically organized scene sections and stable coordinate transforms.

### Outdoor tracking requirements

Do not assume GPS provides precise object placement.

Use visual-inertial tracking as the main local AR tracking method.

If geospatial anchoring is supported for the device and location, it can be added as an optional feature.

Do not make geospatial services mandatory.

### Limitations

Outdoor AR tracking may become inaccurate because of:

- Large featureless surfaces
- Low lighting
- Motion blur
- Rapid camera movement
- Reflective objects
- Tracking drift
- Limited device capabilities

Implement warnings and an easy Recenter World option.

Do not promise perfect alignment of house-sized virtual objects over unlimited distances.

### Physical safety

The giant 3D environment is visual only.

Do not imply virtual walls or game platforms are safe physical surfaces.

Do not encourage players to run through streets, cross obstacles, or enter dangerous areas while focused on the AR display.

Allow the entire arcade game to be played while the user remains stationary.

Physical walking should be optional for changing the viewing perspective, not required to play.

---

## 9. Virtual Objects, Real Buildings, and Outdoor Occlusion

Allow giant 3D arcade scenery to visually coexist with real buildings, trees, yards, and outdoor objects.

Use realistic positioning and lighting where possible.

### Occlusion

Implement supported AR occlusion techniques so real objects can appear in front of virtual objects when appropriate.

Use scene-depth or environmental reconstruction features where available.

When accurate outdoor building geometry is unavailable, avoid claiming real-world occlusion is exact.

Offer user settings such as:

- Standard AR rendering
- Depth-aware occlusion when supported
- Always-visible virtual objects
- Reduced-opacity virtual scenery

Make giant environments visually impressive while clearly communicating device limitations.

---

# 10. Automatic MAME Touchscreen Controls

The emulator must automatically detect and display the correct touchscreen controller for whichever MAME ROM is loaded.

This feature must work in both Indoor Miniature Mode and Outdoor Giant World Mode.

### Input detection

Use MAME's machine definitions, input ports, and other available metadata to detect:

- Required joystick type
- Number of buttons
- Player count
- Analog inputs
- Specialty controls
- Coin and Start requirements
- Screen orientation

Generate an appropriate layout without requiring manual initial configuration.

### Game-specific examples

**Pac-Man**
- Four-way joystick
- Coin
- Start

**Street Fighter II**
- Eight-way joystick
- Light, Medium, and Heavy Punch
- Light, Medium, and Heavy Kick
- Coin
- Start

**Metal Slug**
- Eight-way joystick
- Fire
- Jump
- Grenade
- Coin
- Start

**Centipede**
- Virtual trackball
- Fire
- Coin
- Start

**Arkanoid**
- Virtual spinner or dial
- Game-specific action buttons
- Coin
- Start

**Out Run**
- Steering wheel
- Accelerator
- Brake
- Gear selection
- Coin
- Start

**Light-gun games**
- Touch-to-aim
- Fire
- Reload where needed
- Coin
- Start

**Twin-stick games**
- Left virtual joystick
- Right virtual joystick
- Additional required action buttons

Base all input mappings on the actual supported MAME machine configuration.

### Touchscreen optimization

Use the entire iPhone screen for AR and place transparent controls on top.

Optimize control placement based on:

- Device screen size
- Landscape or portrait orientation
- Number of required controls
- Analog versus digital input
- Multi-touch support
- Original game control layout
- Left-handed preferences
- Visibility of the 3D environment

Automatically hide unnecessary controls.

### Control customization

Include:

- Drag-to-reposition
- Button resizing
- Transparency adjustment
- Sensitivity adjustment
- Analog dead zones
- Vibration/haptic feedback
- Control remapping
- Custom per-game layouts
- Restore automatic layout
- External Bluetooth controller support

Store settings separately for each game.

Controller touches must not accidentally resize or move the AR world.

---

## 11. AR Gameplay Interface

Implement an immersive interface designed around the full-screen camera.

### During gameplay

Display:

- Full-screen camera passthrough
- Reconstructed 3D game world
- Transparent virtual controls
- Small pause/menu control
- Optional AR reposition control
- Optional world-scale control

Hide large interface panels during normal gameplay.

### Pause menu

Provide:

- Resume
- Change AR Mode
- Resize World
- Reposition World
- Controller Layout
- Save State
- Load State
- Game Settings
- Exit Game

The camera feed should remain full-screen even while menus are presented, with menus appearing as temporary overlays.

### Switching AR modes

Let users switch between:

- Indoor Miniature
- Outdoor Giant World

Changing modes should not require re-importing the ROM.

Preserve emulator progress when switching modes where technically supported.

Reset the AR placement and update world scale appropriately.

The player must confirm a new placement before the scene becomes active in the selected mode.

---

## 12. Arcade Game Rendering Profiles

Different MAME games require different spatial interpretations.

Create profile categories for:

- Maze games
- Platformers
- Fighting games
- Side-scrolling games
- Vertical shooters
- Horizontal shooters
- Racing games
- Puzzle games
- Beat-'em-ups
- Native 3D arcade titles

Each profile should specify:

- Object recognition rules
- Voxel depth
- Character size
- Background depth
- Platform elevation
- Scene orientation
- Camera behavior
- Animation synchronization
- Recommended indoor scale
- Recommended outdoor scale
- World bounds
- Scene-transition behavior

### Large environments

For games with scrolling stages, use scene streaming or bounded spatial reconstruction.

Do not assume every game exposes the complete level at once.

Keep nearby reconstructed content synchronized with emulator output.

Cache static geometry where appropriate.

Clearly identify when a complete map cannot be reconstructed from the available data.

---

## 13. MAME ROM Library

Create a polished iOS game library.

The main menu should contain:

- Play
- Import ROM
- Game Library
- Indoor Miniature Mode
- Outdoor Giant World Mode
- Controller Settings
- 3D Profiles
- AR Settings
- Save States
- General Settings

Allow ROM importing through the iOS Files app.

Support compatible ZIP, 7z, CHD, BIOS, parent/clone, and device dependency arrangements.

Automatically detect missing or incompatible files.

Display:

- Game title
- Manufacturer
- Release year
- Original screen orientation
- Input type
- Number of players
- ROM compatibility
- 3D reconstruction compatibility
- Indoor AR support
- Outdoor AR support

Do not assume every emulated ROM has a functional 3D conversion profile.

Provide a clearly labeled original-rendering fallback for unsupported games.

---

## 14. Performance and Optimization

Optimize both AR modes for iPhone hardware.

### Emulation

Use a suitable native ARM64-compatible MAME core with an execution strategy permitted on normally sideloaded iOS apps.

Do not require unrestricted JIT access.

Preserve correct emulation timing and audio synchronization.

### Rendering

Use:

- Metal rendering
- Mesh caching
- GPU instancing
- Incremental geometry updates
- Texture caching
- Static-object caching
- Efficient animation updates
- Geometry level-of-detail
- Frustum culling
- Adaptive rendering quality

### Giant outdoor optimization

For house-sized or larger environments, also implement:

- Distance-based level-of-detail
- Object culling
- Scene streaming where useful
- Efficient shadow distances
- Adjustable rendering range
- Adaptive geometry complexity
- Camera-relative coordinate handling
- Configurable environmental effects

Maintain a visually consistent game world while reducing unnecessary rendering.

Provide performance presets such as Performance, Balanced, and Quality.

Do not guarantee that every MAME game runs at full speed.

---

## 15. Save States and Audio

Preserve original arcade audio and gameplay.

Implement supported features including:

- Pause/resume
- Save states
- Load states
- Game reset
- Coin insertion
- Player start
- Machine-specific settings
- Sound volume
- Input settings

When restoring a save state, update the reconstructed 3D environment to match the emulator.

Retain the same AR placement when possible.

Clearly identify machines that do not support reliable save states.

---

## 16. Project Architecture

Use a native iOS architecture with a modular MAME integration.

Suggested structure:

```text
MAME3DAR/
│
├── ios/
│   ├── App/
│   ├── UI/
│   ├── FullscreenCamera/
│   ├── GameLibrary/
│   ├── TouchControls/
│   └── Settings/
│
├── mame/
│   ├── Core/
│   ├── Drivers/
│   ├── InputBridge/
│   ├── VideoBridge/
│   └── AudioBridge/
│
├── reconstruction/
│   ├── GraphicsAdapters/
│   ├── SpriteAnalysis/
│   ├── TileAnalysis/
│   ├── VoxelGeneration/
│   ├── ObjectTracking/
│   └── GameProfiles/
│
├── ar/
│   ├── Camera/
│   ├── IndoorMiniature/
│   ├── OutdoorGiantWorld/
│   ├── SurfaceDetection/
│   ├── WorldAnchors/
│   ├── Scaling/
│   ├── Occlusion/
│   └── Tracking/
│
├── controls/
│   ├── AutomaticMapping/
│   ├── LayoutGenerator/
│   ├── Joystick/
│   ├── Trackball/
│   ├── Spinner/
│   ├── Steering/
│   └── LightGun/
│
├── scripts/
│
├── .github/
│   └── workflows/
│       └── ios-build.yml
│
└── README.md
```

Use Swift/SwiftUI for native interfaces, C/C++ for the emulator integration, and ARKit/RealityKit/Metal for spatial rendering.

Account for emulator licensing, driver support, ROM-set versioning, and the limitations of iOS execution environments.

---

## 17. IPA Generation and Sideloading

Create a GitHub Actions workflow capable of:

1. Checking out the project.
2. Installing required dependencies.
3. Building the supported MAME components.
4. Compiling the native iOS application.
5. Linking ARKit, RealityKit, Metal, and other required frameworks.
6. Packaging the app.
7. Exporting an IPA.
8. Publishing build artifacts.
9. Providing logs and diagnostic information.

Document the difference between unsigned, development-signed, and distributable IPA packages.

Provide Windows sideloading instructions using compatible signing and installation software.

Do not require me to own a Mac or operate a local VM.

Do not fabricate successful builds or testing results.

---

## 18. Development Milestones

Build and validate the project progressively.

**Phase 1 — Native iOS MAME Emulator**

Create the iOS application with genuine arcade ROM execution.

**Phase 2 — Automatic Touchscreen Controls**

Implement per-game input detection and adaptive control layouts.

**Phase 3 — Full-Screen AR Camera**

Implement edge-to-edge camera passthrough with transparent controls overlaid directly on top.

**Phase 4 — 3D Reconstruction Prototype**

Convert a suitable test game or homebrew program into synchronized, playable 3D geometry.

**Phase 5 — Indoor Miniature Mode**

Place the reconstructed arcade world on a table using AR tracking.

**Phase 6 — Outdoor Giant World Mode**

Implement large-scale ground placement and AR worlds that can appear bigger than a house.

**Phase 7 — Large-World Optimization**

Add appropriate anchor management, scalable scene rendering, distance culling, and tracking recovery.

**Phase 8 — Additional Game Profiles**

Develop 3D profiles for different arcade genres and hardware types.

**Phase 9 — Specialty Controls**

Add trackball, spinner, light-gun, racing, twin-stick, and multiplayer input configurations.

**Phase 10 — IPA Build and Testing**

Complete the remote build pipeline, test on physical iPhone hardware, and produce honest compatibility results.

---

## 19. Final Deliverables

Provide:

1. Complete VS Code project for Windows development.
2. Working MAME-compatible iOS emulator.
3. ROM importing and dependency management.
4. Automatic per-game touchscreen controls.
5. 3dSen-inspired 2D-to-3D conversion engine.
6. Expandable game-specific conversion profiles.
7. Full-screen, edge-to-edge AR camera.
8. Transparent controls overlaid on the camera.
9. Indoor miniature 3D world mode.
10. Outdoor giant 3D world mode.
11. AR environments capable of appearing larger than a house.
12. Adjustable physical world scaling.
13. Outdoor ground placement and tracking.
14. 3D scene lighting and supported occlusion.
15. Original gameplay and audio preservation.
16. Save states where supported.
17. Performance optimization.
18. Automated cloud IPA builds.
19. Windows sideloading instructions.
20. Complete testing and compatibility documentation.

## Final Non-Negotiable Requirements

The completed project must prioritize four main goals.

**First: Genuine 3D conversion.**

Supported MAME games must become actual playable 3D environments inspired by 3dSen, rather than flat arcade screens.

**Second: Two AR world sizes.**

I want to play arcade games as miniature 3D worlds in my home or transform them into enormous 3D environments outdoors that can visually exceed the dimensions of my house.

**Third: Full-screen camera gameplay.**

The live iPhone camera must occupy the entire screen at all times during AR gameplay.

Never display the AR camera inside a boxed viewport.

Touchscreen controls must appear transparently over the camera without reducing its visible area.

**Fourth: Automatic game-specific controls.**

Every supported MAME game must use an appropriately optimized touchscreen layout based on its actual input requirements.

The application must remain manageable from Windows using Visual Studio Code, with remote iOS compilation and an IPA suitable for an appropriate sideloading process.

Implement real code, validate each milestone, and clearly identify technical limitations rather than claiming unsupported functionality works.

Start with genuine MAME emulation and automatic touchscreen controls, establish the full-screen AR presentation, implement a playable 3D reconstruction prototype, and then develop both the miniature and giant outdoor viewing modes.
