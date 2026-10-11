using Shortcut = PBScreenshot.Core.Config.Shortcut;
using System.ComponentModel;
using System.Runtime.InteropServices;
using PBScreenshot.Core.Config;

namespace PBScreenshot.Native.Hotkeys;

public sealed class GlobalHotkeys : NativeWindow, IDisposable
{
    public event Action<bool>? Pressed;
    private Settings current = new() { Enabled = false };

    public GlobalHotkeys() => CreateHandle(new CreateParams { Caption = "pbscreenshot hotkeys" });

    public void Apply(Settings settings)
    {
        settings.Validate();
        Clear();
        try { Register(settings); }
        catch
        {
            Clear();
            try { Register(current); } catch { Clear(); }
            throw;
        }
        current = settings;
    }

    private void Register(Settings settings)
    {
        if (!settings.Enabled) return;
        Bind(1, settings.Region);
        Bind(2, settings.Full);
    }

    private void Bind(int id, Shortcut shortcut)
    {
        if (!RegisterHotKey(Handle, id, shortcut.Modifiers | 0x4000, shortcut.Key))
            throw new Win32Exception(Marshal.GetLastWin32Error(), "Shortcut unavailable. Another application may be using it; choose a different shortcut.");
    }

    private void Clear() { UnregisterHotKey(Handle, 1); UnregisterHotKey(Handle, 2); }
    protected override void WndProc(ref Message message)
    {
        if (message.Msg == 0x0312) Pressed?.Invoke(message.WParam.ToInt32() == 1);
        base.WndProc(ref message);
    }
    public void Dispose() { Clear(); DestroyHandle(); }

    [DllImport("user32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool RegisterHotKey(IntPtr window, int id, uint modifiers, uint key);
    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool UnregisterHotKey(IntPtr window, int id);
}
