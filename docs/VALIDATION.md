# Verified build and test results

Date: 2026-10-19 (America/New_York).

Validated application source commit: `c752c8f5c58b9432bcde68bb4c2846320cf27f9e`.

[Successful GitHub Actions run](https://github.com/CreationsBy/AR-MAME/actions/runs/39341218165).

All three jobs completed successfully:

- **logic:** four Python tooling tests and five Swift logic tests.
- **core-metadata:** compiled the real Linux MAME core; inspected real input definitions for Pac-Man, Street Fighter II, Metal Slug, Arkanoid, Centipede, and Out Run; rejected an unknown machine; generated 5,370 catalog records, including the original diagnostic.
- **core-metadata runtime diagnostic:** executed the original Z80 diagnostic through MAME. Received 24 video callbacks and 19,008 audio frames; input changed the extracted sprite from `(144, 113)` to `(144, 107)`; a serialized/restored machine state returned the hardware sprite to its saved coordinates.
- **ios:** compiled the ARM64 core and native iOS application on GitHub's macOS runner, then packaged and uploaded the unsigned IPA.

The diagnostic emits silent audio buffers; callback counts verify delivery, not audible commercial-game sound or A/V synchronization quality.

## Artifact

[Download ARMAME-unsigned artifact](https://github.com/CreationsBy/AR-MAME/actions/runs/39341218165/artifacts/12228484587). Extract the IPA from the artifact ZIP.

The downloaded IPA was inspected locally:

- Size: 8,086,372 bytes.
- SHA-256: `03e303a9453db6f96972f72cc518f4470ba9514aa545961414445f73b9b5de3a`.
- `Payload/ARMAME.app/ARMAME` is an ARM64 Mach-O executable.
- Bundle identifier: `com.creationsby.armame`.
- Generated catalog, original diagnostic container, and `core-LICENSE.md` resources are present.
- Local workspace copy: `build/artifacts/ARMAME-unsigned.ipa` (ignored by Git).

The package is unsigned. Signing, installation, launch, and physical iPhone camera/AR behavior have not been tested. No commercial ROM boot, game reconstruction accuracy, device performance, audible sound quality, outdoor drift, or occlusion accuracy is claimed by these checks. Follow [Windows sideloading](WINDOWS-SIDELOADING.md) and [device testing](DEVICE-TESTING.md).
