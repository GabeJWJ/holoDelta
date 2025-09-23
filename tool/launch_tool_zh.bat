@echo off
chcp 65001 >nul
title HoloDelta Enhanced Launcher

echo ========================================
echo       ホロデルタ - Enhanced Launcher
echo ========================================
echo.
echo [資訊] 啟動增強版視覺化啟動器...
echo.

cd /d "%~dp0"
python holoDelta_launcher_enhanced.py

if %errorlevel% neq 0 (
    echo.
    echo [錯誤] 啟動器執行失敗，請檢查Python環境
    echo.
    pause
)
