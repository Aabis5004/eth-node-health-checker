#!/bin/bash

# Ethereum Validator Readiness Checker
# Interactive version that asks for RPC URLs

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

# Create and run the interactive checker
TEMP_FILE="/tmp/validator_check_$(date +%s).py"

cat > "$TEMP_FILE" << 'EOF'
#!/usr/bin/env python3
"""
Interactive Ethereum Validator Readiness Checker
Asks user for RPC URLs and checks validator readiness
"""

import requests
import socket
import sys
import time
from datetime import datetime

# Colors
def print_green(text): print(f"\033[92m{text}\033[0m")
def print_red(text): print(f"\033[91m{text}\033[0m")
def print_yellow(text): print(f"\033[93m{text}\033[0m")
def print_blue(text): print(f"\033[94m{text}\033[0m")
def print_cyan(text): print(f"\033[96m{text}\033[0m")

def print_header():
    print_blue("\n" + "="*65)
    print_cyan("🔥 ETHEREUM VALIDATOR READINESS CHECKER")
    print("Check if your nodes can handle validator duties without missing attestations")
    print_blue("="*65)

def get_user_rpcs():
    """Interactive function to get RPC URLs from user"""
    print_yellow("\n📝 ENTER YOUR NODE RPC ENDPOINTS:")
    print()
    
    # Get Beacon Chain RPC
    print_cyan("🔗 BEACON CHAIN NODE:")
    print("   Examples:")
    print("   • http://localhost:5052")
    print("   • http://192.168.1.100:5052")
    print("   • https://your-beacon-node.com:5052")
    print()
    
    while True:
        beacon_url = input("👉 Enter your Beacon Chain RPC URL: ").strip()
        if beacon_url:
            break
        elif input("   Use default localhost:5052? (y/n): ").lower().startswith('y'):
            beacon_url = "http://localhost:5052"
            break
        print("   Please enter a valid URL")
    
    print_yellow(f"   ✅ Beacon URL: {beacon_url}")
    print()
    
    # Get Sepolia RPC
    print_cyan("🔗 SEPOLIA RPC NODE:")
    print("   Examples:")
    print("   • http://localhost:8545")
    print("   • http://192.168.1.100:8545")
    print("   • https://your-sepolia-rpc.com:8545")
    print()
    
    while True:
        sepolia_url = input("👉 Enter your Sepolia RPC URL: ").strip()
        if sepolia_url:
            break
        elif input("   Use default localhost:8545? (y/n): ").lower().startswith('y'):
            sepolia_url = "http://localhost:8545"
            break
        print("   Please enter a valid URL")
    
    print_yellow(f"   ✅ Sepolia URL: {sepolia_url}")
    
    return beacon_url, sepolia_url

def test_port(host, port, timeout=10):
    """Test if port is accessible"""
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(timeout)
        result = sock.connect_ex((host, port))
        sock.close()
        return result == 0
    except:
        return False

def parse_url(url):
    """Parse URL to extract host and port"""
    try:
        if "://" in url:
            protocol, rest = url.split("://", 1)
            if ":" in rest and "/" not in rest.split(":")[-1]:
                host, port_part = rest.rsplit(":", 1)
                port = int(port_part.split("/")[0])
            else:
                host = rest.split("/")[0]
                port = 443 if protocol == "https" else (5052 if "beacon" in url.lower() else 8545)
        else:
            if ":" in url:
                host, port = url.rsplit(":", 1)
                port = int(port)
            else:
                host = url
                port = 5052  # default for beacon
        return host, port
    except Exception as e:
        print_red(f"Error parsing URL {url}: {e}")
        return None, None

