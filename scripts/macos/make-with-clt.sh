#!/bin/bash
set -euo pipefail

# Work around incomplete Xcode setup without changing xcode-select or accepting a license.
# Normal Xcode installations should use make directly.
cd "$(dirname "$0")/../.."
export DEVELOPER_DIR=/Library/Developer/CommandLineTools
xcode=/Applications/Xcode.app/Contents/Developer
frameworks="$DEVELOPER_DIR/Library/Developer/Frameworks"
plugins="$xcode/Platforms/MacOSX.platform/Developer/usr/lib/swift/host/plugins"
server="$xcode/Platforms/MacOSX.platform/Developer/usr/bin/swift-plugin-server"
runtime="$xcode/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift"
for required in "$frameworks" "$plugins" "$server" "$runtime"; do
    if [ ! -e "$required" ]; then
        printf 'Missing toolchain component: %s\nUse make with a configured Xcode installation.\n' "$required" >&2
        exit 1
    fi
done

flags="--build-system native -Xswiftc -resource-dir -Xswiftc $runtime -Xswiftc -F$frameworks -Xlinker -rpath -Xlinker $frameworks -Xswiftc -external-plugin-path -Xswiftc $plugins#$server"
exec "$DEVELOPER_DIR/usr/bin/make" "$@" SWIFT_FLAGS="$flags"
