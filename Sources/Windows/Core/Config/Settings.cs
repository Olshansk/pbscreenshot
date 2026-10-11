using System.Text.Json;

namespace PBScreenshot.Core.Config;

public sealed record Shortcut(uint Modifiers, uint Key)
{
    public bool IsValid => Modifiers is > 0 and <= 15 &&
        (Key is >= 0x30 and <= 0x39 or >= 0x41 and <= 0x5A or >= 0x70 and <= 0x87);
}

public sealed record Settings
{
    public bool Enabled { get; init; } = true;
    public Shortcut Region { get; init; } = new(6, 0x32); // Ctrl+Shift+2
    public Shortcut Full { get; init; } = new(6, 0x33); // Ctrl+Shift+3

    public void Validate()
    {
        if (Region is null || Full is null || !Region.IsValid || !Full.IsValid || Region == Full)
            throw new InvalidDataException("Choose two different shortcuts, each with a modifier and a letter, number, or function key.");
    }
}

public sealed class SettingsStore(string path)
{
    public static string DefaultPath => Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "pbscreenshot", "settings.json");

    public Settings Load()
    {
        if (!File.Exists(path)) return new();
        var settings = JsonSerializer.Deserialize<Settings>(File.ReadAllText(path))
            ?? throw new InvalidDataException("Settings file is empty.");
        settings.Validate();
        return settings;
    }

    public void Save(Settings settings)
    {
        settings.Validate();
        Directory.CreateDirectory(Path.GetDirectoryName(Path.GetFullPath(path))!);
        var pending = path + ".new";
        File.WriteAllText(pending, JsonSerializer.Serialize(settings, new JsonSerializerOptions { WriteIndented = true }));
        File.Move(pending, path, true);
    }
}
