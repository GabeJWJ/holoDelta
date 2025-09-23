# holoDelta PowerShell 啟動器
# 設定編碼為UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "        holoDelta 自動啟動器" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 檢查Python是否安裝
Write-Host "[檢查] 正在檢查Python..." -ForegroundColor Yellow
try {
    $pythonVersion = python --version 2>&1
    Write-Host "[完成] $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "[錯誤] 未找到Python，請先安裝Python 3.8或更高版本" -ForegroundColor Red
    Write-Host "下載地址: https://www.python.org/downloads/" -ForegroundColor Yellow
    Read-Host "按Enter鍵退出"
    exit 1
}

# 檢查專案檔案
Write-Host "[檢查] 正在檢查專案檔案..." -ForegroundColor Yellow
if (-not (Test-Path "project.godot")) {
    Write-Host "[錯誤] 未找到project.godot文件" -ForegroundColor Red
    Write-Host "請確保在正確的目錄中運行此腳本" -ForegroundColor Yellow
    Read-Host "按Enter鍵退出"
    exit 1
}

if (-not (Test-Path "ServerStuff\server.py")) {
    Write-Host "[錯誤] 未找到ServerStuff\server.py文件" -ForegroundColor Red
    Write-Host "請確保在正確的目錄中運行此腳本" -ForegroundColor Yellow
    Read-Host "按Enter鍵退出"
    exit 1
}

Write-Host "[完成] 專案檔案檢查完成" -ForegroundColor Green

# 獲取本機IP地址
Write-Host "[資訊] 正在獲取本機IP地址..." -ForegroundColor Yellow
$localIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -ne "127.0.0.1"} | Select-Object -First 1).IPAddress
Write-Host "[完成] 本機IP地址: $localIP" -ForegroundColor Green
Write-Host ""

# 修改server.gd以使用本地伺服器
Write-Host "[配置] 正在配置客戶端連接本地伺服器..." -ForegroundColor Yellow
if (Test-Path "Scripts\server.gd") {
    Copy-Item "Scripts\server.gd" "Scripts\server.gd.backup" -Force
    $serverGdContent = @"
extends Node

const websocketURL = "$localIP:8000"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
"@
    Set-Content -Path "Scripts\server.gd" -Value $serverGdContent -Encoding UTF8
    Write-Host "[完成] 已配置客戶端連接本地伺服器" -ForegroundColor Green
} else {
    Write-Host "[警告] 未找到Scripts\server.gd文件" -ForegroundColor Yellow
}

# 安裝Python依賴
Write-Host "[安裝] 正在安裝Python依賴..." -ForegroundColor Yellow
Set-Location "ServerStuff"
if (Test-Path "requirements.txt") {
    Write-Host "[資訊] 正在安裝Python依賴包..." -ForegroundColor Yellow
    pip install -r requirements.txt
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[完成] Python依賴安裝成功" -ForegroundColor Green
    } else {
        Write-Host "[錯誤] Python依賴安裝失敗" -ForegroundColor Red
        Read-Host "按Enter鍵退出"
        exit 1
    }
} else {
    Write-Host "[警告] 未找到requirements.txt文件" -ForegroundColor Yellow
}
Set-Location ".."

# 啟動伺服器
Write-Host "[啟動] 正在啟動本地伺服器..." -ForegroundColor Yellow
Write-Host "[資訊] 伺服器地址: http://$localIP:8000" -ForegroundColor Cyan
Write-Host "[資訊] WebSocket地址: ws://$localIP:8000/ws" -ForegroundColor Cyan
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "伺服器啟動中，請稍候..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 在新視窗中啟動伺服器
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$PWD\ServerStuff'; python -m uvicorn server:app --host 0.0.0.0 --port 8000 --reload"

# 等待伺服器啟動
Write-Host "[等待] 等待伺服器啟動..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# 啟動Godot客戶端
Write-Host "[啟動] 正在啟動holoDelta客戶端..." -ForegroundColor Yellow
if (Test-Path "project.godot") {
    Start-Process "godot" -ArgumentList "--path", "$PWD", "--headless=false"
    Write-Host "[完成] 已啟動holoDelta客戶端" -ForegroundColor Green
} else {
    Write-Host "[錯誤] 未找到project.godot文件" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "           啟動完成！" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "伺服器資訊:" -ForegroundColor Yellow
Write-Host "- 本機IP: $localIP" -ForegroundColor White
Write-Host "- 伺服器地址: http://$localIP:8000" -ForegroundColor White
Write-Host "- WebSocket: ws://$localIP:8000/ws" -ForegroundColor White
Write-Host ""
Write-Host "其他玩家連接資訊:" -ForegroundColor Yellow
Write-Host "- 請將此IP地址分享給其他玩家: $localIP" -ForegroundColor White
Write-Host "- 其他玩家需要在RadminVPN中連接到你的網路" -ForegroundColor White
Write-Host ""
Read-Host "按Enter鍵關閉此視窗"


