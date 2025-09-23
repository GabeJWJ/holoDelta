@echo off
chcp 65001 >nul 2>&1
title HoloDelta Launcher

echo ========================================
echo       HoloDelta - Enhanced Launcher
echo ========================================
echo.
echo [INFO] Starting enhanced visual launcher...
echo.

cd /d "%~dp0"

REM Check if Python is available
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Python is not installed or not in PATH
    echo Please install Python 3.7+ and add it to PATH
    echo.
    pause
    exit /b 1
)

REM Check if the launcher file exists
if not exist "holoDelta_launcher_enhanced.py" (
    echo [ERROR] holoDelta_launcher_enhanced.py not found
    echo.
    pause
    exit /b 1
)

REM Launch the enhanced launcher
python holoDelta_launcher_enhanced.py

if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Launcher execution failed
    echo Please check Python environment and dependencies
    echo.
    pause
)
