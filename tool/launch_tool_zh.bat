@echo off
chcp 65001 >nul
title HoloDelta Enhanced Launcher

echo ========================================
echo       HoloDelta - Enhanced Launcher
echo ========================================
echo.
echo [INFO] Starting enhanced visual launcher...
echo.

cd /d "%~dp0"
python holoDelta_launcher_enhanced.py

if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Launcher execution failed, please check Python environment
    echo.
    pause
)
