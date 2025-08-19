#!/bin/bash

# Simple Ethereum Node Health Checker - Direct Run
# Downloads and runs the health checker immediately

echo "🚀 Ethereum Node Health Checker"
echo "================================"
echo ""

# Check if Python 3 is available
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is required but not installed"
    echo "Please install Python 3 first:"
    echo "  Ubuntu/Debian: sudo apt install python3"
    echo "  CentOS/RHEL: sudo yum install python3" 
    exit 1
fi

# Check if requests module is available
if ! python3 -c "import requests" &> /dev/null; then
    echo "📦 Installing required Python module..."
    if pip3 install --user requests &> /dev/null; then
        echo "✅ Requests module installed"
    elif pip3 install --user --break-system-packages requests &> /dev/null; then
        echo "✅ Requests module installed"
    else
        echo "⚠️  Could not install requests module automatically"
        echo "Please install manually: pip3 install requests"
        exit 1
    fi
fi

# Download and run the health checker
echo "📥 Downloading health checker..."
TEMP_FILE="/tmp/eth_health_check_$(date +%s).py"

if command -v curl >/dev/null 2>&1; then
    curl -fsSL "https://raw.githubusercontent.com/Aabis5004/eth-node-health-checker/main/simple_checker.py" -o "$TEMP_FILE"
elif command -v wget >/dev/null 2>&1; then
    wget -q "https://raw.githubusercontent.com/Aabis5004/eth-node-health-checker/main/simple_checker.py" -O "$TEMP_FILE"
else
    echo "❌ Neither curl nor wget found. Please install one of them."
    exit 1
fi

if [ -f "$TEMP_FILE" ]; then
    echo "✅ Download complete"
    echo ""
    echo "🔍 Starting health check..."
    echo ""
    
    # Run the health checker
    python3 "$TEMP_FILE"
    
    # Clean up
    rm -f "$TEMP_FILE"
else
    echo "❌ Download failed"
    exit 1
fi
