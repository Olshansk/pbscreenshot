#!/bin/bash
set -euo pipefail

# Build each architecture with the selected Swift build system, then merge binaries.
output=.build/universal/release
mkdir -p "$output"
for arch in arm64 x86_64; do
    swift build "$@" -c release --arch "$arch"
done
arm=$(swift build "$@" -c release --arch arm64 --show-bin-path)
intel=$(swift build "$@" -c release --arch x86_64 --show-bin-path)
for binary in pbscreenshot pbscreenshot-agent; do
    lipo -create "$arm/$binary" "$intel/$binary" -output "$output/$binary"
done
resource="$arm/KeyboardShortcuts_KeyboardShortcuts.bundle"
test -d "$resource"
rm -rf "$output/KeyboardShortcuts_KeyboardShortcuts.bundle"
cp -R "$resource" "$output/"
