@echo off
:: ============================================================
:: build_installer.bat
:: Script untuk build PDF Converter installer Windows
:: Jalankan file ini di Windows (bukan Linux)
:: ============================================================
setlocal enabledelayedexpansion

echo ============================================
echo  PDF Converter - Windows Installer Builder
echo ============================================
echo.

:: ── 1. Build Flutter Windows Release ─────────────────────
echo [1/4] Building Flutter Windows release...
call flutter build windows --release
if errorlevel 1 (
    echo ERROR: Flutter build failed!
    pause
    exit /b 1
)
echo Flutter build OK!
echo.

:: ── 2. Build Rust Engine for Windows ─────────────────────
echo [2/4] Building Rust engine for Windows...
cd rust
cargo build --release
if errorlevel 1 (
    echo ERROR: Rust build failed!
    cd ..
    pause
    exit /b 1
)
cd ..

:: Copy engine to engine_bin\windows
mkdir engine_bin\windows 2>nul
copy /Y rust\target\release\pdf_converter_engine.exe engine_bin\windows\
echo Rust engine built and copied!
echo.

:: ── 3. Convert icon PNG to ICO (if not already done) ─────
echo [3/4] Checking icon...
if not exist "windows\runner\resources\app_icon.ico" (
    echo WARNING: app_icon.ico not found in windows\runner\resources\
    echo Please make sure the icon file is present.
) else (
    echo Icon OK!
)
echo.

:: ── 4. Build Installer with Inno Setup ────────────────────
echo [4/4] Building installer with Inno Setup...

:: Check Inno Setup locations
set ISCC=""
if exist "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" (
    set ISCC="C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
)
if exist "C:\Program Files\Inno Setup 6\ISCC.exe" (
    set ISCC="C:\Program Files\Inno Setup 6\ISCC.exe"
)

if !ISCC! == "" (
    echo ERROR: Inno Setup 6 not found!
    echo Please install from: https://jrsoftware.org/isinfo.php
    pause
    exit /b 1
)

%ISCC% installer\setup.iss
if errorlevel 1 (
    echo ERROR: Installer build failed!
    pause
    exit /b 1
)

echo.
echo ============================================
echo  BUILD SUCCESSFUL!
echo  Installer: installer\Output\PDFConverter_Setup_v1.0.0.exe
echo ============================================
pause
