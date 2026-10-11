# Destructive lifecycle test is restricted to a disposable CI user profile.
$ErrorActionPreference = 'Stop'
if ($env:GITHUB_ACTIONS -ne 'true' -or $env:RUNNER_OS -ne 'Windows') {
    throw 'Run this lifecycle test only on a disposable GitHub Actions Windows runner.'
}
Set-Location (Join-Path $PSScriptRoot '../..')
$installed = Join-Path $env:LOCALAPPDATA 'Programs/pbscreenshot/pbscreenshot.exe'
$settings = Join-Path $env:LOCALAPPDATA 'pbscreenshot/settings.json'
$runKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
& "$PSScriptRoot/install.ps1"
if (!(Test-Path $installed)) { throw 'Installed executable missing' }
New-Item -ItemType Directory -Force (Split-Path $settings) | Out-Null
$sample = '{"Enabled":false,"Region":{"Modifiers":6,"Key":50},"Full":{"Modifiers":6,"Key":51}}'
Set-Content $settings $sample
if (!(Test-Path $runKey)) { New-Item $runKey -Force | Out-Null }
New-ItemProperty $runKey -Name pbscreenshot -Value ('"' + $installed + '"') -Force | Out-Null
function Test-AppLaunch {
    $app = Start-Process $installed -PassThru
    try {
        Start-Sleep -Seconds 3
        $app.Refresh()
        if ($app.HasExited) { throw 'Installed tray application exited unexpectedly' }
        if (!$app.WaitForInputIdle(10000)) { throw 'Installed application did not initialize its message loop' }
        if ($app.MainWindowHandle -ne 0) { throw 'Unexpected startup window or error dialog' }
        Write-Host 'PASS: installed self-contained app starts and enters its message loop'
    } finally {
        if (!$app.HasExited) { Stop-Process -Id $app.Id -Force; $app.WaitForExit() }
    }
}
Test-AppLaunch
& "$PSScriptRoot/install.ps1" -Uninstall
if (Test-Path $installed) { throw 'Uninstall left installed executable' }
if ((Get-ItemProperty $runKey -Name pbscreenshot -ErrorAction SilentlyContinue)) { throw 'Uninstall left startup registration' }
if ((Get-Content $settings -Raw).Trim() -ne $sample) { throw 'Uninstall changed user preferences' }
& "$PSScriptRoot/install.ps1"
if ((Get-Content $settings -Raw).Trim() -ne $sample) { throw 'Reinstall changed user preferences' }
Test-AppLaunch
& "$PSScriptRoot/install.ps1" -Uninstall
Write-Host 'PASS: install, launch, startup cleanup, uninstall, settings preservation, reinstall, relaunch'
