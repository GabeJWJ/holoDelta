# HoloDelta Enhanced Launcher

<div align="center">

[中文](#中文) | [English](#english) | [日本語](#日本語)

</div>

---

## 中文

一個功能豐富的HoloDelta遊戲啟動器，提供美觀的圖形界面和多語言支持。

### ✨ 功能特色

- 🎨 **現代化設計** - 基於Figma設計的膠囊狀按鈕和漸變配色
- 🌍 **多語言支持** - 支持英文、日文、中文三種語言
- 🔧 **環境檢測** - 自動檢測Python、Godot和項目依賴
- 🖥️ **服務器管理** - 一鍵啟動/停止服務器和客戶端
- 📱 **響應式界面** - 自適應滾動界面，支持不同屏幕尺寸
- ⚙️ **配置管理** - 自動備份和恢復配置文件

### 🚀 快速開始

#### 系統要求

- **Python**: 3.7 或更高版本
- **操作系統**: Windows 10+, macOS 10.14+, Ubuntu 18.04+
- **依賴**: tkinter (通常隨Python一起安裝)

#### 安裝步驟

1. **下載項目文件**
   ```bash
   # 確保您有以下文件：
   # - holoDelta_launcher_enhanced.py
   # - languages.json
   # - launcher_config.json
   # - NotoSans-Black.ttf
   ```

2. **選擇適合您系統的啟動方式**

### 🖥️ 各系統啟動方式

#### Windows

**方法1: 使用啟動腳本 (推薦)**
```cmd
# 雙擊運行
start_launcher.bat
```

**方法1.5: 使用tkinter檢測啟動器 (推薦)**
```cmd
# 自動檢測並安裝tkinter，雙擊運行
start_launcher_with_check.bat
```

**方法2: 直接運行Python**
```cmd
python holoDelta_launcher_enhanced.py
```

**方法3: 簡易啟動器 (備用方案)**
```cmd
# 如果增強版啟動器無法正常運行，使用此簡易版本
simple_launcher.bat
```

#### Linux

**方法1: 使用啟動腳本 (推薦)**
```bash
# 在終端中運行
./start_launcher.sh
```

**方法2: 直接運行Python**
```bash
python3 holoDelta_launcher_enhanced.py
```

#### macOS

**方法1: 使用啟動腳本 (推薦)**
```bash
# 在終端中運行
./start_launcher.command
```

**方法2: 直接運行Python**
```bash
python3 holoDelta_launcher_enhanced.py
```

### 🎮 使用指南

#### 語言切換
- 點擊右上角的語言選擇器
- 支持英文 (English)、日文 (日本語)、中文 (中文)

#### 環境檢測
啟動器會自動檢測：
- ✅ Python環境
- ✅ Godot引擎
- ✅ Python套件依賴
- ✅ 項目文件完整性

#### 服務器設置
- **局域網IP**: 自動檢測或手動輸入
- **端口設置**: 默認端口配置
- **客戶端配置**: 一鍵更新和恢復

#### 服務器管理
- **啟動服務器**: 點擊"啟動伺服器"按鈕
- **啟動客戶端**: 點擊"啟動客戶端"按鈕
- **停止服務**: 點擊對應的停止按鈕

### 🎨 界面設計

#### 配色方案
- **主色調**: 紫色 (#625b93)
- **強調色**: 粉色 (#ff1c99)
- **背景**: 漸變 (#d8d9eb → #b4cfef)
- **按鈕**: 膠囊狀設計，8px紫色邊框

#### 字體
- **主字體**: Noto Sans Black
- **標題**: 32px
- **副標題**: 16px
- **正文**: 12px

### 🔧 故障排除

#### 常見問題

**Q: 啟動器無法啟動**
```
A: 請檢查：
1. Python是否正確安裝 (python --version)
2. tkinter是否可用 (python -c "import tkinter")
3. 所有必需文件是否在同一目錄
4. 如果仍有問題，請使用 simple_launcher.bat 作為備用方案
```

**Q: 增強版啟動器出現錯誤**
```
A: 如果增強版啟動器無法正常運行，請嘗試以下解決方案：
1. 使用 tkinter 檢測啟動器：start_launcher_with_check.bat
   - 自動檢測並安裝 tkinter
   - 提供詳細的安裝指南
2. 使用簡易啟動器：simple_launcher.bat
   - 不依賴 GUI 界面
   - 自動檢查環境和配置
```

**Q: tkinter 模組不可用**
```
A: 使用 start_launcher_with_check.bat 會自動：
1. 檢測 tkinter 是否可用
2. 嘗試自動安裝 tkinter
3. 提供各系統的安裝指南
4. 如果無法安裝，提供簡易啟動器選項
```

**Q: 字體顯示異常**
```
A: 請確保 NotoSans-Black.ttf 文件存在於同一目錄
```

**Q: 服務器無法啟動**
```
A: 請檢查：
1. 端口是否被占用
2. Python依賴是否完整安裝
3. 項目文件是否完整
```

**Q: 語言切換不生效**
```
A: 請確保 languages.json 文件存在且格式正確
```

#### 錯誤代碼

- **錯誤1**: Python環境問題
- **錯誤2**: 依賴包缺失
- **錯誤3**: 配置文件損壞
- **錯誤4**: 端口占用

### 📁 文件結構

```
tool/
├── holoDelta_launcher_enhanced.py  # 主程序 (增強版GUI啟動器)
├── launcher_with_tkinter_check.py  # tkinter檢測器
├── simple_launcher.bat             # 簡易啟動器 (備用方案)
├── languages.json                  # 多語言翻譯
├── launcher_config.json           # 啟動器配置
├── NotoSans-Black.ttf             # 字體文件
├── start_launcher.bat             # Windows啟動腳本
├── start_launcher_with_check.bat  # Windows啟動腳本 (含tkinter檢測)
├── start_launcher.sh              # Linux啟動腳本
├── start_launcher.command         # macOS啟動腳本
└── README.md                      # 說明文件
```

### 🔄 更新日誌

#### v2.0.0 (當前版本)
- ✨ 全新Figma設計界面
- 🌍 完整多語言支持
- 🎨 膠囊狀按鈕和漸變配色
- 📱 響應式滾動界面
- 🔧 增強環境檢測
- ⚙️ 改進配置管理

#### v1.0.0
- 🎉 初始版本發布
- 基本啟動器功能
- 簡單圖形界面

### 🤝 貢獻

歡迎提交問題報告和功能建議！

### 📄 許可證

本項目採用 MIT 許可證。

### 📞 支持

如果您遇到任何問題，請：
1. 檢查本README的故障排除部分
2. 確認您的系統環境符合要求
3. 提交詳細的問題報告

---

## English

A feature-rich HoloDelta game launcher with beautiful GUI and multi-language support.

### ✨ Features

- 🎨 **Modern Design** - Capsule-shaped buttons and gradient colors based on Figma design
- 🌍 **Multi-language Support** - Supports English, Japanese, and Chinese
- 🔧 **Environment Detection** - Auto-detects Python, Godot, and project dependencies
- 🖥️ **Server Management** - One-click start/stop server and client
- 📱 **Responsive Interface** - Adaptive scrolling interface supporting different screen sizes
- ⚙️ **Configuration Management** - Auto backup and restore configuration files

### 🚀 Quick Start

#### System Requirements

- **Python**: 3.7 or higher
- **Operating System**: Windows 10+, macOS 10.14+, Ubuntu 18.04+
- **Dependencies**: tkinter (usually installed with Python)

#### Installation Steps

1. **Download Project Files**
   ```bash
   # Make sure you have the following files:
   # - holoDelta_launcher_enhanced.py
   # - languages.json
   # - launcher_config.json
   # - NotoSans-Black.ttf
   ```

2. **Choose the appropriate startup method for your system**

### 🖥️ Platform-Specific Startup Methods

#### Windows

**Method 1: Using Startup Script (Recommended)**
```cmd
# Double-click to run
start_launcher.bat
```

**Method 2: Direct Python Execution**
```cmd
python holoDelta_launcher_enhanced.py
```

#### Linux

**Method 1: Using Startup Script (Recommended)**
```bash
# Run in terminal
./start_launcher.sh
```

**Method 2: Direct Python Execution**
```bash
python3 holoDelta_launcher_enhanced.py
```

#### macOS

**Method 1: Using Startup Script (Recommended)**
```bash
# Run in terminal
./start_launcher.command
```

**Method 2: Direct Python Execution**
```bash
python3 holoDelta_launcher_enhanced.py
```

### 🎮 User Guide

#### Language Switching
- Click the language selector in the top-right corner
- Supports English, Japanese (日本語), and Chinese (中文)

#### Environment Detection
The launcher automatically detects:
- ✅ Python environment
- ✅ Godot engine
- ✅ Python package dependencies
- ✅ Project file integrity

#### Server Settings
- **LAN IP**: Auto-detect or manual input
- **Port Settings**: Default port configuration
- **Client Configuration**: One-click update and restore

#### Server Management
- **Start Server**: Click "Start Server" button
- **Start Client**: Click "Start Client" button
- **Stop Services**: Click corresponding stop buttons

### 🎨 Interface Design

#### Color Scheme
- **Primary Color**: Purple (#625b93)
- **Accent Color**: Pink (#ff1c99)
- **Background**: Gradient (#d8d9eb → #b4cfef)
- **Buttons**: Capsule design with 8px purple border

#### Typography
- **Main Font**: Noto Sans Black
- **Title**: 32px
- **Subtitle**: 16px
- **Body**: 12px

### 🔧 Troubleshooting

#### Common Issues

**Q: Launcher won't start**
```
A: Please check:
1. Python is properly installed (python --version)
2. tkinter is available (python -c "import tkinter")
3. All required files are in the same directory
```

**Q: Font display issues**
```
A: Make sure NotoSans-Black.ttf file exists in the same directory
```

**Q: Server won't start**
```
A: Please check:
1. Port is not occupied
2. Python dependencies are fully installed
3. Project files are complete
```

**Q: Language switching doesn't work**
```
A: Make sure languages.json file exists and has correct format
```

#### Error Codes

- **Error 1**: Python environment issues
- **Error 2**: Missing dependencies
- **Error 3**: Corrupted configuration files
- **Error 4**: Port occupied

### 📁 File Structure

```
tool/
├── holoDelta_launcher_enhanced.py  # Main program
├── languages.json                  # Multi-language translations
├── launcher_config.json           # Launcher configuration
├── NotoSans-Black.ttf             # Font file
├── start_launcher.bat             # Windows startup script
├── start_launcher.sh              # Linux startup script
├── start_launcher.command         # macOS startup script
└── README.md                      # Documentation
```

### 🔄 Changelog

#### v2.0.0 (Current Version)
- ✨ Brand new Figma-designed interface
- 🌍 Complete multi-language support
- 🎨 Capsule-shaped buttons and gradient colors
- 📱 Responsive scrolling interface
- 🔧 Enhanced environment detection
- ⚙️ Improved configuration management

#### v1.0.0
- 🎉 Initial release
- Basic launcher functionality
- Simple graphical interface

### 🤝 Contributing

Welcome to submit issue reports and feature suggestions!

### 📄 License

This project is licensed under the MIT License.

### 📞 Support

If you encounter any issues, please:
1. Check the troubleshooting section in this README
2. Verify your system environment meets requirements
3. Submit detailed issue reports

---

## 日本語

美しいGUIと多言語サポートを提供する機能豊富なHoloDeltaゲームランチャー。

### ✨ 機能

- 🎨 **モダンデザイン** - Figmaデザインに基づくカプセル型ボタンとグラデーション配色
- 🌍 **多言語サポート** - 英語、日本語、中国語をサポート
- 🔧 **環境検出** - Python、Godot、プロジェクト依存関係を自動検出
- 🖥️ **サーバー管理** - ワンクリックでサーバーとクライアントの開始/停止
- 📱 **レスポンシブインターフェース** - 異なる画面サイズに対応した適応スクロールインターフェース
- ⚙️ **設定管理** - 設定ファイルの自動バックアップと復元

### 🚀 クイックスタート

#### システム要件

- **Python**: 3.7以上
- **オペレーティングシステム**: Windows 10+, macOS 10.14+, Ubuntu 18.04+
- **依存関係**: tkinter (通常Pythonと一緒にインストール)

#### インストール手順

1. **プロジェクトファイルのダウンロード**
   ```bash
   # 以下のファイルがあることを確認してください：
   # - holoDelta_launcher_enhanced.py
   # - languages.json
   # - launcher_config.json
   # - NotoSans-Black.ttf
   ```

2. **お使いのシステムに適した起動方法を選択**

### 🖥️ プラットフォーム別起動方法

#### Windows

**方法1: 起動スクリプトを使用（推奨）**
```cmd
# ダブルクリックで実行
start_launcher.bat
```

**方法2: Python直接実行**
```cmd
python holoDelta_launcher_enhanced.py
```

#### Linux

**方法1: 起動スクリプトを使用（推奨）**
```bash
# ターミナルで実行
./start_launcher.sh
```

**方法2: Python直接実行**
```bash
python3 holoDelta_launcher_enhanced.py
```

#### macOS

**方法1: 起動スクリプトを使用（推奨）**
```bash
# ターミナルで実行
./start_launcher.command
```

**方法2: Python直接実行**
```bash
python3 holoDelta_launcher_enhanced.py
```

### 🎮 ユーザーガイド

#### 言語切り替え
- 右上の言語セレクターをクリック
- 英語、日本語、中国語（中文）をサポート

#### 環境検出
ランチャーは以下を自動検出します：
- ✅ Python環境
- ✅ Godotエンジン
- ✅ Pythonパッケージ依存関係
- ✅ プロジェクトファイルの整合性

#### サーバー設定
- **LAN IP**: 自動検出または手動入力
- **ポート設定**: デフォルトポート設定
- **クライアント設定**: ワンクリック更新と復元

#### サーバー管理
- **サーバー開始**: 「サーバー開始」ボタンをクリック
- **クライアント開始**: 「クライアント開始」ボタンをクリック
- **サービス停止**: 対応する停止ボタンをクリック

### 🎨 インターフェースデザイン

#### カラースキーム
- **プライマリカラー**: 紫 (#625b93)
- **アクセントカラー**: ピンク (#ff1c99)
- **背景**: グラデーション (#d8d9eb → #b4cfef)
- **ボタン**: 8px紫ボーダーのカプセルデザイン

#### タイポグラフィ
- **メインフォント**: Noto Sans Black
- **タイトル**: 32px
- **サブタイトル**: 16px
- **本文**: 12px

### 🔧 トラブルシューティング

#### よくある問題

**Q: ランチャーが起動しない**
```
A: 以下を確認してください：
1. Pythonが正しくインストールされているか (python --version)
2. tkinterが利用可能か (python -c "import tkinter")
3. すべての必要なファイルが同じディレクトリにあるか
```

**Q: フォント表示の問題**
```
A: NotoSans-Black.ttfファイルが同じディレクトリに存在することを確認してください
```

**Q: サーバーが起動しない**
```
A: 以下を確認してください：
1. ポートが占有されていないか
2. Python依存関係が完全にインストールされているか
3. プロジェクトファイルが完全か
```

**Q: 言語切り替えが機能しない**
```
A: languages.jsonファイルが存在し、正しい形式であることを確認してください
```

#### エラーコード

- **エラー1**: Python環境の問題
- **エラー2**: 依存関係の不足
- **エラー3**: 設定ファイルの破損
- **エラー4**: ポート占有

### 📁 ファイル構造

```
tool/
├── holoDelta_launcher_enhanced.py  # メインプログラム
├── languages.json                  # 多言語翻訳
├── launcher_config.json           # ランチャー設定
├── NotoSans-Black.ttf             # フォントファイル
├── start_launcher.bat             # Windows起動スクリプト
├── start_launcher.sh              # Linux起動スクリプト
├── start_launcher.command         # macOS起動スクリプト
└── README.md                      # ドキュメント
```

### 🔄 変更履歴

#### v2.0.0 (現在のバージョン)
- ✨ 全く新しいFigmaデザインインターフェース
- 🌍 完全な多言語サポート
- 🎨 カプセル型ボタンとグラデーションカラー
- 📱 レスポンシブスクロールインターフェース
- 🔧 強化された環境検出
- ⚙️ 改善された設定管理

#### v1.0.0
- 🎉 初回リリース
- 基本的なランチャー機能
- シンプルなグラフィカルインターフェース

### 🤝 貢献

問題報告や機能提案の提出を歓迎します！

### 📄 ライセンス

このプロジェクトはMITライセンスの下でライセンスされています。

### 📞 サポート

問題が発生した場合は、以下をお試しください：
1. このREADMEのトラブルシューティングセクションを確認
2. システム環境が要件を満たしていることを確認
3. 詳細な問題報告を提出

---

**HoloDeltaゲーム体験をお楽しみください！** 🎮✨