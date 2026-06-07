; Inno Setup script for Scrcpy GUI (Windows).
; Builds a single setup.exe from the Flutter release folder.
; No code signing required. Installs per-user (no admin prompt).
;
; Compile from the ScrcpyGui/ directory after `flutter build windows --release`:
;   iscc /DMyAppVersion=1.7.4 installer.iss
; Output: artifacts/windows_installer/scrcpy-gui-setup.exe

#ifndef MyAppVersion
  #define MyAppVersion "0.0.0"
#endif

#define MyAppName "Scrcpy GUI"
#define MyAppExeName "scrcpy_gui_prod.exe"
#define MyAppPublisher "George Englezos"
#define MyAppURL "https://github.com/GeorgeEnglezos/Scrcpy-GUI"
#define BuildDir "build\windows\x64\runner\Release"

[Setup]
AppId={{C2D0F513-6FFD-4E36-8E9B-EFE26AE51864}}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
DefaultDirName={autopf}\ScrcpyGUI
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
; Per-user install -> no admin elevation, no UAC prompt.
PrivilegesRequired=lowest
OutputDir=artifacts\windows_installer
OutputBaseFilename=scrcpy-gui-setup
SetupIconFile=windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#BuildDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#MyAppName}}"; Flags: nowait postinstall skipifsilent
