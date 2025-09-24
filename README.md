# holoDelta-Traditional Chinese version

Original project by [@GabeJWJ](https://github.com/GabeJWJ/holoDelta)

---

## 中文 (繁體)

# holoDelta-繁體中文版

原始專案來自 [@GabeJWJ](https://github.com/GabeJWJ/holoDelta)

## 關於

holoDelta 是一個粉絲製作的 Hololive 交易卡牌遊戲模擬器。此專案包含啟動器工具，讓您更容易運行自己的本地伺服器和客戶端，並支援繁體中文。此專案主要由 AI 編程構建，目的是讓我和我的朋友能夠順暢地遊玩 holoDelta。

## 快速開始

### 選項 1: 啟動器 (推薦)
1. 進入 `tool` 資料夾
2. 執行 `holoDelta_launcher.bat` (Windows) 或 `start_launcher.sh` (Linux/macOS)
3. 啟動器會自動檢測並安裝依賴項目

### 選項 2: 簡易啟動器
如果增強版啟動器遇到問題：
1. 進入 `tool` 資料夾
2. 將 `direct_launch.bat` 移動到 holodelta 的根目錄
3. 執行 `direct_launch.bat`

### 選項 3: 手動設定
1. 安裝 Python 3.7+ 和 Godot 4.3+
2. 安裝伺服器依賴項目：`pip install -r ServerStuff/requirements.txt`
3. 啟動伺服器：`uvicorn server:app --reload` (從 ServerStuff 資料夾)
4. 啟動客戶端：`godot --path . --headless=false`

## 系統需求

- Python 3.7 或更高版本
- Godot 4.3 或更高版本
- FastAPI 和 uvicorn (由啟動器自動安裝)

## 伺服器設定

1. 設定區域網路環境，我使用的是 RadminVPN
2. 開啟啟動器並輸入您的區域網路 IP(若是伺服器主需要啟動伺服器端和客戶端)
3. 注意！您的朋友也應該輸入伺服器主的區域網路 IP，而不是他們自己的

---

## 日本語

# holoDelta-繁体中国語版

オリジナルプロジェクト：[@GabeJWJ](https://github.com/GabeJWJ/holoDelta)

## について

holoDelta は Hololive トレーディングカードゲームのファンメイドシミュレーターです。このプロジェクトには、独自のローカルサーバーとクライアントを簡単に実行できるランチャーツールが含まれており、繁体中国語をサポートしています。このプロジェクトは主に AI コーディングで構築され、私と友人が holoDelta をスムーズにプレイできるようにすることを目的としています。

## クイックスタート

### オプション 1: ランチャー (推奨)
1. `tool` フォルダに移動
2. `holoDelta_launcher.bat` (Windows) または `start_launcher.sh` (Linux/macOS) を実行
3. ランチャーが自動的に依存関係を検出・インストールします

### オプション 2: シンプルランチャー
拡張ランチャーで問題が発生した場合：
1. `tool` フォルダに移動
2. `direct_launch.bat` を holodelta のルートディレクトリに移動
3. `direct_launch.bat` を実行

### オプション 3: 手動セットアップ
1. Python 3.7+ と Godot 4.3+ をインストール
2. サーバー依存関係をインストール：`pip install -r ServerStuff/requirements.txt`
3. サーバーを開始：`uvicorn server:app --reload` (ServerStuff フォルダから)
4. クライアントを起動：`godot --path . --headless=false`

## システム要件

- Python 3.7 以上
- Godot 4.3 以上
- FastAPI と uvicorn (ランチャーが自動インストール)

## サーバーセットアップ

1. LAN 環境を設定（私は RadminVPN を使用）
2. ランチャーを開いて LAN IP を入力（サーバー主の場合はサーバー端とクライアント端の両方を起動する必要があります）
3. 注意！友達も自分の LAN IP ではなく、サーバー主の LAN IP を入力する必要があります

---

## English

## About

holoDelta is a fan-made simulator for the Hololive Trading Card Game. This project includes launcher tools to make it easier to run your own local server and client and supports traditional chinese.This project is built mostly by AI coding, and it's for me and my friend to play holoDelta smoothly.

## Quick Start

### Option 1:  Launcher (Recommended)
1. Navigate to the `tool` folder
2. Run `holoDelta_launcher.bat` (Windows)Z or `start_launcher.sh` (Linux/macOS)
3. The launcher will automatically detect and install dependencies

### Option 2: Simple Launcher
If you encounter issues with the enhanced launcher:
1. Navigate to the `tool` folder  
2. move `direct_launch.bat` to holodelta's root directory
3. run `direct_launch.bat`

### Option 3: Manual Setup
1. Install Python 3.7+ and Godot 4.3+
2. Install server dependencies: `pip install -r ServerStuff/requirements.txt`
3. Start server: `uvicorn server:app --reload` (from ServerStuff folder)
4. Launch client: `godot --path . --headless=false`

## Requirements

- Python 3.7 or higher
- Godot 4.3 or higher
- FastAPI and uvicorn (installed automatically by launcher)

## Server Setup

1. set up a LAN enviroment, in my case, I use RadminVPN
2. open launcher and input your LAN IP (if you are the server host, you need to start both server and client)
3. !CAUTION! YOUR FRIEND SHOULD ALSO INPUT THE SERVER HOST'S LAN IP NOT THEIR'S  

