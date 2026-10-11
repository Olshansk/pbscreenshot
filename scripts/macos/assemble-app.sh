#!/bin/bash
set -euo pipefail

# Assemble either a local or universal build using the same resources and identity.
binaries=${1:?Usage: assemble-app.sh binaries app version}
app=${2:?Missing app path}
version=${3:?Missing version}
resources="$binaries/KeyboardShortcuts_KeyboardShortcuts.bundle"
for binary in pbscreenshot pbscreenshot-agent; do
    test -x "$binaries/$binary"
done
test -d "$resources"
test -f Resources/pbscreenshot.icns

rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$binaries/pbscreenshot" "$binaries/pbscreenshot-agent" "$app/Contents/MacOS/"
cp -R "$resources" "$app/Contents/Resources/"
cp Resources/pbscreenshot.icns "$app/Contents/Resources/"
sed "s/@VERSION@/$version/g" Resources/Info.plist > "$app/Contents/Info.plist"
printf 'APPL????' > "$app/Contents/PkgInfo"
