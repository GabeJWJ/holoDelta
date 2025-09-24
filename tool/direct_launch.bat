@echo off
title holoDelta Client
cd /d "%~dp0"
echo Starting holoDelta Client...
echo.

:: 使用完整路徑啟動 Godot
if exist "C:\Godot\Godot_v4.5-stable_win64.exe" (
    echo Found Godot at C:\Godot\Godot_v4.5-stable_win64.exe
    echo Project path: %CD%
    echo.
    "C:\Godot\Godot_v4.5-stable_win64.exe" --path "%CD%" --headless=false
) else (
    echo [ERROR] Godot not found at C:\Godot\Godot_v4.5-stable_win64.exe
    echo Please make sure Godot is properly installed.
    echo.
    pause
    exit /b 1
)

pause