@echo off
chcp 65001 >nul 2>&1
title ホロデルタ - Enhanced Launcher

echo ========================================
echo        ホロデルタ - Enhanced Launcher
echo ========================================
echo.

:: 檢查Python
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [錯誤] 需要Python 3.7或更高版本
    echo 請先安裝Python: https://www.python.org/downloads/
    pause
    exit /b 1
)

:: 檢查專案結構
if not exist "..\project.godot" (
    echo [錯誤] 未找到holoDelta專案文件
    echo 請確保此工具位於專案根目錄下的tool資料夾中
    pause
    exit /b 1
)

:: 嘗試轉換字體 (如果需要)
if exist "NotoSans-Black.woff" (
    if not exist "NotoSans-Black.ttf" (
        echo [資訊] 正在轉換字體格式...
        python font_converter.py
    )
)

echo [資訊] 啟動增強版視覺化啟動器...
echo.

:: 啟動增強版啟動器
python holoDelta_launcher_enhanced.py

if %errorlevel% neq 0 (
    echo.
    echo [錯誤] 啟動器運行失敗
    echo 請檢查Python環境和依賴
    pause
)
