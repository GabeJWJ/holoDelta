@echo off
chcp 65001 >nul
title holoDelta Debug Launcher

echo ========================================
echo        holoDelta Debug Launcher
echo ========================================
echo.

echo [DEBUG] Current directory: %CD%
echo [DEBUG] Script location: %~dp0
echo.

echo [DEBUG] Checking Python...
python --version
if %errorlevel% neq 0 (
    echo [ERROR] Python not found or not in PATH
    echo Please install Python 3.8 or higher
    echo Download: https://www.python.org/downloads/
    echo.
    echo Press any key to exit...
    pause >nul
    exit /b 1
)
echo [OK] Python check passed
echo.

echo [DEBUG] Checking project files...
if exist "project.godot" (
    echo [OK] Found project.godot
) else (
    echo [ERROR] project.godot not found
    echo Current directory contents:
    dir /b
    echo.
    echo Press any key to exit...
    pause >nul
    exit /b 1
)

if exist "ServerStuff\server.py" (
    echo [OK] Found ServerStuff\server.py
) else (
    echo [ERROR] ServerStuff\server.py not found
    echo ServerStuff directory contents:
    dir ServerStuff /b
    echo.
    echo Press any key to exit...
    pause >nul
    exit /b 1
)

if exist "Scripts\server.gd" (
    echo [OK] Found Scripts\server.gd
) else (
    echo [ERROR] Scripts\server.gd not found
    echo Scripts directory contents:
    dir Scripts /b
    echo.
    echo Press any key to exit...
    pause >nul
    exit /b 1
)

echo.
echo [DEBUG] Getting IP address...
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /i "IPv4"') do (
    for /f "tokens=1" %%b in ("%%a") do (
        set LOCAL_IP=%%b
        goto :ip_found
    )
)
:ip_found

echo [OK] Local IP: %LOCAL_IP%
echo.

echo [DEBUG] Checking Godot...
where godot >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] Found Godot command
    godot --version
) else (
    echo [WARNING] Godot command not found
    echo Please ensure Godot is installed and added to PATH
)

echo.
echo [DEBUG] Checking Python dependencies...
cd ServerStuff
if exist "requirements.txt" (
    echo [OK] Found requirements.txt
    echo Contents:
    type requirements.txt
    echo.
    echo [DEBUG] Attempting to install dependencies...
    pip install -r requirements.txt
) else (
    echo [ERROR] requirements.txt not found
)
cd ..

echo.
echo [DEBUG] All checks completed!
echo.
echo Press any key to exit...
pause >nul
