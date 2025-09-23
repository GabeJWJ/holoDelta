@echo off
chcp 65001 >nul
echo ========================================
echo       修復藝術名稱和效果顯示
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
echo   - 修復客戶端藝術名稱顯示問題
echo   - 將 float 類型的 art[0] 轉換為字符串
echo   - 使用 str(int(art[0])) 確保正確的翻譯鍵
echo   - 修復藝術效果文字顯示
echo.
echo 現在你可以：
echo   1. 重新啟動客戶端
echo   2. 查看卡片詳細信息
echo   3. 藝術名稱和效果應該正常顯示
echo   4. 不再顯示 "hSD05-004_ART_0.0_NAME 40.0" 這樣的錯誤
echo.
echo 按任意鍵退出...
pause >nul
