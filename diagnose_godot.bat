@echo off
title Godot Diagnosis
echo ========================================
echo        Godot Diagnosis Tool
echo ========================================
echo.

echo [1] Checking PATH environment variable...
echo Current PATH:
echo %PATH%
echo.

echo [2] Looking for Godot in PATH...
echo %PATH% | findstr /i "godot"
if %errorlevel% equ 0 (
    echo [FOUND] Godot path found in PATH
) else (
    echo [NOT FOUND] Godot path not found in PATH
)
echo.

echo [3] Checking if godot command works...
where godot
if %errorlevel% equ 0 (
    echo [OK] godot command found
    godot --version
) else (
    echo [ERROR] godot command not found
)
echo.

echo [4] Checking common Godot locations...
if exist "C:\Godot\Godot_v4.5-stable_win64.exe" (
    echo [FOUND] C:\Godot\Godot_v4.5-stable_win64.exe
    "C:\Godot\Godot_v4.5-stable_win64.exe" --version
) else (
    echo [NOT FOUND] C:\Godot\Godot_v4.5-stable_win64.exe
)

if exist "C:\Godot\godot.exe" (
    echo [FOUND] C:\Godot\godot.exe
    "C:\Godot\godot.exe" --version
) else (
    echo [NOT FOUND] C:\Godot\godot.exe
)
echo.

echo [5] Checking Desktop location...
if exist "C:\Users\TASI\Desktop\Godot_v4.5-stable_win64.exe\Godot_v4.5-stable_win64.exe" (
    echo [FOUND] Desktop Godot executable
    "C:\Users\TASI\Desktop\Godot_v4.5-stable_win64.exe\Godot_v4.5-stable_win64.exe" --version
) else (
    echo [NOT FOUND] Desktop Godot executable
)
echo.

echo [6] Testing direct execution...
if exist "C:\Godot\Godot_v4.5-stable_win64.exe" (
    echo Testing: C:\Godot\Godot_v4.5-stable_win64.exe --version
    "C:\Godot\Godot_v4.5-stable_win64.exe" --version
) else (
    echo Cannot test - Godot not found in C:\Godot\
)
echo.

echo [7] System environment variables...
echo USER PATH: %USERPROFILE%
echo SYSTEM ROOT: %SYSTEMROOT%
echo.

echo ========================================
echo Diagnosis complete!
echo ========================================
echo.
echo Press any key to exit...
pause >nul


