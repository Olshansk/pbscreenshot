# Windows installation <!-- omit in toc -->

pbscreenshot runs as a native Windows tray application, with region/full-screen capture, file-reference clipboard output, editable hotkeys, pause/resume, and optional launch at sign-in.
The installer includes the .NET runtime and installs for the current user without administrator access.

- [Install on your laptop](#install-on-your-laptop)
- [Build locally](#build-locally)
- [Projects](#projects)
- [Validation](#validation)
- [Current limits](#current-limits)

## Install on your laptop

For the primary clone-and-install workflow on Windows 11 x64, follow the [main README](../README.md#windows) and run `make install`.

Alternatively, download `pbscreenshot-windows-x64` from a successful [Desktop builds and installation workflow](https://github.com/Olshansk/pbscreenshot/actions/workflows/desktop.yml), extract it, and run `pbscreenshot-setup-win-x64.exe`.
This is a local development installer, not a signed public release.
Windows may show an unknown-publisher warning.

Launch pbscreenshot from Start and find its icon in the system tray (possibly under the overflow arrow).
Right-click it to open **Settings**, pause captures, or quit.
Click a shortcut field and press the new combination, then **Save**.
The defaults are **Ctrl+Shift+2** for a region and **Ctrl+Shift+3** for the full desktop.
Paste into an application that accepts file attachments.

Enable **Launch when I sign in** in Settings to start automatically.
Uninstall from Windows Settings → Apps; uninstall removes startup registration and preserves `%LOCALAPPDATA%\pbscreenshot\settings.json` for reinstall.
Capture PNGs remain in `%TEMP%\pbscreenshot` and expire after seven days when another capture runs.

## Build locally

Development requires the .NET 10 SDK and GNU Make.
Packaging also requires PowerShell 7 and Inno Setup 6 in its default installation directory.
Run these commands from the repository root.

Show Windows commands:

```powershell
make help
```

Build and install:

```powershell
make install
```

Build without installing:

```powershell
make windows-build
```

Run configuration tests:

```powershell
make windows-test
```

Run native integration tests on a disposable desktop (these replace the clipboard temporarily):

```powershell
make windows-test-native
```

Package the self-contained installer:

```powershell
make windows-package
```

Uninstall while retaining settings:

```powershell
make windows-uninstall
```

On macOS/Linux, `make windows-build` cross-compiles the app and `make windows-test` tests portable settings.
Native tests and installer packaging require Windows.
Windows has no dependency on Swift, Xcode, or an Apple developer account.

## Projects

```text
Sources/Windows/
├── Core/Config/           # Validated settings, atomic persistence; no Windows APIs
├── Native/                # Windows Forms and Win32 adapters
│   ├── Capture/           # Desktop PNG capture and rectangular selection overlay
│   ├── Clipboard/         # CF_HDROP file references
│   ├── Hotkeys/           # RegisterHotKey, conflict reporting, disable/release
│   ├── Startup/           # Current-user Run registration and readback
│   └── Permissions/       # Desktop availability and permission guidance
└── App/                   # Entry point, single instance, tray lifecycle
    └── Settings/          # Shortcut recorder and settings window
Tests/Windows/
├── Core/                  # Settings round trips, rejection, corruption preservation
└── Native/                # Real desktop/clipboard/hotkey/startup integration
scripts/windows/           # Packaging, install/uninstall, CI lifecycle verification
packaging/windows/         # Inno Setup definition
makefiles/windows.mk       # Windows build/install/test targets
```

Dependency direction: `App → Native → Core`.
These are separate C# projects; the Swift core and macOS UI remain separate projects.
The platform APIs and deployment constraints differ, so the Windows UI does not attempt to host SwiftUI.

## Validation

GitHub Actions starts a fresh `windows-2022` x64 VM, installs .NET 10, compiles the app, and tests configuration and native APIs.
It runs the documented `make install` flow, captures the actual installer window for review, starts the installed executable, checks its message loop, uninstalls, verifies startup cleanup and settings retention, reinstalls, starts it again, and uninstalls.
The lifecycle target is restricted to GitHub Actions because it modifies a user installation.
The downloadable artifact contains the tested installer and its screenshot.

## Current limits

| # | Severity | Limit |
|---|---|---|
| 1 | 🟡 | CI uses Windows Server 2022 with a desktop; it does not prove every HP driver, scaling setup, Windows 11 policy, or third-party paste destination. |
| 2 | 🟡 | The installer is unsigned. Authenticode signing and a public release are separate publication work. |
| 3 | 🟡 | Windows capture supports region and full desktop; the macOS CLI and window-only capture are not ported. |
| 4 | 🟡 | Interactive drag selection, actual keyboard delivery, mixed-DPI monitors, and sign-in startup still need a Windows laptop smoke test. |
| 5 | 🟢 | Windows needs no macOS-style Screen Recording/Accessibility grant; protected content and locked desktops cannot be captured. |
