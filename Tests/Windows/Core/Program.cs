using PBScreenshot.Core.Config;

var directory = Path.Combine(Path.GetTempPath(), "pbscreenshot-tests-" + Guid.NewGuid());
Directory.CreateDirectory(directory);
try
{
    var path = Path.Combine(directory, "settings.json");
    var store = new SettingsStore(path);
    Assert(store.Load() == new Settings(), "first-run defaults");
    var changed = new Settings { Enabled = false, Region = new(3, 0x41) };
    store.Save(changed);
    Assert(new SettingsStore(path).Load() == changed, "settings survive restart/reinstall");
    try { store.Save(changed with { Full = changed.Region }); throw new Exception("Duplicate accepted"); }
    catch (InvalidDataException) { }
    Assert(store.Load() == changed, "invalid edit preserves previous settings");
    File.WriteAllText(path, "broken json");
    try { store.Load(); throw new Exception("Corruption accepted"); }
    catch (System.Text.Json.JsonException) { }
    Assert(File.ReadAllText(path) == "broken json", "corrupt file preserved");
    Assert(!new Shortcut(0, 0x41).IsValid && !new Shortcut(6, 0).IsValid, "invalid shortcuts rejected");
    Console.WriteLine("PASS: 6 settings and validation checks");
}
finally { Directory.Delete(directory, true); }

static void Assert(bool condition, string message)
{
    if (!condition) throw new Exception(message);
    Console.WriteLine("PASS: " + message);
}
