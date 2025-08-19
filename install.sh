#!/bin/bash

# Simple Ethereum Validator Readiness Checker
# Downloads and runs immediately - no installation needed

echo "🚀 Ethereum Validator Readiness Checker"
echo "========================================"

# Check Python 3
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 required. Install with:"
    echo "   sudo apt install python3"
    exit 1
fi

# Check requests
if ! python3 -c "import requests" 2>/dev/null; then
    echo "📦 Installing requests..."
    pip3 install --user requests || pip3 install --user --break-system-packages requests || {
        echo "❌ Could not install requests. Install manually:"
        echo "   pip3 install requests"
        exit 1
    }
fi

echo "✅ Requirements met"
echo ""

# Download and run checker
echo "📥 Running validator readiness checker..."
TEMP_FILE="/tmp/validator_check_$(date +%s).py"

# Create the checker script directly (embedded)
cat > "$TEMP_FILE" << 'EOF'
#!/usr/bin/env python3
import requests
import socket
import sys
import time
from datetime import datetime

def print_green(text): print(f"\033[92m{text}\033[0m")
def print_red(text): print(f"\033[91m{text}\033[0m")
def print_yellow(text): print(f"\033[93m{text}\033[0m")
def print_blue(text): print(f"\033[94m{text}\033[0m")
def print_cyan(text): print(f"\033[96m{text}\033[0m")

def print_header():
    print_blue("\n" + "="*60)
    print_cyan("🚀 ETHEREUM VALIDATOR READINESS CHECKER")
    print("Check if your nodes are ready for validator duties")
    print_blue("="*60)

def get_user_rpcs():
    print_yellow("\n📝 Enter your node RPC URLs:")
    print()
    print_cyan("🔗 Beacon Chain RPC:")
    print("   Examples: http://localhost:5052, http://192.168.1.100:5052")
    beacon_url = input("   Beacon URL: ").strip()
    if not beacon_url:
        beacon_url = "http://localhost:5052"
        print_yellow(f"   Using default: {beacon_url}")
    print()
    print_cyan("🔗 Sepolia RPC:")
    print("   Examples: http://localhost:8545, http://192.168.1.100:8545")
    sepolia_url = input("   Sepolia URL: ").strip()
    if not sepolia_url:
        sepolia_url = "http://localhost:8545"
        print_yellow(f"   Using default: {sepolia_url}")
    return beacon_url, sepolia_url

def test_port(host, port, timeout=10):
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(timeout)
        result = sock.connect_ex((host, port))
        sock.close()
        return result == 0
    except:
        return False

def parse_url(url):
    try:
        if "://" in url:
            protocol, rest = url.split("://", 1)
            if ":" in rest:
                host, port_part = rest.split(":", 1)
                port = int(port_part.split("/")[0])
            else:
                host = rest.split("/")[0]
                port = 443 if protocol == "https" else 80
        else:
            if ":" in url:
                host, port = url.split(":")
                port = int(port)
            else:
                host = url
                port = 80
        return host, port
    except:
        return None, None

def log_result(message, status="info"):
    timestamp = datetime.now().strftime("%H:%M:%S")
    if status == "success":
        print_green(f"[{timestamp}] ✅ {message}")
    elif status == "error":
        print_red(f"[{timestamp}] ❌ {message}")
    elif status == "warning":
        print_yellow(f"[{timestamp}] ⚠️ {message}")
    else:
        print_blue(f"[{timestamp}] ℹ️ {message}")

