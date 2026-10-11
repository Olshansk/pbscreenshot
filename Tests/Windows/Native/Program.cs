using PBScreenshot.Core.Config;
using PBScreenshot.Native.Capture;
using PBScreenshot.Native.Clipboard;
using PBScreenshot.Native.Hotkeys;
using PBScreenshot.Native.Startup;

internal static class Program
{
    [STAThread]
    private static void Main()
    {
        Application.SetHighDpiMode(HighDpiMode.PerMonitorV2);
        var path = Path.Combine(Path.GetTempPath(), $"pbscreenshot-native-{Guid.NewGuid()}.png");
        var login = new LoginItem(Environment.ProcessPath!, "pbscreenshot-ci-" + Guid.NewGuid());
        try
        {
            ScreenCapture.Save(SystemInformation.VirtualScreen, path);
            using (var image = Image.FromFile(path))
                Assert(image.Width == SystemInformation.VirtualScreen.Width && image.Height == SystemInformation.VirtualScreen.Height, "real desktop PNG dimensions");
            FileClipboard.Copy(path);
            Assert(Clipboard.GetFileDropList().Contains(path), "native file-reference clipboard round trip");
            using var first = new GlobalHotkeys();
            var settings = new Settings { Region = new(7, 0x7A), Full = new(7, 0x7B) };
            first.Apply(settings);
            using var second = new GlobalHotkeys();
            try { second.Apply(settings); throw new Exception("Hotkey conflict was not reported"); }
            catch (System.ComponentModel.Win32Exception) { Console.WriteLine("PASS: native hotkey conflict reported"); }
            first.Apply(settings with { Enabled = false });
            second.Apply(settings);
            Console.WriteLine("PASS: disabling releases native hotkeys");
            login.Enabled = true;
            Assert(login.Enabled, "startup registered");
            login.Enabled = false;
            Assert(!login.Enabled, "startup removed");
            using var region = new RegionSelector();
            Assert(region.Bounds == SystemInformation.VirtualScreen, "region overlay covers virtual desktop");
        }
        finally { login.Enabled = false; Clipboard.Clear(); File.Delete(path); }
    }
    private static void Assert(bool condition, string message)
    {
        if (!condition) throw new Exception(message);
        Console.WriteLine("PASS: " + message);
    }
}
