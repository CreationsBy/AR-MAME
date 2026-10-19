# Validation procedure

Use legally obtained ROMs that match the exact MAME 2003-Plus core. Do not add ROMs or save states containing game data to GitHub.

Record phone model, iOS version, core revision, application commit, selected ROM set/hashes, controller, thermal state, and indoor/outdoor conditions for every result.

1. Confirm all three cloud jobs pass. Inspect the IPA for `Payload/ARMAME.app/ARMAME`, generated machine catalog, and core license files. Re-sign and install on a physical iPhone.
   Start with **Try Original Z80 Diagnostic**. Verify its generated board and moving yellow sprite in flat and hardware 3D modes before importing a commercial set. This test does not validate a commercial game's emulation or reconstructed appearance.
2. Import a known-compatible ZIP. Test missing parent/BIOS and wrong-version errors. Test a properly named machine folder with matching CHD version. Confirm unsupported 7z and loose CHD guidance.
3. Verify original rendering, boot, Coin/Start, all required actions, native screen orientation, timing, scoring, audio pitch, and pause/reset. Compare against the same pinned core on a reference platform.
4. For pacman/puckman, switch to the hardware 3D profile. Verify maze alignment, pellets disappearing, sprite positions, palette, animation, attract screens, death/restart, tunnel transitions, and level changes against the flat output. Log known visual mismatches rather than declaring support.
5. In portrait and landscape, verify camera pixels reach every edge and remain behind controls, cutouts are respected, simultaneous input works, and joystick/buttons never move the AR anchor. Edit and restore layouts; restart the app to verify per-game persistence.
6. Place a 0.6m board on a detected tabletop, walk slowly around it if safe, rotate and resize it. Confirm physical dimensions with a measuring reference. Test backgrounding, lock/unlock, session interruption, camera permission refusal, and tracking loss.
7. Switch mode without reloading the ROM. Confirm progress is preserved, gameplay pauses until a fresh ground placement, and scale resets to 25m. Compare 1/5/10/25/50/100m presets while remaining stationary in a clear area.
8. Test tracking in direct sunlight, shadow, low-feature ground, and low light. Verify warnings and repositioning. Never treat virtual platforms/walls as physical surfaces or require walking across hazards.
9. Test supported LiDAR mesh occlusion against nearby real objects, then compare standard, always-visible, and reduced-opacity modes. Record inaccuracies and sensor range.
10. Save, advance gameplay, restore, and confirm graphics immediately match restored state while placement stays fixed. Confirm incompatible/corrupt states fail clearly.
11. Check Bluetooth input and disconnect while holding controls. Check audio after route changes and pauses. Measure emulation speed, audio underruns, mesh draw cost, memory, battery, and thermal throttling for at least 15 minutes.

Completed checks: four local/cloud Python tooling tests, five cloud Swift tests, native machine metadata checks, an original Z80 runtime diagnostic including input and state restoration, and a successful ARM64 iOS build. The downloaded IPA's executable and required resources were inspected locally. See [verified results](VALIDATION.md) for the source commit, run, artifact, and checksum. No physical device results are prefilled.
