@echo off
title 測試牌組資訊修復
echo ========================================
echo       測試牌組資訊修復
echo ========================================
echo.

echo [INFO] 已修復的問題：
echo 1. Scenes/deck_info.gd:23 - 添加 int() 類型轉換
echo 2. Scripts/card.gd:75 - 添加 int() 類型轉換
echo.

echo [INFO] 修復內容：
echo - 將 artNum = deck_info.oshi[1] 改為 artNum = int(deck_info.oshi[1])
echo - 將 artNum = art_code 改為 artNum = int(art_code)
echo.

echo [INFO] 這解決了以下錯誤：
echo "Invalid access to property or key '0.0' on a base object of type 'Dictionary'"
echo.

echo [INFO] 原因：
echo - JSON 解析時數字可能被解析為浮點數 (0.0)
echo - 但代碼期望整數 (0)
echo - 字典鍵必須是字符串，所以 '0.0' 和 '0' 是不同的鍵
echo.

echo [INFO] 現在請：
echo 1. 重新啟動客戶端
echo 2. 嘗試選擇牌組
echo 3. 檢查是否還有錯誤
echo.

echo ========================================
echo 按任意鍵退出...
pause >nul