def check_beacon_validator_ready(url):
    print_yellow("\n🔍 CHECKING BEACON CHAIN NODE")
    print_yellow("-" * 30)
    
    host, port = parse_url(url)
    if not host:
        log_result("Invalid Beacon URL format", "error")
        return False, 0
    
    score = 0
    log_result(f"Testing connection to {host}:{port}...")
    if not test_port(host, port):
        log_result(f"Cannot connect to {host}:{port}", "error")
        log_result("Check: Is beacon node running? Firewall open?", "warning")
        return False, 0
    
    log_result("Connection successful", "success")
    score += 20
    
    try:
        log_result("Checking node health...")
        response = requests.get(f"{url}/eth/v1/node/health", timeout=15)
        if response.status_code == 200:
            log_result("Beacon node is healthy", "success")
            score += 25
        else:
            log_result(f"Health check failed (HTTP {response.status_code})", "error")
            return False, score
        
        log_result("Checking sync status...")
        response = requests.get(f"{url}/eth/v1/node/syncing", timeout=15)
        if response.status_code == 200:
            sync_data = response.json()
            is_syncing = sync_data.get("data", {}).get("is_syncing", True)
            if not is_syncing:
                log_result("Node is FULLY SYNCED - Ready for validator", "success")
                score += 30
            else:
                log_result("Node is SYNCING - NOT ready for validator", "error")
                return False, score
        
        log_result("Checking peer connections...")
        response = requests.get(f"{url}/eth/v1/node/peers", timeout=15)
        if response.status_code == 200:
            peers_data = response.json()
            peer_count = len(peers_data.get("data", []))
            if peer_count >= 50:
                log_result(f"Excellent peer count: {peer_count} (optimal for validators)", "success")
                score += 15
            elif peer_count >= 20:
                log_result(f"Good peer count: {peer_count} (sufficient for validators)", "success")
                score += 10
            elif peer_count >= 5:
                log_result(f"Low peer count: {peer_count} (risky for validators)", "warning")
                score += 5
            else:
                log_result(f"Very low peers: {peer_count} (dangerous for validators)", "error")
        
        log_result("Testing response speed...")
        start_time = time.time()
        response = requests.get(f"{url}/eth/v1/beacon/headers/head", timeout=15)
        response_time = (time.time() - start_time) * 1000
        
        if response_time < 500:
            log_result(f"Excellent response: {response_time:.0f}ms", "success")
            score += 10
        elif response_time < 1000:
            log_result(f"Good response: {response_time:.0f}ms", "success")
            score += 5
        else:
            log_result(f"Slow response: {response_time:.0f}ms (risk of missed attestations)", "warning")
        
        return True, score
        
    except Exception as e:
        log_result(f"Error checking beacon: {str(e)}", "error")
        return False, score

def check_sepolia_validator_ready(url):
    print_yellow("\n🔍 CHECKING SEPOLIA RPC NODE")
    print_yellow("-" * 27)
    
    host, port = parse_url(url)
    if not host:
        log_result("Invalid Sepolia URL format", "error")
        return False, 0
    
    score = 0
    log_result(f"Testing connection to {host}:{port}...")
    if not test_port(host, port):
        log_result(f"Cannot connect to {host}:{port}", "error")
        log_result("Check: Is Sepolia node running? Firewall open?", "warning")
        return False, 0
    
    log_result("Connection successful", "success")
    score += 20
    
    try:
        log_result("Testing RPC functionality...")
        payload = {"jsonrpc": "2.0", "method": "eth_chainId", "params": [], "id": 1}
        response = requests.post(url, json=payload, timeout=15)
        
        if response.status_code == 200:
            result = response.json()
            if "result" in result:
                chain_id = int(result["result"], 16)
                if chain_id == 11155111:
                    log_result("Confirmed Sepolia testnet", "success")
                    score += 25
                else:
                    log_result(f"Unexpected chain ID: {chain_id}", "warning")
                    score += 10
        else:
            log_result("RPC request failed", "error")
            return False, score
        
        log_result("Checking sync status...")
        payload = {"jsonrpc": "2.0", "method": "eth_syncing", "params": [], "id": 1}
        response = requests.post(url, json=payload, timeout=15)
        
        if response.status_code == 200:
            result = response.json()
            if "result" in result:
                sync_result = result["result"]
                if sync_result is False:
                    log_result("Node is FULLY SYNCED", "success")
                    score += 30
                else:
                    log_result("Node is SYNCING - not ready for validator", "error")
                    return False, score
        
        log_result("Checking latest block...")
        payload = {"jsonrpc": "2.0", "method": "eth_blockNumber", "params": [], "id": 1}
        response = requests.post(url, json=payload, timeout=15)
        
        if response.status_code == 200:
            result = response.json()
            if "result" in result:
                latest_block = int(result["result"], 16)
                log_result(f"Latest block: {latest_block:,}", "success")
                score += 15
        
        log_result("Testing response speed...")
        start_time = time.time()
        payload = {"jsonrpc": "2.0", "method": "eth_blockNumber", "params": [], "id": 1}
        response = requests.post(url, json=payload, timeout=15)
        response_time = (time.time() - start_time) * 1000
        
        if response_time < 300:
            log_result(f"Excellent response: {response_time:.0f}ms", "success")
            score += 10
        elif response_time < 1000:
            log_result(f"Good response: {response_time:.0f}ms", "success")
            score += 5
        else:
            log_result(f"Slow response: {response_time:.0f}ms", "warning")
        
        return True, score
        
    except Exception as e:
        log_result(f"Error checking Sepolia: {str(e)}", "error")
        return False, score

