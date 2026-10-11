# Capture the real installer UI on the disposable Windows CI desktop.
$ErrorActionPreference = 'Stop'
if ($env:GITHUB_ACTIONS -ne 'true' -or $env:RUNNER_OS -ne 'Windows') {
    throw 'Installer screenshot capture is restricted to the disposable Windows CI VM.'
}
Set-Location (Join-Path $PSScriptRoot '../..')
Add-Type -AssemblyName System.Drawing
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class InstallerWindow {
    [StructLayout(LayoutKind.Sequential)]
    public struct Rect { public int Left, Top, Right, Bottom; }
    [DllImport("user32.dll")]
    public static extern bool GetWindowRect(IntPtr window, out Rect rect);
    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr window);
    [DllImport("user32.dll")]
    public static extern bool SetProcessDPIAware();
}
'@
[InstallerWindow]::SetProcessDPIAware() | Out-Null
$installer = Join-Path $PWD 'dist/windows/pbscreenshot-setup-win-x64.exe'
$setup = Start-Process $installer -ArgumentList '/SP- /NORESTART' -PassThru
try {
    $deadline = (Get-Date).AddSeconds(30)
    do {
        $window = Get-Process | Where-Object {
            $_.ProcessName -like 'pbscreenshot*' -and $_.MainWindowTitle -like '*pbscreenshot*'
        } | Select-Object -First 1
        if ($window) { break }
        Start-Sleep -Milliseconds 200
    } while ((Get-Date) -lt $deadline)
    if (!$window) { throw 'Installer window did not appear.' }
    [InstallerWindow]::SetForegroundWindow($window.MainWindowHandle) | Out-Null
    Start-Sleep -Seconds 1
    $rect = New-Object InstallerWindow+Rect
    if (![InstallerWindow]::GetWindowRect($window.MainWindowHandle, [ref]$rect)) { throw 'Could not locate installer window.' }
    $width = $rect.Right - $rect.Left
    $height = $rect.Bottom - $rect.Top
    if ($width -lt 300 -or $height -lt 200) { throw 'Unexpected installer window size.' }
    $bitmap = New-Object System.Drawing.Bitmap($width, $height)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    try {
        $graphics.CopyFromScreen($rect.Left, $rect.Top, 0, 0, $bitmap.Size)
        $directory = New-Item -ItemType Directory -Force 'dist/windows/evidence'
        $destination = Join-Path $directory.FullName 'windows-installation.png'
        $bitmap.Save($destination, [System.Drawing.Imaging.ImageFormat]::Png)
        Write-Host "PASS: captured actual installer window '$($window.MainWindowTitle)' to $destination"
    } finally {
        $graphics.Dispose()
        $bitmap.Dispose()
    }
} finally {
    # Inno's bootstrapper launches a child wizard; close both test processes.
    if ($window -and !$window.HasExited) { Stop-Process -Id $window.Id -Force }
    $setup.Refresh()
    if (!$setup.HasExited) { Stop-Process -Id $setup.Id -Force }
    Start-Sleep -Seconds 1
}
