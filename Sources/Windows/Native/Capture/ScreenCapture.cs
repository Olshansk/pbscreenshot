using System.Drawing.Imaging;
using PBScreenshot.Native.Permissions;

namespace PBScreenshot.Native.Capture;

public static class ScreenCapture
{
    public static string Save(Rectangle bounds, string? destination = null)
    {
        DesktopAccess.Check();
        if (bounds.Width <= 0 || bounds.Height <= 0) throw new ArgumentException("Select a non-empty area.");
        var directory = Path.Combine(Path.GetTempPath(), "pbscreenshot");
        destination ??= Path.Combine(directory, $"capture-{DateTime.UtcNow:yyyyMMdd-HHmmss}-{Guid.NewGuid():N}.png");
        Directory.CreateDirectory(Path.GetDirectoryName(Path.GetFullPath(destination))!);
        using var bitmap = new Bitmap(bounds.Width, bounds.Height);
        using (var graphics = Graphics.FromImage(bitmap))
            graphics.CopyFromScreen(bounds.Location, Point.Empty, bounds.Size, CopyPixelOperation.SourceCopy);
        bitmap.Save(destination, ImageFormat.Png);
        // Keep recent captures alive so file references remain pasteable.
        if (Directory.Exists(directory))
            foreach (var file in Directory.EnumerateFiles(directory, "capture-*.png"))
                try { if (File.GetLastWriteTimeUtc(file) < DateTime.UtcNow.AddDays(-7)) File.Delete(file); }
                catch (IOException) { } catch (UnauthorizedAccessException) { }
        return Path.GetFullPath(destination);
    }
}
