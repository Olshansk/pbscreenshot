# pbscreenshot <!-- omit in toc -->

Screenshot straight to your clipboard **as a file**, not as pixels — so Claude Code, Slack, and email attach the image instead of pasting raw bytes.

```bash
brew install --cask olshansk/tap/pbscreenshot
```

- [Why this exists](#why-this-exists)
- [Install](#install)
- [Usage](#usage)
- [Permissions](#permissions)
- [Development](#development)
- [How it works](#how-it-works)
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

Homebrew (recommended) — installs the menu bar app and puts the CLI on your `PATH`:

```bash
brew install --cask olshansk/tap/pbscreenshot
```

From source:

```bash
git clone https://github.com/olshansk/pbscreenshot && cd pbscreenshot && make launch
```

## Usage

Press **Cmd+Shift+2**, select a region, then paste. That's the whole tool.

The same thing from the CLI:

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

Rebind the hotkey, change the clipboard format, or set the temp-file retention in **Settings** from the menu bar icon.

## Permissions

**Screen Recording** — required, and macOS prompts for it the first time you capture. Any screenshot tool needs this.

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
| `make launch` | Build, install to `~/Applications`, launch |
| `make app` | Assemble `dist/pbscreenshot.app` (universal) |
| `make release` | Build → sign → DMG → notarize → print cask |
| `make doctor` | Check signing identity, notary profile, `create-dmg` |

The package builds three targets: `PBScreenshotKit` (all logic), `pbscreenshot` (CLI), and `pbscreenshot-agent` (menu bar). The CLI ships *inside* the app bundle, so the cask installs both and they can never drift.

## How it works

```swift
pasteboard.clearContents()
pasteboard.writeObjects([fileURL as NSURL])
```

That's it. Everything else — `/usr/sbin/screencapture` for the native selection UI, a temp file, TTL cleanup that runs *after* the capture so it never delays the crosshair — exists to serve those two lines.

## License

MIT
