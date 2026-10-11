# Windows implementation <!-- omit in toc -->

The native Windows implementation lives in separate .NET projects under `Sources/Windows`.
See [Windows architecture, installation, and validation](../../../docs/windows.md).

- [Dependencies](#dependencies)

## Dependencies

`App → Native → Core`: the tray/settings shell depends on Win32/Windows Forms adapters, which depend on portable C# configuration.
These projects do not depend on the Swift package or macOS frameworks.
