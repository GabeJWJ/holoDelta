#!/bin/bash

echo "========================================"
echo "   HoloDelta - Enhanced Launcher"
echo "========================================"
echo ""
echo "[INFO] Starting enhanced visual launcher..."
echo ""

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    if ! command -v python &> /dev/null; then
        echo "[ERROR] Python is not installed or not in PATH"
        echo "Please install Python 3.7+ using one of the following methods:"
        echo "  1. Download from https://www.python.org/downloads/"
        echo "  2. Use Homebrew: brew install python"
        echo "  3. Use MacPorts: sudo port install python37"
        echo ""
        read -p "Press Enter to exit..."
        exit 1
    else
        PYTHON_CMD="python"
    fi
else
    PYTHON_CMD="python3"
fi

# Check Python version
PYTHON_VERSION=$($PYTHON_CMD --version 2>&1 | cut -d' ' -f2 | cut -d'.' -f1,2)
REQUIRED_VERSION="3.7"

if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$PYTHON_VERSION" | sort -V | head -n1)" != "$REQUIRED_VERSION" ]; then
    echo "[ERROR] Python version $PYTHON_VERSION is too old"
    echo "Please install Python 3.7 or higher"
    echo ""
    read -p "Press Enter to exit..."
    exit 1
fi

# Check if the launcher file exists
if [ ! -f "holoDelta_launcher_enhanced.py" ]; then
    echo "[ERROR] holoDelta_launcher_enhanced.py not found"
    echo "Please make sure you are running this script from the correct directory"
    echo ""
    read -p "Press Enter to exit..."
    exit 1
fi

# Start the launcher
echo "[INFO] Launching HoloDelta Enhanced Launcher..."
$PYTHON_CMD holoDelta_launcher_enhanced.py

# Check if the launcher exited with an error
if [ $? -ne 0 ]; then
    echo ""
    echo "[ERROR] Launcher execution failed"
    echo "Please check Python environment and dependencies"
    echo ""
    read -p "Press Enter to exit..."
    exit 1
fi

echo ""
echo "[INFO] Launcher closed successfully"
read -p "Press Enter to exit..."
