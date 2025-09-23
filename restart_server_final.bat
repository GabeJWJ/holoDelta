@echo off
chcp 65001 >nul
title 最終伺服器重啟 - 修復牌組驗證問題
echo ========================================
echo       最終伺服器重啟 - 修復牌組驗證問題
echo ========================================
echo.

echo [INFO] 已修復的關鍵問題：
echo 1. ServerStuff/globals/data.py - 路徑問題修復
echo 2. ServerStuff/utils/card_utils.py - 空值處理修復
echo 3. ServerStuff/utils/deck_validator.py - 類型檢查修復
echo 4. Scripts/deck_creation.gd - 類型轉換修復
echo 5. Scenes/deck_info.gd - artNum 類型轉換
echo 6. Scripts/card.gd - artNum 類型轉換
echo.

echo [INFO] 停止現有伺服器進程...
taskkill /f /im python.exe 2>nul
timeout /t 3 /nobreak >nul

echo [INFO] 清理 Python 緩存...
cd /d "%~dp0ServerStuff"
if exist __pycache__ rmdir /s /q __pycache__ 2>nul
if exist globals\__pycache__ rmdir /s /q globals\__pycache__ 2>nul
if exist utils\__pycache__ rmdir /s /q utils\__pycache__ 2>nul
if exist classes\__pycache__ rmdir /s /q classes\__pycache__ 2>nul

echo [INFO] 測試修復...
cd ..
python test_card_info_fresh.py
if %errorlevel% neq 0 (
    echo [ERROR] 測試失敗，請檢查修復
    pause
    exit /b 1
)

echo [INFO] 重新啟動伺服器...
cd ServerStuff
echo 伺服器將在 http://26.46.176.133:8000 運行
echo WebSocket 將在 ws://26.46.176.133:8000/ws 運行
echo.

python -m uvicorn server:app --host 0.0.0.0 --port 8000 --reload

pause

