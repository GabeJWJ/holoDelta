# holoDelta

An unofficial Hololive TCG simulator, worked on in my spare time.

Original project by [@GabeJWJ](https://github.com/GabeJWJ/holoDelta)

## About

holoDelta is a fan-made simulator for the Hololive Trading Card Game. This project includes enhanced launcher tools to make it easier to run your own local server and client.

## Quick Start

### Option 1: Enhanced Launcher (Recommended)
1. Navigate to the `tool` folder
2. Run `start_launcher_with_check.bat` (Windows) or `start_launcher.sh` (Linux/macOS)
3. The launcher will automatically detect and install dependencies

### Option 2: Simple Launcher
If you encounter issues with the enhanced launcher:
1. Navigate to the `tool` folder  
2. Run `simple_launcher.bat`

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

To run your own server:
1. All server code is in the `ServerStuff` folder
2. Change the `websocketURL` in `Scripts/server.gd` to your local server address
3. Set `WebSocket` in `board` to not use wss for local development

## Contributing

This project welcomes community contributions. The original author is committed to accepting and encouraging community contributions.

If you're interested in contributing but find the code confusing, feel free to contact the original author for guidance.

## License

MIT License

## Acknowledgments

- Original project by [GabeJWJ](https://github.com/GabeJWJ/holoDelta)
- Enhanced launcher tools added for better user experience