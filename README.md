# pbscreenshot <!-- omit in toc -->

Screenshot straight to your clipboard **as a file**, not as pixels — so Claude Code, Slack, and email attach the image instead of pasting raw bytes.

```bash
make install
```

- [Why this exists](#why-this-exists)
- [Install](#install)
- [Windows](#windows)
- [Usage](#usage)
- [Permissions](#permissions)
- [Development](#development)
- [Architecture and diagnostics](#architecture-and-diagnostics)
- [How it works](#how-it-works)
- [Maintainer](#maintainer)
- [License](#license)

## Why this exists

`screencapture -c` puts **image bytes** on the clipboard. `pbcopy` puts **file contents**. Neither gives you what Finder's Cmd+C gives you: a *file reference*.

That difference is the whole point. CLI tools and chat apps that accept file attachments ignore raw bytes but happily accept a file reference. Without it, the workflow is: capture → find the file → drag it in. With it: press a key, paste.

| | On the clipboard | Claude Code paste |
|---|---|---|
| `screencapture -c` | Image bytes | ⚠️ Inconsistent |
| `pbcopy < shot.png` | File contents as text | ❌ Garbage |
| `pbscreenshot` | File reference | ✅ Attaches the image |

## Install

Local builds need macOS 13+ and a Swift 6+ toolchain, but **no Apple developer account, signing certificate, or notarization**.
Swift downloads the package dependencies on the first build; building, signing, and installing then happen locally.

Clone the repository:

```bash
git clone https://github.com/olshansk/pbscreenshot
```

Enter the project:

```bash
cd pbscreenshot
```

Build for this Mac and install to `~/Applications`:

```bash
make install
```

Build, install, and open the menu bar app:

```bash
make launch
```

The local app is ad-hoc signed with timestamping disabled; installation does not contact Apple's signing/notarization services.
An existing local signing identity can optionally be selected with `LOCAL_SIGN_ID`.
`make release` remains the separate universal, Developer ID–signed, notarized distribution workflow.
The Homebrew cask template is for that future distribution workflow.

| # | Severity | Local setup notes |
|---|---|---|
| 1 | 🟡 | Ad-hoc rebuilds can require Screen Recording approval again. A local build still needs macOS privacy consent. |
| 2 | 🟡 | If Xcode's unaccepted license blocks even `make`, use the verified fallback below on this workspace's Mac. It uses the installed Command Line Tools and Xcode framework/plugin files without changing global settings. |

Fallback for this Mac's toolchain setup (the prefix lets macOS start Make before Xcode's license check):

```bash
DEVELOPER_DIR=/Library/Developer/CommandLineTools make install-clt
```

## Windows

A separate native Windows tray app and self-contained per-user installer are available from the [Windows CI workflow](https://github.com/Olshansk/pbscreenshot/actions/workflows/desktop.yml).
See [Windows installation, build targets, architecture, and limitations](docs/windows.md).
On Windows, `make install` builds the installer and installs it.
No Apple account or .NET runtime installation is needed to run the packaged app.

## Usage

Press **Cmd+Shift+2**, select a region, then paste. That's the whole tool.

The same thing from the CLI:

The source install bundles the CLI at `~/Applications/pbscreenshot.app/Contents/MacOS/pbscreenshot`.
Use that path directly; the short command examples below assume the CLI is on your `PATH`.

```bash
pbscreenshot
```

Capture without the crosshair:

```bash
pbscreenshot --mode full
pbscreenshot --mode window
```

Save somewhere permanent:

```bash
pbscreenshot --output ~/Desktop/bug.png
```

Put the path on the clipboard as plain text instead of a file reference:

```bash
pbscreenshot --copy path
```

Script it — exit code `2` means the user pressed Esc, so cancellation is not an error:

```bash
if path=$(pbscreenshot --quiet --json | jq -r .path); then
  echo "captured $path"
fi
```

Use **Enable pbscreenshot** in the menu to pause/resume captures. Open **Settings** from the menu or reopen the app in Finder to edit hotkeys and enable **Launch at login**. Clipboard format, shutter sound, and retention live under **Advanced**.

## Permissions

**Screen Recording** — open Settings and select **Allow Screen Recording**. If permission was previously denied, enable pbscreenshot in System Settings → Privacy & Security → Screen Recording (the name varies by macOS version). Return to the app or select **Check Again**. If macOS still reports no access, quit and reopen the installed app. A CLI launched from a terminal may use the terminal’s permission context rather than the menu bar app’s grant.

**Accessibility — not required.** The hotkey uses Carbon's `RegisterEventHotKey` rather than a CGEvent tap. Beyond skipping a permission dialog, this avoids a genuinely nasty failure mode: a stale Accessibility grant lets tap creation *succeed* while the tap silently receives nothing, so your hotkey dies with no error anywhere. That can't happen here.

One consequence worth knowing: an app that *does* run a CGEvent tap sees keystrokes before Carbon hotkeys do. If another tool is grabbing Cmd+Shift+2, it wins — rebind one of them.

## Development

```bash
make help
```

| Target | Does |
|---|---|
| `make build` | Debug build |
| `make test` | Run the suite |
| `make install` | Build and install locally without a certificate |
| `make install-clt` | Build and install with the Command Line Tools fallback |
| `make launch` | Build, install to `~/Applications`, launch |
| `make app` | Assemble `dist/pbscreenshot.app` (universal) |
| `make release` | Build → sign → DMG → notarize → print cask |
| `make doctor` | Check signing identity, notary profile, `create-dmg` |

The package builds four targets: `PBScreenshotKit` (portable types/storage), `PBScreenshotMacOS` (native adapters), `pbscreenshot` (CLI), and `pbscreenshot-agent` (menu bar). The CLI ships *inside* the app bundle, so the cask installs both and they can never drift.

## Architecture and diagnostics

See [the full source tree and target boundaries](docs/architecture.md), [the desktop CI diagnostic report](docs/diagnostics-2026-10-11.md), and [the earlier macOS permission investigation](docs/diagnostics-2026-10-04.md).
macOS and Windows have native apps; Linux remains an unimplemented adapter boundary.

Local installation uses an ad-hoc signature by default; production signing stays in `make release`.
`make launch` builds, signs locally, installs, and opens the app.
Before `make uninstall`, turn off **Launch at login** in Settings. Uninstall preserves preferences and macOS permission records.

## How it works

```swift
pasteboard.clearContents()
pasteboard.writeObjects([fileURL as NSURL])
```

That's it. Everything else — `/usr/sbin/screencapture` for the native selection UI, a temp file, TTL cleanup that runs *after* the capture so it never delays the crosshair — exists to serve those two lines.

## Maintainer

Name: `MAINTAINER_NAME` (placeholder).

Email: `MAINTAINER_EMAIL` (placeholder).

## License

MIT