def log_result(message, status="info"):
    """Log result with colored output"""
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
    """Check if Beacon node is ready for validator duties"""
    print_yellow("\n🔍 CHECKING BEACON CHAIN - VALIDATOR READINESS")
    print_yellow("-" * 48)
    
    host, port = parse_url(url)
    if not host:
        log_result("Invalid Beacon URL format", "error")
        return False, 0, ["Invalid URL"]
    
    score = 0
    issues = []
    
    # Connection test
    log_result(f"Testing connection to {host}:{port}...")
    if not test_port(host, port):
        log_result(f"Cannot connect to {host}:{port}", "error")
        log_result("Possible issues: Node offline, firewall blocking, wrong IP/port", "warning")
        return False, 0, ["Connection failed"]
    
    log_result("Connection established successfully", "success")
    score += 20
    
    try:
        # Node health check
        log_result("Checking beacon node health status...")
        response = requests.get(f"{url}/eth/v1/node/health", timeout=15)
        if response.status_code == 200:
            log_result("Beacon node is healthy and responding", "success")
            score += 25
        else:
            log_result(f"Health check failed (HTTP {response.status_code})", "error")
            issues.append("Node health check failed")
            return False, score, issues
        
        # Sync status check (CRITICAL for validators)
        log_result("Checking synchronization status...")
        response = requests.get(f"{url}/eth/v1/node/syncing", timeout=15)
        if response.status_code == 200:
            sync_data = response.json()
            is_syncing = sync_data.get("data", {}).get("is_syncing", True)
            if not is_syncing:
                log_result("✓ Node is FULLY SYNCED - Ready for validator duties", "success")
                score += 35
            else:
                log_result("✗ Node is SYNCING - NOT ready for validator", "error")
                issues.append("Node still syncing")
                return False, score, issues
        else:
            log_result("Could not check sync status", "warning")
            issues.append("Sync status unknown")
        
        # Peer connectivity check
        log_result("Checking peer connections...")
        response = requests.get(f"{url}/eth/v1/node/peers", timeout=15)
        if response.status_code == 200:
            peers_data = response.json()
            peer_count = len(peers_data.get("data", []))
            if peer_count >= 50:
                log_result(f"Excellent peer count: {peer_count} peers (optimal)", "success")
                score += 15
            elif peer_count >= 25:
                log_result(f"Good peer count: {peer_count} peers (sufficient)", "success")
                score += 12
            elif peer_count >= 10:
                log_result(f"Adequate peer count: {peer_count} peers (minimum)", "warning")
                score += 8
                issues.append("Low peer count")
            else:
                log_result(f"Poor peer count: {peer_count} peers (risky for validators)", "error")
                score += 3
                issues.append("Very low peer count")
        
        # Response time test (critical for attestations)
        log_result("Testing response time for validator operations...")
        start_time = time.time()
        response = requests.get(f"{url}/eth/v1/beacon/headers/head", timeout=15)
        response_time = (time.time() - start_time) * 1000
        
        if response_time < 300:
            log_result(f"Excellent response time: {response_time:.0f}ms (optimal for validators)", "success")
            score += 5
        elif response_time < 800:
            log_result(f"Good response time: {response_time:.0f}ms (acceptable)", "success")
            score += 3
        elif response_time < 2000:
            log_result(f"Slow response time: {response_time:.0f}ms (may affect performance)", "warning")
            score += 1
            issues.append("Slow response time")
        else:
            log_result(f"Very slow response: {response_time:.0f}ms (risk of missed attestations)", "error")
            issues.append("Very slow response time")
        
        return True, score, issues
        
    except Exception as e:
        log_result(f"Error during beacon checks: {str(e)}", "error")
        return False, score, issues + [f"Check error: {str(e)}"]

