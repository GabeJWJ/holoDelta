# holoDelta 手動啟動指南

如果自動啟動腳本無法正常工作，請按照以下步驟手動啟動：

## 步驟 1: 檢查環境

### 檢查 Python
在命令提示字元中運行：
```cmd
python --version
```
應該顯示 Python 3.8 或更高版本。

### 檢查專案檔案
確保以下檔案存在：
- `project.godot`
- `ServerStuff\server.py`
- `Scripts\server.gd`

## 步驟 2: 獲取本機 IP 地址

在命令提示字元中運行：
```cmd
ipconfig
```
找到 "IPv4 位址" 或 "IPv4 Address"，記錄這個 IP 地址。

## 步驟 3: 配置客戶端

編輯 `Scripts\server.gd` 檔案，將內容改為：
```gdscript
extends Node

const websocketURL = "你的IP地址:8000"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
```
將 "你的IP地址" 替換為步驟 2 中獲得的 IP 地址。

## 步驟 4: 安裝 Python 依賴

在命令提示字元中運行：
```cmd
cd ServerStuff
pip install -r requirements.txt
```

## 步驟 5: 啟動伺服器

在命令提示字元中運行：
```cmd
cd ServerStuff
python -m uvicorn server:app --host 0.0.0.0 --port 8000 --reload
```

伺服器啟動後，你應該會看到類似以下的訊息：
```
INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
INFO:     Started reloader process
INFO:     Started server process
INFO:     Waiting for application startup.
INFO:     Application startup complete.
```

## 步驟 6: 啟動客戶端

開啟新的命令提示字元視窗，運行：
```cmd
godot --path "專案目錄路徑" --headless=false
```
將 "專案目錄路徑" 替換為你的 holoDelta 專案目錄的完整路徑。

## 步驟 7: 測試連接

1. 客戶端啟動後，應該會自動連接到本地伺服器
2. 檢查客戶端是否顯示連接成功
3. 記錄你的 IP 地址，分享給其他玩家

## 網路設定

### 使用 RadminVPN

1. **主機（你）**：
   - 安裝 RadminVPN
   - 創建新網路並設定密碼
   - 將網路名稱、密碼和你的 IP 地址分享給朋友

2. **朋友**：
   - 安裝 RadminVPN
   - 加入你創建的網路
   - 在遊戲中輸入你的 IP 地址

### 防火牆設定

確保以下程式可以通過防火牆：
- `python.exe`
- `godot.exe`
- 端口 `8000`

## 故障排除

### 常見問題

1. **Python 未找到**
   - 重新安裝 Python 並確保勾選 "Add Python to PATH"

2. **Godot 未找到**
   - 安裝 Godot 並添加到系統 PATH
   - 或使用 Godot 的完整路徑

3. **無法連接到伺服器**
   - 檢查防火牆設定
   - 確認 IP 地址正確
   - 檢查伺服器是否正常運行

4. **朋友無法連接**
   - 確認朋友已加入 RadminVPN 網路
   - 檢查 IP 地址是否正確
   - 確認防火牆設定

## 完整命令範例

假設你的 IP 地址是 `192.168.1.100`，專案目錄是 `C:\Users\TASI\Desktop\holocard\holoDelta`：

### 終端 1 (伺服器)：
```cmd
cd C:\Users\TASI\Desktop\holocard\holoDelta\ServerStuff
python -m uvicorn server:app --host 0.0.0.0 --port 8000 --reload
```

### 終端 2 (客戶端)：
```cmd
godot --path "C:\Users\TASI\Desktop\holocard\holoDelta" --headless=false
```

### 修改 Scripts\server.gd：
```gdscript
extends Node

const websocketURL = "192.168.1.100:8000"

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	pass
```

這樣就可以手動啟動 holoDelta 了！


