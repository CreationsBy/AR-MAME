# Build, sign, and install from Windows

All iOS compilation happens on GitHub's macOS runner. Use Windows/VS Code to edit, commit, push, download the artifact, and run a supported signing/installation tool. No local Mac or VM is required by this project.

## Download the build

Open https://github.com/CreationsBy/AR-MAME/actions and select a successful **iOS IPA** run. Download the **ARMAME-unsigned** artifact and extract `ARMAME-unsigned.ipa`. If the job failed, inspect **ios-diagnostics** and its logs; no working IPA is claimed by a failed run. The artifact ZIP and contained IPA are different files.

The workflow runs `xcodebuild` with signing disabled and packages the compiled app into `Payload/ARMAME.app`. It deliberately does not contain a private certificate, team ID, or provisioning profile.

## What signing means

| Package | Contents and use |
| --- | --- |
| Unsigned IPA | Compiled app without a valid device-install signature. Must be signed/re-signed before installation. |
| Development-signed IPA | Signed with an Apple development certificate and a provisioning profile authorizing the app, team, entitlements, and testing device. Requires Developer Mode as applicable. |
| Ad hoc / other distribution | Requires the appropriate Apple distribution certificate/profile and permitted devices/distribution channel. An arbitrary sideload signature does not authorize App Store or public distribution. |

For manual team signing you need a matching Apple-issued certificate **and private key** (typically password-protected `.p12`), an appropriate `.mobileprovision`, the intended bundle identifier, and the device UDID where required. The certificate alone is insufficient. Keep private keys/passwords in a trusted signing tool or GitHub encrypted secrets, never in source control. This repository provides unsigned builds and does not yet automate certificate-based signed export.

## Sideloadly on Windows

1. Download the current installer only from [Sideloadly](https://sideloadly.io/) and follow its current Windows iTunes/iCloud/driver requirements. Install the Apple components it specifies, not arbitrary driver bundles.
2. Connect and unlock the iPhone over USB. Trust the computer on the device.
3. Open Sideloadly, select the device, and choose the extracted `ARMAME-unsigned.ipa`.
4. Use your own Apple account or supported signing identity directly inside the signing tool; complete two-factor authentication if requested. No credentials are needed in this repository or this chat.
5. Start its signing/install process. The tool obtains/applies the appropriate signature and provisioning under that account's capabilities; it cannot bypass app/entitlement restrictions.
6. If iOS requests developer trust, follow the installed profile prompt under **Settings > General > VPN & Device Management**.
7. For development-signed installs on applicable iOS versions, enable **Settings > Privacy & Security > Developer Mode**, restart, and confirm. See [Apple's Developer Mode documentation](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device).
8. Launch AR-MAME and allow camera access. Test with a matching legally obtained ROM set.

Free-account signing typically expires quickly (often seven days) and has device/app limits. Re-sign/refresh before expiry using the tool's current supported process. Paid developer provisioning has different validity and device rules. Check the tool and Apple's current account terms; successful compilation does not guarantee signing/install success.

## AltStore Classic alternative

Follow the official [AltStore Classic Windows installation guide](https://faq.altstore.io/altstore-classic/how-to-install-altstore-windows) to install AltServer and the required Apple components. Install/trust AltStore on the connected phone, then import the IPA through AltStore's supported app installation flow and refresh it using AltServer. Observe account app limits and certificate expiry. Do not confuse AltStore Classic with unrelated regional marketplace installation flows.

## ROM folder layout

Import a ZIP directly or select a folder containing ZIPs and CHD machine directories:

```text
ROMs/
  pacman.zip
  neogeo.zip
  mslug.zip
  parent.zip
  clone.zip
  chdmachine.zip
  chdmachine/
    required-disk-name.chd
```

Names above illustrate arrangements, not a promise that every example needs every listed dependency. Use the core's generated metadata and launch audit. Renaming a ZIP does not convert its ROM version. Do not unzip the individual ROM chips.

For 7z sets, use 7-Zip on Windows to extract into a temporary folder and create a ZIP with the same ROM members at its root. Do not simply rename `.7z` to `.zip`. Preserve original names and contents. For CHDs, import the containing ROM-root folder so the `machine/disk.chd` layout survives; loose CHDs are rejected with instructions. CHDs from a newer MAME version may be incompatible with this core.

The app exposes its Documents folder through the iOS Files application so you can manage imported sets, System files, and Saves. Existing import targets are not silently overwritten. The current importer copies files synchronously and large CHDs can temporarily stall the UI; test with small sets first.
