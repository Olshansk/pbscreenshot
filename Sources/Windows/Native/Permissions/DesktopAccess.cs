namespace PBScreenshot.Native.Permissions;

public static class DesktopAccess
{
    public const string Description = "No Accessibility or Screen Recording approval is needed on Windows. Capture requires an unlocked desktop. Protected content and the sign-in screen cannot be captured.";
    public static void Check()
    {
        if (!Environment.UserInteractive || SystemInformation.VirtualScreen.Width <= 0)
            throw new InvalidOperationException("Capture requires an interactive Windows desktop.");
    }
}
