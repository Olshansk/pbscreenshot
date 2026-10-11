#define AppVersion "0.1.0"
[Setup]
AppId=Olshansky.pbscreenshot
AppName=pbscreenshot
AppVersion={#AppVersion}
AppPublisher=Olshansky
DefaultDirName={localappdata}\Programs\pbscreenshot
DefaultGroupName=pbscreenshot
PrivilegesRequired=lowest
OutputDir=..\..\dist\windows
OutputBaseFilename=pbscreenshot-setup-win-x64
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
CloseApplications=yes
UninstallDisplayIcon={app}\pbscreenshot.exe

[Files]
Source: "..\..\dist\windows\app\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\pbscreenshot"; Filename: "{app}\pbscreenshot.exe"

[Registry]
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueName: "pbscreenshot"; Flags: uninsdeletevalue

[Run]
Filename: "{app}\pbscreenshot.exe"; Description: "Launch pbscreenshot"; Flags: nowait postinstall skipifsilent
