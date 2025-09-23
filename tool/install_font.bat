@echo off
chcp 65001 >nul
title HoloDelta 字體安裝工具

echo ========================================
echo        HoloDelta 字體安裝工具
echo ========================================
echo.
echo [資訊] 正在安裝 NotoSansJP-Black.ttf 字體...
echo.

cd /d "%~dp0"
python install_font.py

if %errorlevel% neq 0 (
    echo.
    echo [錯誤] 字體安裝失敗，請檢查Python環境
    echo.
    pause
)