def check_sepolia_validator_ready(url):
    """Check if Sepolia RPC is ready for validator support"""
    print_yellow("\n🔍 CHECKING SEPOLIA RPC - VALIDATOR SUPPORT")
    print_yellow("-" * 42)
    
    host, port = parse_url(url)
    if not host:
        log_result("Invalid Sepolia URL format", "error")
        return False, 0, ["Invalid URL"]
    
    score = 0
    issues = []
    
    # Connection test
    log_result(f"Testing connection to {host}:{port}...")
    if not test_port(host, port):
        log_result(f"Cannot connect to {host}:{port}", "error")
        log_result("Possible issues: Node offline, firewall blocking, wrong IP/port", "warning")
        return False, 0, ["Connection failed"]
    
    log_result("Connection established successfully", "success")
    score += 20
    
    try:
        # RPC functionality test
        log_result("Testing RPC functionality...")
        payload = {"jsonrpc": "2.0", "method": "eth_chainId", "params": [], "id": 1}
        response = requests.post(url, json=payload, timeout=15)
        
        if response.status_code == 200:
            result = response.json()
            if "result" in result:
                chain_id = int(result["result"], 16)
                if chain_id == 11155111:
                    log_result("✓ Confirmed Sepolia testnet (Chain ID: 11155111)", "success")
                    score += 25
                else:
                    log_result(f"Unexpected chain ID: {chain_id} (expected: 11155111)", "warning")
                    score += 15
                    issues.append(f"Wrong chain ID: {chain_id}")
            else:
                log_result("Invalid RPC response format", "error")
                issues.append("Invalid RPC response")
        else:
            log_result(f"RPC request failed (HTTP {response.status_code})", "error")
            issues.append("RPC request failed")
            return False, score, issues
        
        # Sync status check
        log_result("Checking synchronization status...")
        payload = {"jsonrpc": "2.0", "method": "eth_syncing", "params": [], "id": 1}
        response = requests.post(url, json=payload, timeout=15)
        
        if response.status_code == 200:
            result = response.json()
            if "result" in result:
                sync_result = result["result"]
                if sync_result is False:
                    log_result("✓ Node is FULLY SYNCED", "success")
                    score += 30
                else:
                    log_result("✗ Node is SYNCING - not ready for validator", "error")
                    issues.append("Node still syncing")
                    return False, score, issues
        
        # Latest block check
        log_result("Checking latest block information...")
        payload = {"jsonrpc": "2.0", "method": "eth_blockNumber", "params": [], "id": 1}
        response = requests.post(url, json=payload, timeout=15)
        
        if response.status_code == 200:
            result = response.json()
            if "result" in result:
                latest_block = int(result["result"], 16)
                log_result(f"Latest block: {latest_block:,}", "success")
                score += 15
                
                # Check if block number seems reasonable
                if latest_block > 1000000:
                    log_result("Block height appears current", "success")
                else:
                    log_result("Block height seems low - node may be syncing", "warning")
                    issues.append("Low block height")
        
        # Response speed test
        log_result("Testing RPC response speed...")
        start_time = time.time()
        payload = {"jsonrpc": "2.0", "method": "eth_blockNumber", "params": [], "id": 1}
        response = requests.post(url, json=payload, timeout=15)
        response_time = (time.time() - start_time) * 1000
        
        if response_time < 200:
            log_result(f"Excellent response time: {response_time:.0f}ms", "success")
            score += 10
        elif response_time < 500:
            log_result(f"Good response time: {response_time:.0f}ms", "success")
            score += 7
        elif response_time < 1500:
            log_result(f"Acceptable response time: {response_time:.0f}ms", "warning")
            score += 4
            issues.append("Slow RPC response")
        else:
            log_result(f"Slow response time: {response_time:.0f}ms", "error")
            issues.append("Very slow RPC response")
        
        return True, score, issues
        
    except Exception as e:
        log_result(f"Error during Sepolia checks: {str(e)}", "error")
        return False, score, issues + [f"Check error: {str(e)}"]

