@echo off
chcp 65001 >nul
echo ========================================
echo       修復 float 到 int 轉換錯誤
echo ========================================
echo.

echo [INFO] 停止伺服器...
taskkill /f /im python.exe >nul 2>&1
timeout /t 2 >nul

echo [INFO] 清理 Python 緩存...
cd ServerStuff
for /d /r . %%d in (__pycache__) do @if exist "%%d" rd /s /q "%%d" 2>nul
cd ..

echo [INFO] 重新啟動伺服器...
cd ServerStuff
start "holoDelta Server" cmd /k "python server.py"
timeout /t 3 >nul

echo [INFO] 修復完成！
echo.
echo 修復內容：
echo   - 修復 side.py 中的 float 到 int 轉換問題
echo   - 在 range() 函數中使用 int() 轉換
echo   - 在 Card 構造函數中使用 int() 轉換
echo   - 確保所有數值參數都是整數類型
echo.
echo 現在你可以：
echo   1. 重新啟動客戶端
echo   2. 選擇任何牌組
echo   3. 點擊 Ready
echo   4. 開始遊戲 - 不會再出現 TypeError
echo.
echo 按任意鍵退出...
pause >nul
