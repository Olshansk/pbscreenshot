# Desktop diagnostic report — 2026-10-11 <!-- omit in toc -->

Native macOS and Windows implementations are separated, the Windows installer runs without administrator access or a preinstalled .NET runtime, and CI exercises a real Windows desktop plus the installation lifecycle.

- [Implementation](#implementation)
- [Evidence](#evidence)
- [Installation and permissions](#installation-and-permissions)
- [Remaining verification](#remaining-verification)

## Implementation

- macOS keeps its Foundation core, native adapters, menu bar app, and CLI targets.
- Windows has three .NET 10 projects: portable configuration, native Windows adapters, and a Windows Forms tray/settings app.
- Hotkeys, startup, permissions, capture, clipboard, and settings each have their own files/directories.
- Windows defaults to Ctrl+Shift+2 for region capture and Ctrl+Shift+3 for full desktop capture; settings can change both.
- Both apps expose enable/disable, startup, and hotkey settings.
- `make install` selects the host's native installation. Explicit `windows-*` targets cover build, settings tests, native integration tests, packaging, install, uninstall, and CI reinstall tests.
- The Windows installer preserves user settings while removing the application's Run startup entry on uninstall.
- Public signing/release is separate from local installation.

See [architecture](architecture.md), [Windows setup](windows.md), and [the earlier macOS permission investigation](diagnostics-2026-10-04.md).

## Evidence

Implementation commit: `c68b2beeec6821b3637a21159c7c43a80d6c1e5d`.
[CI run and downloadable Windows installer](https://github.com/Olshansk/pbscreenshot/actions/runs/38165806910).
The preceding [full lifecycle run](https://github.com/Olshansk/pbscreenshot/actions/runs/38165738081) also passed.

| # | Severity | Check |
|---|---|---|
| 1 | ✅ | Local macOS: all 21 Swift tests passed, including real private-pasteboard file/image reads. |
| 2 | ✅ | Local Windows cross-compilation: application and native integration test projects compile with zero warnings/errors. |
| 3 | ✅ | Configuration checks: defaults, persistence, invalid-edit preservation, duplicate/invalid shortcut rejection, corrupt-file preservation. |
| 4 | ✅ | Windows VM: desktop capture produces a PNG with the actual rendered green marker, not just plausible dimensions. |
| 5 | ✅ | Windows VM: real file-reference clipboard round trip, hotkey conflict reporting and release while disabled, startup registration/removal, virtual-desktop overlay bounds. |
| 6 | ✅ | Windows VM: self-contained installer, app launch/message-loop readiness, uninstall, startup cleanup, preference preservation, reinstall, relaunch, final uninstall. |
| 7 | ✅ | macOS CI: clean build and all 21 Swift tests. |

🟢 The automated checks above pass. The limits below remain outside their coverage.

## Installation and permissions

The Windows installer is a per-user Inno Setup executable targeting x64; it installs to `%LOCALAPPDATA%\Programs\pbscreenshot`.
It embeds the .NET runtime and requires no Apple account or certificate.
Settings live separately at `%LOCALAPPDATA%\pbscreenshot\settings.json`.
Windows does not use macOS's Screen Recording or Accessibility grant mechanism.
Protected content and locked desktops are outside the supported capture context.

On macOS, local installation remains ad-hoc signed with timestamping disabled.
The earlier investigation identified an improperly bound linker signature on the original installation and the distinction between terminal and app permission contexts.
Changing the signing identity, rebuilding ad-hoc code, or launching another copy can affect permission continuity; local permission approval still must be verified with the installed app.
The existing diagnostic report explains the observed evidence and recovery steps without resetting the user's privacy database.

## Remaining verification

| # | Severity | Outstanding item |
|---|---|---|
| 1 | 🟡 | The HP laptop itself is not connected to this session. Its OS and the identity of “Exactium” still need clarification; no installation of that application or the HP itself is claimed. |
| 2 | 🟡 | CI runs Windows Server 2022, not that laptop's Windows/driver combination. Real key presses, drag/Escape interaction, mixed-DPI monitors, actual sign-in startup, and pasting into the customer's preferred apps still need a laptop smoke test. |
| 3 | 🟡 | Windows Authenticode signing and macOS notarization remain public-release work. The current Windows installer has no publisher signature. |
| 4 | 🟠 | The macOS menu bar app's Screen Recording grant and hotkey-driven capture still need verification on an unlocked Mac. The earlier computer-use attempt was blocked by the lock screen. |
| 5 | 🟡 | Linux remains a documented future adapter boundary; there is no Linux desktop installer or application. |
