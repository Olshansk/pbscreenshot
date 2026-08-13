# NEXT — pbscreenshot pickup notes <!-- omit in toc -->

Written 2026-08-13. Everything builds, signs, and installs; the one thing never verified end-to-end is an actual pixel capture.

- [State of things](#state-of-things)
- [1. Verify the hotkey end-to-end](#1-verify-the-hotkey-end-to-end)
- [2. Cut the first release](#2-cut-the-first-release)
- [3. Publish the cask](#3-publish-the-cask)
- [4. Loose ends](#4-loose-ends)
- [Decisions worth not re-litigating](#decisions-worth-not-re-litigating)

## State of things

| # | Status | Item |
|---|---|---|
| 1 | ✅ | SPM package: `PBScreenshotKit` + `pbscreenshot` (CLI) + `pbscreenshot-agent` (menu bar) |
| 2 | ✅ | 16 tests passing (`make test`) |
| 3 | ✅ | Universal bundle assembled and Developer ID signed with hardened runtime |
| 4 | ✅ | Installed and running from `~/Applications/pbscreenshot.app` |
| 5 | ⚠️ | **No real screenshot has ever been captured by this code** — see below |
| 6 | ❌ | Not notarized, no DMG, no cask published, no git commit |

**The untested part:** `screencapture` needs Screen Recording, which the shell doing the development lacked (`could not create image from display`). Capture logic is tested against stand-in binaries (`/usr/bin/true`, `touch`, `false`) covering the cancel, success, and failure paths — but never against a real display. Assume the capture path works; verify it before releasing.

## 1. Verify the hotkey end-to-end

Two gotchas will make a working build look broken:

1. **ClaudeCompanion must not be running.** Its CGEvent tap sits at the head of the event chain and swallows Cmd+Shift+2 before Carbon hotkeys see it. Run `make kill` in `claude_companion` first, or rebind one of the two.
2. **Screen Recording** must be granted to `pbscreenshot.app` — macOS should prompt on first capture.

```bash
make launch
```

Then press Cmd+Shift+2, drag a region, and paste into Claude Code with **Ctrl+V** (not Cmd+V). Success means the image attaches rather than pasting as text or pixels.

Also worth a pass: `pbscreenshot --mode full`, `--copy path`, and Esc during region select (should exit `2` and print nothing).

## 2. Cut the first release

Prerequisites, both one-time:

```bash
xcrun notarytool store-credentials pbscreenshot-notary --apple-id <your-apple-id> --team-id G5YQ84295L --password <app-specific-password>
```

```bash
brew install create-dmg
```

Confirm readiness, then run the pipeline:

```bash
make doctor
```

```bash
make release
```

`release` chains app → sign → dmg → notarize → cask, and prints the ready-to-paste cask block with the version and sha256 filled in. Notarization takes a few minutes.

## 3. Publish the cask

1. Create `github.com/olshansk/homebrew-tap` if it doesn't exist (I couldn't check — `gh` is broken in this shell, see loose ends).
2. Create `github.com/olshansk/pbscreenshot`, push, and tag `v0.1.0`.
3. Attach `dist/pbscreenshot-0.1.0.dmg` to the GitHub release — the cask URL points at that exact path.
4. Copy the `make cask` output into `Casks/pbscreenshot.rb` in the tap.
5. Verify from a clean angle: `brew install --cask olshansk/tap/pbscreenshot`.

Template lives at `packaging/pbscreenshot.rb` with `@VERSION@` / `@SHA256@` placeholders.

## 4. Loose ends

| # | Severity | Item | Note |
|---|---|---|---|
| 1 | 🟡 | Git branch is `master`, no commits yet | Your other repos use `main` — rename before the first push |
| 2 | 🟡 | No app icon | `Resources/` holds only `Info.plist`; the menu bar uses the `camera.viewfinder` SF Symbol. Fine until it's in `/Applications` next to real icons |
| 3 | 🟡 | `CaptureMode.isCancellable` is dead code | `Sources/PBScreenshotKit/Capture.swift:21` — referenced only by tests. Either use it (CLI could treat "cancelled" from `--mode full` as an error, since full-screen can't be cancelled) or delete it |
| 4 | 🟢 | `make app` wipes the signature | Correct by design — assemble, then sign. Just don't run `app` after `sign` and expect it to still be signed |
| 5 | 🟢 | `gh` CLI errors in zsh | `gh:3: _completion_loaded: assignment to invalid subscript range` — a broken completion in `~/workspace/configs/zshrc.d/`, unrelated to this repo but it blocks scripted GitHub work |
| 6 | 🟢 | Phase 6 (GitHub Actions release automation) not started | Plan has the shape; deferred deliberately until the manual release works once |

## Decisions worth not re-litigating

- **No Accessibility permission, by design.** The hotkey uses Carbon `RegisterEventHotKey` via `sindresorhus/KeyboardShortcuts`, not a CGEvent tap. This came directly out of debugging ClaudeCompanion on 2026-08-12, where three conflicting TCC records accumulated under one bundle ID and every hotkey went silently deaf — `tapCreate` succeeded and simply received nothing. The trade-off is no `fn`-key combos, which this tool doesn't need.
- **Cleanup runs after capture, never before.** A temp-dir scan has variable cost that grows with unrelated junk from other apps; it must not sit in front of the crosshair. The original in `ScreenshotInterceptor.swift` had this backwards.
- **Signing identity is resolved from the keychain, not hardcoded.** The Developer ID cert reads `Daniel Olshasnky` — a typo in the Apple Developer account. `claude_companion/Makefile:11` hardcodes the correctly-spelled name and would fail to sign. Fixing the typo means requesting a new certificate from Apple; the dynamic lookup sidesteps it either way.
- **The CLI ships inside the app bundle.** One cask installs both, so the app and CLI can never drift to different versions.
