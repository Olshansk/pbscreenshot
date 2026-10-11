# Linux adapter boundary <!-- omit in toc -->

No Linux application ships yet. `PBScreenshotKit` contains the portable capture types and temporary-file storage.

- [Implementation scope](#implementation-scope)

## Implementation scope

A Linux release needs native capture and clipboard adapters, desktop hotkeys, screen-capture consent, startup registration, and a tray/settings shell.
Keep those implementations here and in a future `Sources/App/Linux` target.
Do not import macOS frameworks into `Sources/Core`.