def print_validator_assessment(beacon_ok, beacon_score, beacon_issues, sepolia_ok, sepolia_score, sepolia_issues):
    """Print comprehensive validator readiness assessment"""
    print_blue("\n🎯 VALIDATOR READINESS ASSESSMENT")
    print_blue("="*65)
    
    overall_score = (beacon_score + sepolia_score) / 2
    all_issues = beacon_issues + sepolia_issues
    
    print()
    print_cyan("📊 DETAILED SCORES:")
    print(f"   Beacon Chain:  {beacon_score}/100")
    print(f"   Sepolia RPC:   {sepolia_score}/100")
    print(f"   Overall Score: {overall_score:.0f}/100")
    print()
    
    # Validator readiness determination
    if beacon_ok and sepolia_ok and overall_score >= 90:
        print_green("🟢 EXCELLENT - FULLY READY FOR VALIDATOR")
        print_green("   ✅ Your nodes are highly reliable for validator operations")
        print_green("   ✅ Very low risk of missed attestations")
        print_green("   ✅ Optimal performance expected")
        validator_ready = True
        
    elif beacon_ok and sepolia_ok and overall_score >= 75:
        print_yellow("🟡 GOOD - SUITABLE FOR VALIDATOR DUTIES")
        print_yellow("   ✅ Your nodes should perform well for validators")
        print_yellow("   ⚠️ Monitor performance and address minor issues")
        validator_ready = True
        
    elif beacon_ok and sepolia_ok and overall_score >= 60:
        print_yellow("🟠 MARGINAL - PROCEED WITH CAUTION")
        print_yellow("   ⚠️ Your nodes may work but with some risks")
        print_yellow("   ⚠️ Address issues before running validator")
        validator_ready = False
        
    else:
        print_red("🔴 NOT READY - DO NOT RUN VALIDATOR")
        print_red("   ❌ Your nodes will likely cause missed attestations")
        print_red("   ❌ Fix critical issues before considering validator duties")
        validator_ready = False
    
    # Issues summary
    if all_issues:
        print()
        print_yellow("⚠️ ISSUES TO ADDRESS:")
        for i, issue in enumerate(set(all_issues), 1):
            print(f"   {i}. {issue}")
    
    # Recommendations
    print()
    print_cyan("💡 VALIDATOR RECOMMENDATIONS:")
    print("   🔧 Critical Requirements:")
    print("      • Both nodes must be fully synced")
    print("      • Maintain stable internet connection")
    print("      • Keep nodes running 24/7")
    print("      • Monitor for any sync issues")
    print()
    print("   📈 Performance Optimization:")
    print("      • Maintain 25+ peers on beacon node")
    print("      • Keep response times under 500ms")
    print("      • Set up monitoring and alerts")
    print("      • Have backup RPC endpoints ready")
    print()
    print("   ⚡ Avoiding Missed Attestations:")
    print("      • Test your setup during low-stakes periods")
    print("      • Monitor validator performance metrics")
    print("      • Ensure redundant network connections")
    print("      • Keep validator software updated")
    
    print_blue("\n" + "="*65)
    
    return validator_ready

def main():
    """Main execution function"""
    try:
        print_header()
        
        # Get RPC URLs from user
        beacon_url, sepolia_url = get_user_rpcs()
        
        print_blue("\n🚀 Starting comprehensive validator readiness assessment...")
        print("   This will test your nodes' ability to handle validator duties")
        
        # Run checks
        beacon_ok, beacon_score, beacon_issues = check_beacon_validator_ready(beacon_url)
        sepolia_ok, sepolia_score, sepolia_issues = check_sepolia_validator_ready(sepolia_url)
        
        # Print assessment
        validator_ready = print_validator_assessment(
            beacon_ok, beacon_score, beacon_issues,
            sepolia_ok, sepolia_score, sepolia_issues
        )
        
        # Final message
        if validator_ready:
            print_green("\n🎉 Your setup looks good for validator operations!")
        else:
            print_red("\n⚠️ Please address the issues above before running a validator.")
        
        # Exit with appropriate code
        sys.exit(0 if validator_ready else 1)
        
    except KeyboardInterrupt:
        print_yellow("\n\n⚠️ Assessment cancelled by user")
        sys.exit(1)
    except Exception as e:
        print_red(f"\n❌ Unexpected error: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main()
EOF

echo "🔍 Starting interactive validator readiness checker..."
echo ""

# Run the checker
python3 "$TEMP_FILE"
exit_code=$?

# Clean up
rm -f "$TEMP_FILE"

exit $exit_code
