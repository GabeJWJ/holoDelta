@echo off
chcp 65001 >nul 2>&1
title holoDelta 自動啟動器

echo ========================================
echo        holoDelta 自動啟動器
echo ========================================
echo.

:: 檢查Python是否安裝
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [錯誤] 未找到Python，請先安裝Python 3.8或更高版本
    echo 下載地址: https://www.python.org/downloads/
    echo.
    echo 按任意鍵退出...
    pause >nul
    exit /b 1
)

:: 檢查Godot是否安裝
where godot >nul 2>&1
if %errorlevel% neq 0 (
    echo [警告] 未找到Godot命令，將嘗試使用專案內的Godot
    set GODOT_PATH=godot
) else (
    set GODOT_PATH=godot
)

:: 獲取本機IP地址
echo [資訊] 正在獲取本機IP地址...
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /i "IPv4"') do (
    for /f "tokens=1" %%b in ("%%a") do (
        set LOCAL_IP=%%b
        goto :ip_found
    )
)
:ip_found

echo [資訊] 本機IP地址: %LOCAL_IP%
echo.

:: 創建本地伺服器配置
echo [步驟 1/4] 配置本地伺服器...
if not exist "ServerStuff\config_local.py" (
    echo # 本地伺服器配置 > ServerStuff\config_local.py
    echo HOST = "0.0.0.0" >> ServerStuff\config_local.py
    echo PORT = 8000 >> ServerStuff\config_local.py
    echo DEBUG = True >> ServerStuff\config_local.py
    echo LOCAL_IP = "%LOCAL_IP%" >> ServerStuff\config_local.py
    echo [完成] 已創建本地伺服器配置文件
) else (
    echo [完成] 本地伺服器配置文件已存在
)

:: 修改server.gd以使用本地伺服器
echo [步驟 2/4] 配置客戶端連接本地伺服器...
if exist "Scripts\server.gd" (
    copy "Scripts\server.gd" "Scripts\server.gd.backup" >nul 2>&1
    echo extends Node > "Scripts\server.gd"
    echo. >> "Scripts\server.gd"
    echo const websocketURL = "%LOCAL_IP%:8000" >> "Scripts\server.gd"
    echo. >> "Scripts\server.gd"
    echo # Called when the node enters the scene tree for the first time. >> "Scripts\server.gd"
    echo func _ready() -^> void: >> "Scripts\server.gd"
    echo ^tpass # Replace with function body. >> "Scripts\server.gd"
    echo. >> "Scripts\server.gd"
    echo. >> "Scripts\server.gd"
    echo # Called every frame. 'delta' is the elapsed time since the previous frame. >> "Scripts\server.gd"
    echo func _process(_delta: float) -^> void: >> "Scripts\server.gd"
    echo ^tpass >> "Scripts\server.gd"
    echo [完成] 已配置客戶端連接本地伺服器
) else (
    echo [警告] 未找到Scripts\server.gd文件
)

:: 安裝Python依賴
echo [步驟 3/4] 安裝Python依賴...
cd ServerStuff
if exist "requirements.txt" (
    echo [資訊] 正在安裝Python依賴包...
    pip install -r requirements.txt --quiet
    if %errorlevel% equ 0 (
        echo [完成] Python依賴安裝成功
    ) else (
        echo [錯誤] Python依賴安裝失敗
        pause
        exit /b 1
    )
) else (
    echo [警告] 未找到requirements.txt文件
)
cd ..

:: 啟動伺服器
echo [步驟 4/4] 啟動本地伺服器...
echo [資訊] 正在啟動FastAPI伺服器...
echo [資訊] 伺服器地址: http://%LOCAL_IP%:8000
echo [資訊] WebSocket地址: ws://%LOCAL_IP%:8000/ws
echo.
echo ========================================
echo 伺服器啟動中，請稍候...
echo ========================================
echo.

:: 在新視窗中啟動伺服器
start "holoDelta Server" cmd /k "cd /d %~dp0ServerStuff && python -m uvicorn server:app --host 0.0.0.0 --port 8000 --reload"

:: 等待伺服器啟動
timeout /t 3 /nobreak >nul

:: 啟動Godot客戶端
echo [資訊] 正在啟動holoDelta客戶端...
if exist "project.godot" (
    start "" "%GODOT_PATH%" --path "%~dp0" --headless=false
    echo [完成] 已啟動holoDelta客戶端
) else (
    echo [錯誤] 未找到project.godot文件
    echo 請確保在正確的目錄中運行此腳本
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