def print_validator_summary(beacon_ok, beacon_score, sepolia_ok, sepolia_score):
    print_blue("\n🎯 VALIDATOR READINESS ASSESSMENT")
    print_blue("="*50)
    
    overall_score = (beacon_score + sepolia_score) / 2
    
    print()
    print_cyan("📊 SCORES:")
    print(f"   Beacon Chain: {beacon_score}/100")
    print(f"   Sepolia RPC:  {sepolia_score}/100")
    print(f"   Overall:      {overall_score:.0f}/100")
    print()
    
    if beacon_ok and sepolia_ok and overall_score >= 85:
        print_green("🟢 EXCELLENT - READY FOR VALIDATOR DUTIES")
        print_green("   Your nodes are reliable for validator operations")
        print_green("   ✅ Low risk of missed attestations")
        print_green("   ✅ Should handle validator requests well")
        validator_ready = True
    elif beacon_ok and sepolia_ok and overall_score >= 70:
        print_yellow("🟡 GOOD - SUITABLE FOR VALIDATOR")
        print_yellow("   Your nodes should work for validators")
        print_yellow("   ⚠️ Monitor performance closely")
        validator_ready = True
    else:
        print_red("🔴 NOT READY - DO NOT RUN VALIDATOR")
        print_red("   Your nodes may cause missed attestations")
        print_red("   ❌ Fix issues before running validator")
        validator_ready = False
    
    print()
    print_cyan("💡 VALIDATOR RECOMMENDATIONS:")
    print("   • Ensure both nodes are fully synced")
    print("   • Maintain good peer connections (20+ recommended)")
    print("   • Monitor response times < 500ms")
    print("   • Set up monitoring and alerts")
    print("   • Have backup node connections ready")
    
    print_blue("="*50)
    return validator_ready

def main():
    try:
        print_header()
        beacon_url, sepolia_url = get_user_rpcs()
        print_blue("\n🚀 Starting validator readiness check...")
        beacon_ok, beacon_score = check_beacon_validator_ready(beacon_url)
        sepolia_ok, sepolia_score = check_sepolia_validator_ready(sepolia_url)
        validator_ready = print_validator_summary(beacon_ok, beacon_score, sepolia_ok, sepolia_score)
        sys.exit(0 if validator_ready else 1)
    except KeyboardInterrupt:
        print_yellow("\n\n⚠️ Check cancelled by user")
        sys.exit(1)
    except Exception as e:
        print_red(f"\n❌ Error: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main()
EOF

# Run the checker
python3 "$TEMP_FILE"
exit_code=$?

# Clean up
rm -f "$TEMP_FILE"

exit $exit_code
