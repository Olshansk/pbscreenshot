using PBScreenshot.App;

internal static class Program
{
    [STAThread]
    private static void Main()
    {
        ApplicationConfiguration.Initialize();
        using var singleInstance = new Mutex(true, @"Local\Olshansky.pbscreenshot", out var created);
        if (!created) { MessageBox.Show("pbscreenshot is already running. Open Settings from its system tray icon.", "pbscreenshot"); return; }
        try { using var tray = new TrayApplication(); Application.Run(tray); }
        catch (Exception error) { MessageBox.Show(error.Message, "pbscreenshot", MessageBoxButtons.OK, MessageBoxIcon.Error); }
    }
}
