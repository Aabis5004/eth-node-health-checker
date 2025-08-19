#!/bin/bash

# Ethereum Validator Readiness Checker - Instant Run
# No external dependencies except Python 3 standard library

echo "🔥 Ethereum Validator Readiness Checker"
echo "========================================"
echo ""

# Check if Python 3 is available
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is required but not installed"
    echo ""
    echo "Install Python 3:"
    echo "  Ubuntu/Debian: sudo apt install python3"
    echo "  CentOS/RHEL:   sudo yum install python3"
    echo "  macOS:         brew install python3"
    exit 1
fi

echo "✅ Python 3 found - no additional dependencies needed"
echo ""

# Download and run the validator readiness checker
echo "📥 Downloading validator readiness checker..."
TEMP_FILE="/tmp/validator_checker_$(date +%s).py"

if command -v curl >/dev/null 2>&1; then
    if curl -fsSL "https://raw.githubusercontent.com/Aabis5004/eth-node-health-checker/main/simple_checker.py" -o "$TEMP_FILE" 2>/dev/null; then
        echo "✅ Download successful"
    else
        echo "❌ Download failed - check your internet connection"
        echo "   URL: https://raw.githubusercontent.com/Aabis5004/eth-node-health-checker/main/simple_checker.py"
        exit 1
    fi
elif command -v wget >/dev/null 2>&1; then
    if wget -q "https://raw.githubusercontent.com/Aabis5004/eth-node-health-checker/main/simple_checker.py" -O "$TEMP_FILE" 2>/dev/null; then
        echo "✅ Download successful"
    else
        echo "❌ Download failed - check your internet connection"
        exit 1
    fi
else
    echo "❌ Neither curl nor wget found"
    echo "Please install curl: sudo apt install curl"
    exit 1
fi

if [ -f "$TEMP_FILE" ] && [ -s "$TEMP_FILE" ]; then
    echo ""
    echo "🔍 Starting validator readiness assessment..."
    echo ""
    
    # Run the validator readiness checker
    python3 "$TEMP_FILE"
    EXIT_CODE=$?
    
    # Clean up
    rm -f "$TEMP_FILE"
    
    exit $EXIT_CODE
else
    echo "❌ Download failed or file is empty"
    rm -f "$TEMP_FILE"
    exit 1
fi
