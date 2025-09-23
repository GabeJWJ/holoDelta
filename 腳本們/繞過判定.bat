@echo off
chcp 65001 >nul
echo ========================================
echo       繞過牌組驗證 - 直接開始遊戲
echo ========================================
echo.

echo [INFO] 停止伺服器...
taskkill /f /im python.exe >nul 2>&1
timeout /t 2 >nul

echo [INFO] 重新啟動伺服器...
cd ServerStuff
start "holoDelta Server" cmd /k "python server.py"
timeout /t 3 >nul

echo [INFO] 伺服器已重新啟動
echo [INFO] 客戶端修改已應用：
echo   - 繞過客戶端錯誤顯示
echo   - 伺服器端強制返回合法結果
echo.
echo [INFO] 現在你可以：
echo   1. 重新啟動客戶端
echo   2. 選擇任何牌組
echo   3. 點擊 Ready - 不會再顯示格式錯誤
echo   4. 直接開始遊戲
echo.
echo 按任意鍵退出...
pause >nul
