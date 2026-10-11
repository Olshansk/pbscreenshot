using Shortcut = PBScreenshot.Core.Config.Shortcut;
using PBScreenshot.Core.Config;

namespace PBScreenshot.App.SettingsUI;

internal sealed class ShortcutBox : TextBox
{
    public Shortcut Shortcut { get; private set; } = new(6, 0x32);
    public ShortcutBox()
    {
        ReadOnly = true;
        Width = 240;
        AccessibleDescription = "Press Control, Alt, or Shift together with a letter, number, or function key.";
        KeyDown += (_, e) =>
        {
            e.SuppressKeyPress = true;
            var shortcut = new Shortcut((uint)((e.Alt ? 1 : 0) | (e.Control ? 2 : 0) | (e.Shift ? 4 : 0)), (uint)e.KeyCode);
            if (shortcut.IsValid) Set(shortcut);
        };
    }

    public void Set(Shortcut shortcut)
    {
        Shortcut = shortcut;
        Text = ((shortcut.Modifiers & 2) != 0 ? "Ctrl+" : "") +
               ((shortcut.Modifiers & 1) != 0 ? "Alt+" : "") +
               ((shortcut.Modifiers & 4) != 0 ? "Shift+" : "") +
               ((shortcut.Modifiers & 8) != 0 ? "Win+" : "") +
               ((Keys)shortcut.Key).ToString();
    }
}
