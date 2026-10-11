using PBScreenshot.Core.Config;
using PBScreenshot.Native.Capture;
using PBScreenshot.Native.Clipboard;
using PBScreenshot.Native.Hotkeys;
using PBScreenshot.Native.Startup;
using PBScreenshot.App.SettingsUI;

namespace PBScreenshot.App;

internal sealed class TrayApplication : ApplicationContext
{
    private readonly SettingsStore store = new(SettingsStore.DefaultPath);
    private Settings settings = new();
    private readonly GlobalHotkeys hotkeys = new();
    private readonly LoginItem login = new(Environment.ProcessPath!);
    private readonly NotifyIcon tray;
    private readonly ToolStripMenuItem enabled = new("Enabled");
    private SettingsForm? window;
    private bool capturing;

    public TrayApplication()
    {
        string? warning = null;
        try { settings = store.Load(); }
        catch (Exception error) { warning = $"Could not load settings: {error.Message}\nYour settings file has been preserved."; settings = new() { Enabled = false }; }
        try { hotkeys.Apply(settings); }
        catch (Exception error) { warning = error.Message; settings = settings with { Enabled = false }; }
        var menu = new ContextMenuStrip();
        menu.Items.Add(enabled);
        enabled.Click += (_, _) => Run(() => Apply(settings with { Enabled = !settings.Enabled }));
        menu.Items.Add("Capture region", null, (_, _) => Capture(true));
        menu.Items.Add("Capture full screen", null, (_, _) => Capture(false));
        menu.Items.Add("Settings…", null, (_, _) => ShowSettings());
        menu.Items.Add(new ToolStripSeparator());
        menu.Items.Add("Quit", null, (_, _) => ExitThread());
        tray = new NotifyIcon { Icon = SystemIcons.Application, Text = "pbscreenshot", ContextMenuStrip = menu, Visible = true };
        tray.DoubleClick += (_, _) => ShowSettings();
        hotkeys.Pressed += Capture;
        RefreshStatus();
        if (warning is not null) { ShowSettings(); MessageBox.Show(warning, "pbscreenshot", MessageBoxButtons.OK, MessageBoxIcon.Warning); }
    }

    private void Apply(Settings next)
    {
        hotkeys.Apply(next);
        try { store.Save(next); }
        catch { hotkeys.Apply(settings); throw; }
        settings = next;
        RefreshStatus();
    }

    private void RefreshStatus()
    {
        enabled.Checked = settings.Enabled;
        tray.Text = settings.Enabled ? "pbscreenshot — enabled" : "pbscreenshot — paused";
    }

    private void ShowSettings()
    {
        if (window is null || window.IsDisposed)
            {
            window = new SettingsForm(() => settings, Apply, login);
            window.Activated += (_, _) => hotkeys.Apply(settings with { Enabled = false });
            window.Deactivate += (_, _) => Run(() => hotkeys.Apply(settings));
        }
        window.Reload();
        window.Show();
        window.WindowState = FormWindowState.Normal;
        window.Activate();
    }

    private async void Capture(bool region)
    {
        if (!settings.Enabled || capturing) return;
        capturing = true;
        try
        {
            var bounds = SystemInformation.VirtualScreen;
            if (region)
            {
                using var selector = new RegionSelector();
                if (selector.ShowDialog() != DialogResult.OK) return;
                bounds = selector.Selection;
            }
            // Let the overlay or tray menu leave the compositor before capture.
            await Task.Delay(180);
            FileClipboard.Copy(ScreenCapture.Save(bounds));
        }
        catch (Exception error) { MessageBox.Show(error.Message, "Capture failed", MessageBoxButtons.OK, MessageBoxIcon.Error); }
        finally { capturing = false; }
    }

    private static void Run(Action action)
    {
        try { action(); }
        catch (Exception error) { MessageBox.Show(error.Message, "pbscreenshot", MessageBoxButtons.OK, MessageBoxIcon.Error); }
    }

    protected override void Dispose(bool disposing)
    {
        if (disposing) { tray.Visible = false; tray.Dispose(); hotkeys.Dispose(); window?.Dispose(); }
        base.Dispose(disposing);
    }
}
