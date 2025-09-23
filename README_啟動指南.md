# holoDelta 本地伺服器啟動指南

## 概述
這個指南將幫助你快速啟動 holoDelta 桌面端應用並架設本地局域網伺服器，讓你和朋友們可以一起遊玩。

## 系統需求

### 必要軟體
- **Python 3.8+**：用於運行伺服器
- **Godot 4.3**：用於運行遊戲客戶端
- **RadminVPN**：用於建立虛擬局域網（可選，但推薦）

### 下載連結
- Python: https://www.python.org/downloads/
- Godot: https://godotengine.org/download/
- RadminVPN: https://www.radmin-vpn.com/

## 快速啟動

### 方法一：使用自動啟動腳本（推薦）

1. **確保已安裝必要軟體**
   - Python 3.8 或更高版本
   - Godot 4.3（建議安裝到系統PATH中）

2. **運行啟動腳本**
   ```
   雙擊 launch_holodelta.bat
   ```

3. **腳本會自動完成以下操作**：
   - 檢查系統環境
   - 獲取本機IP地址
   - 配置本地伺服器
   - 修改客戶端連接設定
   - 安裝Python依賴
   - 啟動伺服器和客戶端

4. **分享連接資訊**
   - 腳本會顯示你的本機IP地址
   - 將此IP地址分享給朋友們

### 方法二：手動啟動

#### 1. 安裝Python依賴
```bash
cd ServerStuff
pip install -r requirements.txt
```

#### 2. 啟動伺服器
```bash
cd ServerStuff
python -m uvicorn server:app --host 0.0.0.0 --port 8000 --reload
```

#### 3. 修改客戶端設定
編輯 `Scripts/server.gd` 文件：
```gdscript
extends Node

const websocketURL = "你的IP地址:8000"  # 例如: "192.168.1.100:8000"
```

#### 4. 啟動客戶端
```bash
godot --path . --headless=false
```

## 網路設定

### 使用 RadminVPN（推薦）

1. **主機設定**：
   - 安裝並啟動 RadminVPN
   - 創建新網路並設定密碼
   - 運行 `launch_holodelta.bat`
   - 將網路資訊和IP地址分享給朋友

2. **朋友連接**：
   - 安裝 RadminVPN
   - 加入主機創建的網路
   - 在遊戲中輸入主機IP地址

詳細設定請參考：`setup_radmin_vpn.md`

### 使用本地網路

如果你和朋友們在同一個WiFi網路中：
1. 確保所有設備連接到同一個路由器
2. 運行啟動腳本獲取IP地址
3. 朋友們在遊戲中輸入你的IP地址

## 故障排除

### 常見問題

#### 1. Python 未找到
```
[錯誤] 未找到Python，請先安裝Python 3.8或更高版本
```
**解決方案**：
- 下載並安裝 Python
- 確保安裝時勾選 "Add Python to PATH"

#### 2. Godot 未找到
```
[警告] 未找到Godot命令，將嘗試使用專案內的Godot
```
**解決方案**：
- 安裝 Godot 4.3
- 將 Godot 添加到系統 PATH
- 或確保專案目錄中有 Godot 執行檔

#### 3. 無法連接到伺服器
**檢查項目**：
- 防火牆是否阻擋了連接
- IP地址是否正確
- 伺服器是否正常運行
- RadminVPN 是否正確連接

#### 4. 朋友無法連接
**檢查項目**：
- 確認朋友已加入 RadminVPN 網路
- 檢查IP地址是否正確
- 確認防火牆設定
- 嘗試重新啟動伺服器

### 防火牆設定

#### Windows 防火牆
1. 打開 "Windows Defender 防火牆"
2. 點擊 "允許應用程式或功能通過 Windows Defender 防火牆"
3. 找到並勾選：
   - Python
   - Godot
4. 如果找不到，點擊 "變更設定" > "允許其他應用程式"

#### 第三方防火牆
確保以下程式可以通過防火牆：
- `python.exe`
- `godot.exe`
- 端口 `8000` 開放

## 進階設定

### 修改伺服器端口
如果端口 8000 被佔用，可以修改為其他端口：

1. 編輯 `ServerStuff/server.py`
2. 修改啟動命令：
   ```bash
   python -m uvicorn server:app --host 0.0.0.0 --port 8080 --reload
   ```
3. 同時修改 `Scripts/server.gd` 中的端口號

### 自定義伺服器設定
編輯 `ServerStuff/config_local.py`：
```python
HOST = "0.0.0.0"
PORT = 8000
DEBUG = True
LOCAL_IP = "你的IP地址"
```

## 安全注意事項

1. **網路安全**：
   - 只邀請信任的朋友加入網路
   - 使用強密碼保護 RadminVPN 網路
   - 定期更換網路密碼

2. **防火牆**：
   - 確保防火牆設定正確
   - 只開放必要的端口

3. **系統安全**：
   - 保持系統和軟體更新
   - 使用防毒軟體

## 技術支援

如果遇到問題：
1. 檢查本指南的故障排除部分
2. 確認所有必要軟體已正確安裝
3. 檢查網路連接和防火牆設定
4. 嘗試重新啟動所有相關程式

## 檔案說明

- `launch_holodelta.bat`：自動啟動腳本
- `setup_radmin_vpn.md`：RadminVPN 詳細設定指南
- `README_啟動指南.md`：本文件
- `ServerStuff/`：伺服器相關檔案
- `Scripts/server.gd`：客戶端伺服器連接設定

## 更新日誌

- v1.0：初始版本，支援自動啟動和 RadminVPN 設定


