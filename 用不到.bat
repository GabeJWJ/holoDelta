@echo off
chcp 65001 >nul
title 重啟伺服器並修復牌組驗證問題
echo ========================================
echo       重啟伺服器並修復牌組驗證問題
echo ========================================
echo.

echo [INFO] 已修復的問題：
echo 1. ServerStuff/utils/deck_validator.py:113 - cheerDeck 類型檢查
echo 2. ServerStuff/utils/card_utils.py:24-25 - card_info 空值處理
echo 3. Scripts/deck_creation.gd - 所有類型轉換問題
echo 4. Scenes/deck_info.gd:13 - artNum 類型轉換
echo 5. Scripts/card.gd:75 - artNum 類型轉換
echo.

echo [INFO] 現在重啟伺服器以載入修復...
echo.

cd /d "%~dp0ServerStuff"

echo [INFO] 停止現有伺服器進程...
taskkill /f /im python.exe 2>nul
timeout /t 2 /nobreak >nul

echo [INFO] 重新啟動伺服器...
echo 伺服器將在 http://26.46.176.133:8000 運行
echo WebSocket 將在 ws://26.46.176.133:8000/ws 運行
echo.

python -m uvicorn server:app --host 0.0.0.0 --port 8000 --reload

pause

