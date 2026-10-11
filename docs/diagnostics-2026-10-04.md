# Publication diagnostic report — 2026-10-04 <!-- omit in toc -->

The project now has separate core, macOS adapter, app, and CLI targets, a persistent pause switch, focused settings, and a signed installation path.
The current priority is local installation without a developer account; publishing is deferred. The initial release audit remains below as historical test evidence.
Nothing was committed or published.

- [Local-first follow-up](#local-first-follow-up)
- [Architecture and scope](#architecture-and-scope)
- [Permission findings](#permission-findings)
- [Verification results](#verification-results)
- [Remaining release checks](#remaining-release-checks)
- [Local evidence and recovery](#local-evidence-and-recovery)

## Local-first follow-up

The certificate requirement was removed from local installation at the user's request.
`make install` now builds a host-architecture debug bundle and ad-hoc signs it with `--timestamp=none`; `make launch` also opens it.
`make release` still builds the universal production bundle and uses Developer ID signing/notarization.
Local installation never reads the production signing identity or invokes notarization.
A first-time SwiftPM dependency download still needs network access.

The workspace examples inspected were `../claude_companion/Makefile` and `../openclaw/scripts/codesign-mac-app.sh` (paths relative to the repository root).
OpenClaw demonstrates ad-hoc signing and disabled timestamping; only that small pattern was reused, with no added entitlements or security-setting changes.

| # | Severity | Follow-up result |
|---|---|---|
| 1 | ✅ | Built and installed locally with `SIGN_ID=` and `LOCAL_SIGN_ID=-`, proving the local path requires no production certificate. |
| 2 | ✅ | The installed native arm64 app passes deep/strict verification, has the intended bundle ID and sealed resources, and its CLI reports version 0.1.0. |
| 3 | ✅ | Local and release dry runs confirm separate artifacts, timestamp/signing behavior, and no notarization in the install path. |
| 4 | 🟡 | This Mac's incomplete Xcode setup blocks `/usr/bin/make` before it reads the Makefile. The checked-in `scripts/macos/make-with-clt.sh` reproduces the tested workaround without changing global configuration. |
| 5 | 🟡 | Ad-hoc code can run locally, but rebuilds may require Screen Recording approval again. An optional existing `LOCAL_SIGN_ID` can provide a stable signing identity while keeping timestamping disabled. |
| 6 | 🔴 | The user approved granting Screen Recording. Computer control then reported that the Mac is locked and automatic unlock failed. No grant or native UI verification was performed after that failure. |

Latest local evidence: `output/diagnostics/local-install.log`, `local-signature.txt`, `local-tests.log`, `local-install-dry-run.txt`, and `release-dry-run.txt`.
The installed app is now the local ad-hoc build; the Developer ID observations below refer to the earlier audit run.

## Architecture and scope

See [the complete tree and target dependencies](architecture.md).
All first-party Swift files, tests, package configuration, Makefile, app metadata, cask template, README, and historical handoff notes were inspected.

- `Sources/Core` contains Foundation-only types, version configuration, and temporary storage.
- `Sources/Platforms/macOS` contains capture, clipboard, logging, and permissions.
- `Sources/App/macOS` contains config, capture orchestration, hotkeys, startup, and settings.
- `Sources/CLI/macOS` contains argument parsing and command execution.
- Linux and Windows directories document future adapter boundaries; neither ships an app.
- Existing clipboard modes, shutter preferences, retention, shortcut keys, bundle identifier, and bundled CLI are preserved.
- Existing uncommitted icon/resource packaging changes were retained.
- `Package.resolved` is no longer ignored, so the tested dependency versions can be included in the next manual commit.

## Permission findings

| # | Severity | Finding and response |
|---|---|---|
| 1 | 🟠 | **Confirmed identity problem:** the previously installed app used an ad-hoc/linker signature with identifier `pbscreenshot-agent`, no team identifier, an unbound Info.plist, and no resource seal. `make launch` rebuilt and installed without signing. The initial fix used Developer ID signing. The local-first follow-up now deliberately supports ad-hoc builds too; both paths verify the complete bundle. |
| 2 | 🟠 | **Likely explanation for other-machine failures:** rebuilds changed the ad-hoc identity, which can invalidate Screen Recording grants. This is supported by local signature evidence and Apple's guidance, but the affected other computers were not examined. |
| 3 | 🟡 | **OS authorization and process state differ:** a running process may still lack access after a Settings change. The app now reads the preflight result on activation and on Check Again, requests only after a user action, and explains quitting/reopening the installed app. It does not claim a machine reboot is required. |
| 4 | ✅ | **Startup UI was stale:** the old toggle cached a Boolean and logged failures invisibly. The new controller reads actual `SMAppService` status after mutations and on activation; approval-required and error states are visible. |
| 5 | 🟢 | **Accessibility is not a requirement for this app's Carbon hotkeys.** No Accessibility permission request or event-tap implementation was added. |
| 6 | 🟡 | **App and shell are separate permission contexts:** the CLI captured successfully, but the newly signed menu bar app reported Permission needed. CLI success does not establish an app grant. |

Apple's [code-signing explanation for lost screen-capture grants](https://developer.apple.com/forums/thread/819406) confirms the ad-hoc identity problem.
Apple's [requiresApproval documentation](https://developer.apple.com/documentation/servicemanagement/smappservice/status-swift.enum/requiresapproval) and [register documentation](https://developer.apple.com/documentation/servicemanagement/smappservice/register()) distinguish registration from eligibility to launch.
The installed CoreGraphics SDK's `CGWindow.h` also documents that previously denied processes are not re-prompted and must be enabled in System Settings.

## Verification results

Host: Apple Silicon, macOS 27.0.1 (26A434), Swift 6.4.

| # | Severity | Check and observed result |
|---|---|---|
| 1 | ✅ | **21 tests passed** across storage, capture process behavior, private-pasteboard round trips, permission refresh/revocation, and startup approval/error transitions. The new OS-state tests use injected responses; they do not grant permissions or register login items. |
| 2 | ✅ | **Real CLI screenshot:** full-screen capture produced a decodable 3456×2234 PNG using `--copy none --keep --silent --json`. The system clipboard was not changed by this CLI test. |
| 3 | ✅ | **Universal release:** both arm64 and x86_64 binaries built and were merged. Intel execution on real Intel hardware was not tested. |
| 4 | ✅ | **Signing:** the installed app has bundle identifier `com.olshansky.pbscreenshot`, Developer ID authority, team identity, resource sealing, and a valid deep/strict signature. |
| 5 | ✅ | **Native Settings:** the installed app opened its settings window, exposing enable/disable, startup, two shortcut recorders, Screen Recording state/actions, and Advanced options. Native controls expose text labels to accessibility tools. |
| 6 | ✅ | **Pause persistence:** disabled captures through the native switch, relaunched, and observed it still disabled in the UI and persisted preferences. Restored enabled after lifecycle tests. |
| 7 | ✅ | **Launch at login:** toggled on successfully, relaunched, and observed it still on without an approval/error warning. Toggled off afterward, matching its initial state. Actual logout/login was not performed. |
| 8 | ✅ | **Uninstall/reinstall:** stopped the app, ran `make uninstall`, verified the installed bundle was absent, reinstalled with `make install`, verified its signature, and reopened Settings. Pause state and the original Cmd+Shift+2 shortcut survived. |
| 9 | 🟡 | **Hotkey recording:** automation changed displayed field text but did not persist a shortcut. The attempted full-screen shortcut disappeared on relaunch and the original region binding was unchanged. This is an unverified native-event interaction, not a passing customization test. |
| 10 | 🟡 | **Menu bar capture and grant survival:** the new app displayed Permission needed. The user subsequently approved access, but computer control was blocked by the locked Mac; the permission was not changed. Capture under the app identity and grant survival across reinstalls remain unverified. |
| 11 | ✅ | **Static validation:** Info.plist parses, the release shell script passes shell syntax checking, and `git diff --check` passes. |
| 12 | 🟡 | **Toolchain workaround:** default Xcode commands are blocked by an unaccepted license; the CLT default build engine also failed. Native SwiftPM needed explicit framework, macro-plugin, and Xcode Swift runtime paths. These machine-specific overrides are saved locally, not imposed on the package defaults. |

The initial unmodified test command failed before executing tests; there is no claimed green baseline run.
The passing run used the Command Line Tools workaround.
The test linker warned that this toolchain's Testing framework targets macOS 14; the tests ran on macOS 27, not the app's minimum macOS 13.
A private-pasteboard test emitted a sandbox-extension warning, but the tested pasteboard contents were read back successfully.

## Remaining release checks

| # | Severity | Required verification |
|---|---|---|
| 1 | 🔴 | Configure a usable `pbscreenshot-notary` keychain profile, notarize the DMG, staple/validate its ticket, and test Gatekeeper on a downloaded copy. `notarytool history` explicitly reported that the profile's keychain item does not exist. |
| 2 | 🟠 | Grant Screen Recording to the signed installed app; test region capture, Escape cancellation, full-screen capture, clipboard attachment, revoke/regrant, app relaunch, and signed upgrade/reinstall persistence. |
| 3 | 🟠 | Manually record a custom hotkey, relaunch, and confirm it triggers the intended capture. Confirm pausing releases the shortcut for other apps and re-enabling restores it. |
| 4 | 🟡 | Test minimum macOS 13, Intel execution, real login startup, VoiceOver/keyboard traversal, and the menu bar icon/actions on a second Mac. Current native UI inspection is not a full accessibility audit. |
| 5 | 🟡 | Finish local Xcode setup before relying on unmodified build commands. No license was accepted on the user's behalf. |

## Local evidence and recovery

Local artifacts are intentionally under ignored `output/diagnostics/`:

- `preexisting.patch`: changes present before this task.
- `original-pbscreenshot.app`: original installed bundle backup.
- `original-preferences.plist`: original preference export.
- `original-signature.txt`, `installed-signature.txt`: before/after signing evidence.
- `tests.log`: the 21-test passing run.
- `cli-capture.json`, `cli-capture.stderr`, `cli-capture.png`: real CLI capture evidence; the PNG is local desktop content and is not included in publication files.
- `build-release.log`, `final-build-install.log`, `install.log`, `reinstall.log`, `doctor.log`: build/lifecycle logs. The first install log also records a corrected diagnostic verbosity issue before the successful install.
- `run-make.sh`: machine-specific toolchain override used for validation.

The app remains installed in `~/Applications/pbscreenshot.app`.
Preferences and TCC records were preserved during removal; no global permission reset, reboot, or logout was performed.
Changing between Developer ID and local ad-hoc builds can require a fresh grant. Stable-certificate builds should retain the same bundle identifier and signing team; ad-hoc rebuilds do not provide that continuity guarantee.
