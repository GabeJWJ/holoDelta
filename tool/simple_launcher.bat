@echo off
chcp 65001 >nul 2>&1
title holoDelta 簡易啟動器
echo ========================================
echo        holoDelta 簡易啟動器
echo ========================================
echo.

:: 檢查Python是否安裝
echo [檢查] 正在檢查Python環境...
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [錯誤] 未找到Python，請先安裝Python 3.7或更高版本
    echo 下載地址: https://www.python.org/downloads/
    echo.
    pause
    exit /b 1
)
echo [完成] Python環境檢查通過

:: 檢查專案檔案
echo [檢查] 正在檢查專案檔案...
if not exist "..\project.godot" (
    echo [錯誤] 未找到project.godot文件
    echo 請確保在正確的目錄中運行此腳本
    echo.
    pause
    exit /b 1
)
echo [完成] 專案檔案檢查通過

:: 獲取本機IP地址
echo [資訊] 正在獲取本機IP地址...
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /i "IPv4"') do (
    for /f "tokens=1" %%b in ("%%a") do (
        set LOCAL_IP=%%b
        goto :ip_found
    )
)
:ip_found
echo [完成] 本機IP地址: %LOCAL_IP%

:: 配置客戶端連接
echo [配置] 正在配置客戶端連接...
if exist "..\Scripts\server.gd" (
    copy "..\Scripts\server.gd" "..\Scripts\server.gd.backup" >nul 2>&1
    echo extends Node > "..\Scripts\server.gd"
    echo. >> "..\Scripts\server.gd"
    echo const websocketURL = "%LOCAL_IP%:8000" >> "..\Scripts\server.gd"
    echo. >> "..\Scripts\server.gd"
    echo # Called when the node enters the scene tree for the first time. >> "..\Scripts\server.gd"
    echo func _ready() -^> void: >> "..\Scripts\server.gd"
    echo ^tpass # Replace with function body. >> "..\Scripts\server.gd"
    echo. >> "..\Scripts\server.gd"
    echo. >> "..\Scripts\server.gd"
    echo # Called every frame. 'delta' is the elapsed time since the previous frame. >> "..\Scripts\server.gd"
    echo func _process(_delta: float) -^> void: >> "..\Scripts\server.gd"
    echo ^tpass >> "..\Scripts\server.gd"
    echo [完成] 客戶端配置完成
) else (
    echo [警告] 未找到Scripts\server.gd文件
)

:: 安裝Python依賴
echo [安裝] 正在安裝Python依賴...
cd "..\ServerStuff"
if exist "requirements.txt" (
    echo [資訊] 正在安裝Python依賴包...
    pip install -r requirements.txt --quiet
    if %errorlevel% equ 0 (
        echo [完成] Python依賴安裝成功
    ) else (
        echo [警告] Python依賴安裝失敗，但將繼續嘗試啟動
    )
) else (
    echo [警告] 未找到requirements.txt文件
)
cd "..\tool"

:: 啟動伺服器
echo [啟動] 正在啟動伺服器...
echo [資訊] 伺服器地址: http://%LOCAL_IP%:8000
echo [資訊] WebSocket地址: ws://%LOCAL_IP%:8000/ws
echo.

:: 在新視窗中啟動伺服器
start "holoDelta Server" cmd /k "cd /d %~dp0..\ServerStuff && python -m uvicorn server:app --host 0.0.0.0 --port 8000 --reload"

:: 等待伺服器啟動
echo [等待] 等待伺服器啟動...
timeout /t 5 /nobreak >nul

:: 啟動Godot客戶端
echo [啟動] 正在啟動holoDelta客戶端...
cd ".."

:: 嘗試不同的Godot路徑
set GODOT_FOUND=0

if exist "C:\Godot\Godot_v4.5-stable_win64.exe" (
    echo [找到] Godot at C:\Godot\Godot_v4.5-stable_win64.exe
    start "" "C:\Godot\Godot_v4.5-stable_win64.exe" --path "%CD%" --headless=false
    set GODOT_FOUND=1
) else if exist "C:\Godot\Godot.exe" (
    echo [找到] Godot at C:\Godot\Godot.exe
    start "" "C:\Godot\Godot.exe" --path "%CD%" --headless=false
    set GODOT_FOUND=1
) else (
    :: 嘗試使用系統PATH中的godot
    where godot >nul 2>&1
    if %errorlevel% equ 0 (
        echo [找到] Godot in system PATH
        start "" godot --path "%CD%" --headless=false
        set GODOT_FOUND=1
    )
)

if %GODOT_FOUND% equ 0 (
    echo [錯誤] 未找到Godot安裝
    echo 請安裝Godot 4.5或更高版本
    echo 下載地址: https://godotengine.org/download/
    echo.
    echo 或者將Godot安裝到以下位置之一：
    echo - C:\Godot\Godot_v4.5-stable_win64.exe
    echo - C:\Godot\Godot.exe
    echo - 或將godot.exe加入系統PATH
    echo.
    pause
    exit /b 1
)

echo.
echo ========================================
echo           啟動完成！
echo ========================================
echo.
echo 伺服器資訊:
echo - 本機IP: %LOCAL_IP%
echo - 伺服器地址: http://%LOCAL_IP%:8000
echo - WebSocket: ws://%LOCAL_IP%:8000/ws
echo.
echo 其他玩家連接資訊:
echo - 請將此IP地址分享給其他玩家: %LOCAL_IP%
echo - 其他玩家需要在RadminVPN中連接到你的網路
echo.
echo 按任意鍵關閉此視窗...
pause >nul
