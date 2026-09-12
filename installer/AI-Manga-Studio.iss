#define MyAppName "AI Manga Studio"
#define MyAppVersion "0.1.0"
#define MyAppPublisher "AI Manga Studio"
#define MyAppExeName "AI-Manga-Studio-Launcher.cmd"

[Setup]
AppId={{A1D4F6EE-3A77-4E11-A8D0-3D2EA4A7D2C1}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\AI Manga Studio
DefaultGroupName={#MyAppName}
OutputDir=output
OutputBaseFilename=AI-Manga-Studio-Setup-{#MyAppVersion}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
Uninstallable=yes
ArchitecturesInstallIn64BitMode=x64
UninstallDisplayIcon={app}\AI-Manga-Studio-Launcher.cmd

[Tasks]
Name: "desktopicon"; Description: "바탕화면 바로가기 생성"; GroupDescription: "바로가기:"; Flags: checkedonce

[Files]
Source: "bundle\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs ignoreversion
Source: "launchers\AI-Manga-Studio-Launcher.cmd"; DestDir: "{app}"; Flags: ignoreversion
Source: "launchers\AI-Manga-Studio-ComfyUI.cmd"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\AI Manga Studio"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\AI Manga Studio"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "AI Manga Studio 실행"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{app}\app"
Type: filesandordirs; Name: "{app}\runtime"
Type: filesandordirs; Name: "{app}\comfyui"
Type: files; Name: "{app}\AI-Manga-Studio-Launcher.cmd"
Type: files; Name: "{app}\AI-Manga-Studio-ComfyUI.cmd"
; 사용자 작업물 {app}\data는 기본 보존합니다.
