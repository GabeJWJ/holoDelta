@echo off
title HoloDelta Launcher

echo ========================================
echo       HoloDelta - Enhanced Launcher
echo ========================================
echo.
echo [INFO] Starting launcher...
echo.

cd /d "%~dp0"

REM Check Python
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Python not found
    echo Please install Python 3.7+ and add to PATH
    pause
    exit /b 1
)

REM Check launcher file
if not exist "holoDelta_launcher_enhanced.py" (
    echo [ERROR] Launcher file not found
    pause
    exit /b 1
)

REM Launch
python holoDelta_launcher_enhanced.py

if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Launch failed
    pause
)
