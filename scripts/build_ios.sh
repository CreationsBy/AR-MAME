#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build/core build/artifacts
python3 scripts/prepare_core.py
python3 scripts/generate_catalog.py
sdk="$(xcrun --sdk iphoneos --show-sdk-path)"
make -C vendor/mame2003-plus -j3 armame-static \
  platform=ios-arm64 ARCH=arm64 CPU_ARCH=arm64 IOSSDK="$sdk" \
  MINVERSION=-miphoneos-version-min=17.0 \
  'PLATCFLAGS=-D__IOS__ -fcommon -Wno-error=implicit-function-declaration -Wno-error=int-conversion -Wno-error=incompatible-pointer-types' \
  ARMAME_ARCHIVE="$PWD/build/core/libarmame.a" 2>&1 | tee build/core-build.log
xcrun lipo -info build/core/libarmame.a
xcodegen generate --spec project.yml
xcodebuild -project ARMAME.xcodeproj -scheme ARMAME -configuration Release \
  -sdk iphoneos -destination 'generic/platform=iOS' -derivedDataPath build/DerivedData \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build 2>&1 | tee build/xcodebuild.log
python3 scripts/package_ipa.py build/DerivedData/Build/Products/Release-iphoneos/ARMAME.app build/artifacts/ARMAME-unsigned.ipa
