using PBScreenshot.Core.Config;
using PBScreenshot.Native.Startup;
using PBScreenshot.Native.Permissions;

namespace PBScreenshot.App.SettingsUI;

internal sealed class SettingsForm : Form
{
    private readonly CheckBox enabled = new() { Text = "Enable pbscreenshot", AutoSize = true };
    private readonly CheckBox startup = new() { Text = "Launch when I sign in", AutoSize = true };
    private readonly ShortcutBox region = new() { AccessibleName = "Region shortcut" };
    private readonly ShortcutBox full = new() { AccessibleName = "Full screen shortcut" };
    private readonly Func<Settings> read;
    private readonly Action<Settings> save;
    private readonly LoginItem login;

    public SettingsForm(Func<Settings> read, Action<Settings> save, LoginItem login)
    {
        this.read = read; this.save = save; this.login = login;
        Text = "pbscreenshot Settings";
        ClientSize = new Size(490, 340);
        MinimumSize = new Size(480, 380);
        AutoScaleMode = AutoScaleMode.Dpi;
        StartPosition = FormStartPosition.CenterScreen;
        var layout = new FlowLayoutPanel { Dock = DockStyle.Fill, FlowDirection = FlowDirection.TopDown, WrapContents = false, Padding = new Padding(20), AutoScroll = true };
        layout.Controls.Add(enabled);
        layout.Controls.Add(startup);
        layout.Controls.Add(new Label { Text = "Region shortcut (click, then press keys)", AutoSize = true, Margin = new Padding(3, 14, 3, 3) });
        layout.Controls.Add(region);
        layout.Controls.Add(new Label { Text = "Full screen shortcut", AutoSize = true });
        layout.Controls.Add(full);
        var apply = new Button { Text = "Save", AutoSize = true };
        apply.Click += (_, _) => Save();
        layout.Controls.Add(apply);
        layout.Controls.Add(new Label { Text = DesktopAccess.Description, AutoSize = true, MaximumSize = new Size(430, 0) });
        Controls.Add(layout);
        AcceptButton = apply;
    }

    public void Reload()
    {
        var settings = read();
        enabled.Checked = settings.Enabled;
        startup.Checked = login.Enabled;
        region.Set(settings.Region);
        full.Set(settings.Full);
    }

    private void Save()
    {
        try
        {
            var previousStartup = login.Enabled;
            login.Enabled = startup.Checked;
            try { save(new Settings { Enabled = enabled.Checked, Region = region.Shortcut, Full = full.Shortcut }); }
            catch { login.Enabled = previousStartup; throw; }
            Hide();
        }
        catch (Exception error) { MessageBox.Show(this, error.Message, "Could not save settings", MessageBoxButtons.OK, MessageBoxIcon.Error); }
    }
}
