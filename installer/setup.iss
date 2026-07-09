; ============================================================
; PDF Converter - Inno Setup Installer Script
; ============================================================
; Requirements:
;   1. Inno Setup 6+ (https://jrsoftware.org/isinfo.php)
;   2. Flutter Windows release build:
;        flutter build windows --release
;   3. Rust engine built for Windows (in engine_bin/windows/)
;
; Run: Right-click this file → Compile in Inno Setup Compiler
; Output: installer/Output/PDFConverter_Setup_v1.0.0.exe
; ============================================================

#define AppName      "PDF Converter"
#define AppVersion   "1.0.0"
#define AppPublisher "Mustofa"
#define AppURL       "https://github.com/Mustofa12312/image-pdf"
#define AppExeName   "pdf_converter.exe"
#define AppId        "{{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}"

; Path to Flutter Windows release build output
#define BuildDir     "..\build\windows\x64\runner\Release"

[Setup]
AppId={#AppId}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppURL}
AppSupportURL={#AppURL}
AppUpdatesURL={#AppURL}

; Default install dir: C:\Program Files\PDF Converter
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes

; Output installer file
OutputDir=Output
OutputBaseFilename=PDFConverter_Setup_v{#AppVersion}

; Icon for the installer itself
SetupIconFile=..\assets\image\file.ico

; Compression
Compression=lzma2/ultra64
SolidCompression=yes
LZMAUseSeparateProcess=yes

; Require admin for Program Files install
PrivilegesRequired=admin
PrivilegesRequiredOverridesAllowed=dialog

; Wizard appearance
WizardStyle=modern
WizardResizable=yes

; Windows 10/11 minimum
MinVersion=10.0.17763

; Uninstall info
UninstallDisplayName={#AppName}
UninstallDisplayIcon={app}\{#AppExeName}

; Restart not needed
RestartIfNeededByRun=no
DisableReadyPage=no

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon";    Description: "Create a &desktop shortcut";         GroupDescription: "Additional shortcuts:"; Flags: checked
Name: "startmenuicon";  Description: "Create a &Start Menu shortcut";      GroupDescription: "Additional shortcuts:"; Flags: checked

[Files]
; ── Main Flutter app ──────────────────────────────────────────────────────────
Source: "{#BuildDir}\{#AppExeName}";           DestDir: "{app}";              Flags: ignoreversion
Source: "{#BuildDir}\*.dll";                   DestDir: "{app}";              Flags: ignoreversion recursesubdirs
Source: "{#BuildDir}\data\*";                  DestDir: "{app}\data";         Flags: ignoreversion recursesubdirs createallsubdirs

; ── Rust PDF engine ───────────────────────────────────────────────────────────
Source: "..\engine_bin\windows\pdf_converter_engine.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\engine_bin\windows\pdfium.dll"; DestDir: "{app}"; Flags: ignoreversion skipifsourcedoesntexist

; ── Poppler tools (pdftoppm.exe) for PDF→Image conversion ────────────────────
; Download from: https://github.com/oschwartz10612/poppler-windows/releases
; Extract and place the "bin" and "Library" folders into: installer\poppler\
Source: "poppler\*";  DestDir: "{app}\poppler"; Flags: ignoreversion recursesubdirs createallsubdirs skipifsourcedoesntexist

; ── App icon ──────────────────────────────────────────────────────────────────
Source: "..\assets\image\file.ico";  DestDir: "{app}"; DestName: "app.ico"; Flags: ignoreversion skipifsourcedoesntexist

[Icons]
; Start Menu shortcut
Name: "{group}\{#AppName}";       Filename: "{app}\{#AppExeName}"; IconFilename: "{app}\app.ico"; Tasks: startmenuicon
Name: "{group}\Uninstall {#AppName}"; Filename: "{uninstallexe}";

; Desktop shortcut
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; IconFilename: "{app}\app.ico"; Tasks: desktopicon

[Registry]
; Register the app so it appears in "Apps & features" (Settings)
Root: HKLM; Subkey: "Software\{#AppPublisher}\{#AppName}"; ValueType: string; ValueName: "InstallPath"; ValueData: "{app}"; Flags: uninsdeletekey
Root: HKLM; Subkey: "Software\{#AppPublisher}\{#AppName}"; ValueType: string; ValueName: "Version";     ValueData: "{#AppVersion}"

; Add poppler to PATH so pdftoppm is accessible from the app
Root: HKLM; Subkey: "SYSTEM\CurrentControlSet\Control\Session Manager\Environment"; ValueType: expandsz; ValueName: "Path"; ValueData: "{olddata};{app}\poppler\bin"; Flags: preservestringtype uninsdeletekeyifempty

[Run]
; Launch app after install (optional)
Filename: "{app}\{#AppExeName}"; Description: "Launch {#AppName}"; Flags: nowait postinstall skipifsilent

[UninstallRun]
; Clean up on uninstall

[Code]
// Check if Visual C++ Redistributable is installed
function VCRedistInstalled: Boolean;
var
  SubKey: string;
begin
  SubKey := 'SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\X64';
  Result := RegKeyExists(HKLM, SubKey);
end;

procedure InitializeWizard;
begin
  // Custom welcome message
  WizardForm.WelcomeLabel2.Caption :=
    'This will install ' + '{#AppName}' + ' ' + '{#AppVersion}' + ' on your computer.' + #13#10 + #13#10 +
    'PDF Converter is a fast, offline PDF ↔ Image conversion tool.' + #13#10 +
    'Supports PDF to PNG/JPG, Image to PDF, Word to Image, and more.' + #13#10 + #13#10 +
    'Click Next to continue.';
end;
