$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '../..')
dotnet publish Sources/Windows/App/PBScreenshot.App.csproj -c Release -r win-x64 --self-contained true -o dist/windows/app
if ($LASTEXITCODE -ne 0) { throw 'Windows publish failed' }
$compiler = Join-Path ${env:ProgramFiles(x86)} 'Inno Setup 6/ISCC.exe'
if (!(Test-Path $compiler)) { throw 'Install Inno Setup 6 to create the Windows installer.' }
& $compiler packaging/windows/pbscreenshot.iss
if ($LASTEXITCODE -ne 0) { throw 'Installer compilation failed' }
