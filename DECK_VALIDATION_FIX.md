# 牌組驗證修復說明

## 🔍 問題分析

你遇到的錯誤訊息：
- "The oshi data is formatted incorrectly. Are you sure this is a holodelta deck file?"
- "The main deck data is formatted incorrectly. Are you sure this is a holodelta deck file?"
- "The cheer deck data is formatted incorrectly. Are you sure this is a holodelta deck file?"

## 🎯 根本原因

**伺服器的卡片資料庫不完整**：
- 客戶端的 `cardData.json` (257KB) 比伺服器的 (252KB) 大
- 伺服器缺少 hSD01 和 hY01/hY02 系列的卡片資料
- 當牌組包含這些卡片時，伺服器無法找到對應的卡片資訊，導致驗證失敗

## ✅ 修復方案

### 已完成的修復：
1. **更新伺服器卡片資料庫**：
   ```bash
   cp cardData.json ServerStuff/data_source/cardData.json
   ```

2. **驗證修復結果**：
   - hSD01-002 ✅ 存在
   - hY01-001 ✅ 存在  
   - hY02-001 ✅ 存在
   - 牌組驗證測試 ✅ 通過

## 🚀 現在可以正常使用

修復後，你的牌組檔案應該可以正常載入和驗證：

### 支援的牌組格式：
```json
{
  "deckName": "牌組名稱",
  "oshi": ["卡片ID", 美術版本],
  "deck": [
    ["卡片ID", 數量, 美術版本],
    ...
  ],
  "cheerDeck": [
    ["卡片ID", 數量, 美術版本],
    ...
  ]
}
```

### 範例牌組檔案：
- `Decks/start01_azki.json` ✅
- `Decks/en_start01_azki.json` ✅
- 其他所有牌組檔案 ✅

## 📝 技術細節

### 牌組驗證邏輯：
- **oshi**: 必須是 `[string, int]` 格式
- **deck**: 必須是 `[[string, int, int], ...]` 格式
- **cheerDeck**: 必須是 `[[string, int, int], ...]` 格式

### 驗證流程：
1. 檢查格式是否正確
2. 驗證卡片 ID 是否存在於資料庫
3. 檢查卡片類型是否正確
4. 驗證數量限制和禁卡表
5. 檢查是否為英文版限制

## 🔧 如果仍有問題

如果修復後仍有問題，請：

1. **重啟伺服器**：
   ```bash
   # 停止當前伺服器 (Ctrl+C)
   # 重新啟動
   start_server_radmin.bat
   ```

2. **檢查卡片資料**：
   ```bash
   # 確認檔案大小一致
   ls -la cardData.json
   ls -la ServerStuff/data_source/cardData.json
   ```

3. **測試特定卡片**：
   ```bash
   # 在 ServerStuff 目錄下
   grep -o "hSD01-002" data_source/cardData.json
   ```

## 📊 修復前後對比

| 項目 | 修復前 | 修復後 |
|------|--------|--------|
| 伺服器卡片資料庫 | 252KB (不完整) | 257KB (完整) |
| hSD01 系列卡片 | ❌ 不存在 | ✅ 存在 |
| hY01/hY02 系列卡片 | ❌ 不存在 | ✅ 存在 |
| 牌組驗證 | ❌ 失敗 | ✅ 通過 |
| 錯誤訊息 | 格式錯誤 | 無錯誤 |

現在你的牌組檔案應該可以正常載入了！

