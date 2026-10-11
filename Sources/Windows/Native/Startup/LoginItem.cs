using Microsoft.Win32;

namespace PBScreenshot.Native.Startup;

public sealed class LoginItem(string executable, string name = "pbscreenshot")
{
    private const string RunKey = @"Software\Microsoft\Windows\CurrentVersion\Run";
    private string Command => $"\"{executable}\"";
    public bool Enabled
    {
        get { using var key = Registry.CurrentUser.OpenSubKey(RunKey); return key?.GetValue(name) as string == Command; }
        set
        {
            using var key = Registry.CurrentUser.CreateSubKey(RunKey);
            if (value) key.SetValue(name, Command); else key.DeleteValue(name, false);
            if (Enabled != value) throw new IOException("Windows did not save the startup setting.");
        }
    }
}
