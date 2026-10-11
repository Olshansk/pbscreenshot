param([switch]$Uninstall)
$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '../..')
$installed = Join-Path $env:LOCALAPPDATA 'Programs/pbscreenshot'
if ($Uninstall) {
    $executable = Join-Path $installed 'unins000.exe'
    if (!(Test-Path $executable)) { throw 'pbscreenshot is not installed for this user.' }
    $arguments = '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART'
} else {
    $executable = Join-Path $PWD 'dist/windows/pbscreenshot-setup-win-x64.exe'
    if (!(Test-Path $executable)) { throw 'Run make windows-package first.' }
    $arguments = '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART'
}
$process = Start-Process -FilePath $executable -ArgumentList $arguments -Wait -PassThru
if ($process.ExitCode -ne 0) { throw "Installer exited with $($process.ExitCode)" }
