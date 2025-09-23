@echo off
title Godot Environment Check
echo ========================================
echo        Godot Environment Check
echo ========================================
echo.

echo [CHECK] Checking PATH environment variable...
echo %PATH% | findstr /i godot
if %errorlevel% equ 0 (
    echo [OK] Godot found in PATH
) else (
    echo [WARNING] Godot not found in PATH
)
echo.

echo [CHECK] Checking common Godot locations...
if exist "C:\Godot\Godot_v4.5-stable_win64.exe" (
    echo [OK] Found: C:\Godot\Godot_v4.5-stable_win64.exe
) else (
    echo [NOT FOUND] C:\Godot\Godot_v4.5-stable_win64.exe
)

if exist "C:\Users\TASI\Desktop\Godot_v4.5-stable_win64.exe\Godot_v4.5-stable_win64.exe" (
    echo [OK] Found: C:\Users\TASI\Desktop\Godot_v4.5-stable_win64.exe\Godot_v4.5-stable_win64.exe
) else (
    echo [NOT FOUND] C:\Users\TASI\Desktop\Godot_v4.5-stable_win64.exe\Godot_v4.5-stable_win64.exe
)
echo.

echo [CHECK] Testing godot command...
godot --version
if %errorlevel% equ 0 (
    echo [OK] godot command works
) else (
    echo [ERROR] godot command not working
)
echo.

echo [INFO] Current PATH entries containing 'Godot':
echo %PATH% | findstr /i godot
echo.

echo Press any key to exit...
pause >nul


