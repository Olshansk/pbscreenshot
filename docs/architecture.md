# Architecture <!-- omit in toc -->

Four Swift targets keep the macOS app small while separating code that future desktop ports can reuse.
Windows has a separate native C# implementation described in [Windows architecture and installation](windows.md).

- [Source tree](#source-tree)
- [Dependency direction](#dependency-direction)
- [Behavior](#behavior)
- [Platform boundaries](#platform-boundaries)

## Source tree

```text
pbscreenshot/
├── Package.swift                         # Target/dependency definitions
├── Makefile                              # Build, test, install, release
├── Sources/
│   ├── Core/                             # PBScreenshotKit — Foundation only
│   │   ├── Capture/CaptureTypes.swift     # Modes and capture result
│   │   ├── Clipboard/ClipboardMode.swift  # Clipboard format choices
│   │   ├── Config/Version.swift           # Version used by bundle and CLI
│   │   └── Storage/TempStore.swift        # Capture paths and retention
│   ├── Platforms/
│   │   ├── macOS/                        # PBScreenshotMacOS — native adapters
│   │   │   ├── Capture/Capturer.swift     # Native screencapture process
│   │   │   ├── Clipboard/Pasteboard.swift # Finder-compatible file references
│   │   │   ├── Logging/Log.swift          # Apple unified logging
│   │   │   └── Permissions/ScreenRecordingPermission.swift
│   │   ├── Linux/README.md               # Future implementation boundary
│   │   └── Windows/README.md             # Pointer to the separate .NET projects
│   ├── App/macOS/                        # pbscreenshot-agent — menu bar app
│   │   ├── App.swift                     # Entry, menu, reopen/single instance
│   │   ├── Capture/CaptureService.swift   # Async capture and visible errors
│   │   ├── Config/DefaultsKey.swift       # Existing preference keys preserved
│   │   ├── Hotkeys/Hotkeys.swift          # Carbon hotkeys and pause state
│   │   ├── Startup/LoginItem.swift        # SMAppService state and errors
│   │   └── Settings/
│   │       ├── SettingsView.swift         # Hotkeys, startup, permissions
│   │       └── SettingsWindow.swift       # Single native settings window
│   └── CLI/macOS/Command.swift           # pbscreenshot CLI
├── Tests/
│   ├── CoreTests/                        # Portable storage tests
│   ├── MacOSTests/                       # Capture, clipboard, permission tests
│   └── AppTests/                         # Startup state transitions
├── Resources/                            # macOS Info.plist and app icon
├── scripts/macos/
│   ├── assemble-app.sh                   # Shared local/release bundle assembly
│   ├── build-release.sh                  # arm64/x86_64 build and merge
│   └── make-with-clt.sh                  # Workaround for this Mac's Xcode setup
├── packaging/pbscreenshot.rb             # Homebrew cask template
└── docs/                                 # Architecture and diagnostic report
```

## Dependency direction

```text
pbscreenshot-agent ──┬── PBScreenshotMacOS ── PBScreenshotKit
                     ├── PBScreenshotKit
                     └── KeyboardShortcuts
pbscreenshot ────────┬── PBScreenshotMacOS
                     ├── PBScreenshotKit
                     └── ArgumentParser
```

`PBScreenshotKit` has no AppKit, SwiftUI, CoreGraphics, ServiceManagement, or hotkey dependency.
The macOS adapter library owns native capture and clipboard APIs.
The app owns user preferences, lifecycle, hotkeys, and startup policy.
No protocols or empty implementations are added for platforms that do not exist yet.

## Behavior

`make install` builds a native debug app, signs it locally without a certificate, and installs to `~/Applications`.
`make launch` additionally opens it.
Local bundles live in `dist/local`, separate from universal release bundles in `dist`.
`make release` retains Developer ID signing and notarization.


- The camera menu remains available while captures are paused; the icon changes to a pause symbol.
- Enable/disable persists across relaunches and releases global hotkeys while paused.
- Settings can open from the menu or by reopening the app in Finder.
- Hotkey editing, enable/disable, startup, and Screen Recording are the primary settings.
- Existing clipboard, shutter, and retention preferences remain under Advanced.
- Startup state is read back from macOS, including pending approval and failed registration.
- Permission checks run when Settings opens, becomes active, or the user selects Check Again.
- Permission prompts require a user action; launch never requests Accessibility access.
- Only one app capture runs at a time. Errors appear in Settings.

## Platform boundaries

On non-macOS hosts, the package manifest exposes only the portable library and its tests.
Linux is still a future adapter boundary. Windows is built independently from `Sources/Windows` with Core, Native, and App .NET projects; see [Windows documentation](windows.md) for its full tree and validation limits.
