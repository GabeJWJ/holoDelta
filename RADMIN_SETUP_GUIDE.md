# RadminVPN 設定指南

## 概述
這個指南將幫助你設定 RadminVPN，讓朋友們可以連接到你的 holoDelta 伺服器。

## 你的伺服器資訊
- **你的 RadminVPN IP**: `26.46.176.133`
- **伺服器地址**: `http://26.46.176.133:8000`
- **WebSocket地址**: `ws://26.46.176.133:8000/ws`

## 步驟1：啟動 RadminVPN 伺服器

### 1.1 啟動 RadminVPN
1. 打開 RadminVPN 應用程式
2. 確保你已連接到你的網路

### 1.2 啟動 holoDelta 伺服器
```
雙擊 start_server_radmin.bat
```

### 1.3 測試連線
```
雙擊 test_radmin_connection.bat
```

## 步驟2：分享網路資訊給朋友

### 2.1 創建 RadminVPN 網路（如果還沒創建）
1. 在 RadminVPN 中點擊 "Create Network"
2. 輸入網路名稱（例如：holoDelta-Game）
3. 設定密碼
4. 點擊 "Create"

### 2.2 分享資訊給朋友
將以下資訊分享給你的朋友：

**網路資訊**：
- 網路名稱：[你的網路名稱]
- 網路密碼：[你的網路密碼]

**遊戲連線資訊**：
- 伺服器IP：`26.46.176.133`
- 端口：`8000`

## 步驟3：朋友們的設定步驟

### 3.1 安裝 RadminVPN
1. 前往 https://www.radmin-vpn.com/
2. 下載並安裝 RadminVPN
3. 註冊免費帳號

### 3.2 加入網路
1. 打開 RadminVPN
2. 點擊 "Join Network"
3. 輸入你提供的網路名稱和密碼
4. 點擊 "Join"

### 3.3 連接到遊戲
1. 確保 RadminVPN 已連接
2. 在 holoDelta 中，伺服器地址應該會自動設定為 `26.46.176.133:8000`
3. 如果沒有自動設定，手動輸入：`26.46.176.133:8000`

## 步驟4：測試連線

### 4.1 你（主機）的測試
1. 啟動伺服器：`start_server_radmin.bat`
2. 啟動客戶端：`start_client_fixed.bat`
3. 測試連線：`test_radmin_connection.bat`

### 4.2 朋友的測試
1. 確保 RadminVPN 已連接
2. 啟動 holoDelta 客戶端
3. 檢查是否能連接到伺服器

## 故障排除

### 常見問題

#### 1. 朋友無法連接到伺服器
**檢查項目**：
- 確認朋友已加入 RadminVPN 網路
- 確認你的伺服器正在運行
- 確認防火牆設定
- 確認 IP 地址正確

#### 2. 連線超時
**解決方案**：
- 檢查 RadminVPN 連線狀態
- 重新啟動 RadminVPN
- 檢查網路設定

#### 3. 防火牆問題
**Windows 防火牆設定**：
1. 打開 Windows Defender 防火牆
2. 點擊 "允許應用程式或功能通過 Windows Defender 防火牆"
3. 找到並勾選：
   - Python
   - Godot
4. 確保端口 8000 是開放的

#### 4. 伺服器無法啟動
**檢查項目**：
- 確認 Python 已安裝
- 確認依賴包已安裝
- 確認端口 8000 沒有被其他程式佔用

## 安全注意事項

1. **網路密碼**：使用強密碼保護你的 RadminVPN 網路
2. **信任的朋友**：只邀請你信任的朋友加入網路
3. **定期更換密碼**：定期更換網路密碼以保持安全
4. **防火牆**：確保防火牆設定正確

## 完整啟動流程

### 你的操作順序：
1. 啟動 RadminVPN
2. 啟動伺服器：`start_server_radmin.bat`
3. 啟動客戶端：`start_client_fixed.bat`
4. 測試連線：`test_radmin_connection.bat`
5. 分享網路資訊給朋友

### 朋友的操作順序：
1. 安裝 RadminVPN
2. 加入你的網路
3. 啟動 holoDelta 客戶端
4. 連接到 `26.46.176.133:8000`

## 技術支援

如果遇到問題：
1. 檢查 RadminVPN 連線狀態
2. 確認伺服器正常運行
3. 檢查防火牆設定
4. 嘗試重新啟動所有相關程式

現在你可以開始和朋友們一起遊玩 holoDelta 了！

