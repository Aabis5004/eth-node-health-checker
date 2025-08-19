#!/usr/bin/env python3
"""
Ethereum Validator Node Readiness Checker
Checks if your Beacon Chain and Sepolia nodes are ready for validator duties
Minimal dependencies - only uses Python standard library + requests
"""

import json
import socket
import sys
import time
import urllib.request
import urllib.parse
import urllib.error
from datetime import datetime

# Simple color codes (no external dependencies)
class Color:
    RED = '\033[91m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    WHITE = '\033[97m'
    BOLD = '\033[1m'
    END = '\033[0m'

def print_colored(text, color=Color.WHITE):
    """Print colored text"""
    print(f"{color}{text}{Color.END}")

def print_header():
    """Print application header"""
    print_colored("\n" + "="*65, Color.BLUE)
    print_colored("🔥 ETHEREUM VALIDATOR READINESS CHECKER", Color.CYAN + Color.BOLD)
    print_colored("Check if your nodes are ready for validator duties", Color.WHITE)
    print_colored("="*65, Color.BLUE)

def get_user_input():
    """Get RPC URLs from user with examples"""
    print_colored("\n📝 Enter your node URLs:", Color.YELLOW + Color.BOLD)
    print()
    
    print_colored("🔗 Beacon Chain Node URL:", Color.CYAN)
    print("   Examples:")
    print("   • http://localhost:5052")
    print("   • http://192.168.1.100:5052") 
    print("   • https://beacon-node.yourdomain.com")
    beacon_url = input("   Enter Beacon URL: ").strip()
    
    if not beacon_url:
        beacon_url = "http://localhost:5052"
        print_colored(f"   → Using default: {beacon_url}", Color.YELLOW)
    
    print()
    print_colored("🔗 Sepolia RPC Node URL:", Color.CYAN)
    print("   Examples:")
    print("   • http://localhost:8545")
    print("   • http://192.168.1.100:8545")
    print("   • https://sepolia-rpc.yourdomain.com")
    sepolia_url = input("   Enter Sepolia URL: ").strip()
    
    if not sepolia_url:
        sepolia_url = "http://localhost:8545"
        print_colored(f"   → Using default: {sepolia_url}", Color.YELLOW)
    
    return beacon_url, sepolia_url

def test_connection(host, port, timeout=5):
    """Test TCP connection"""
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
            parts = url.split("://", 1)
            protocol = parts[0]
            rest = parts[1]
            
            if ":" in rest and "/" not in rest.split(":")[-1]:
                host, port = rest.rsplit(":", 1)
                port = int(port)
            else:
                host = rest.split("/")[0]
                port = 443 if protocol == "https" else (5052 if "5052" in url else 8545)
        else:
            if ":" in url:
                host, port = url.rsplit(":", 1)
                port = int(port)
            else:
                host = url
                port = 5052 if "5052" in url else 8545
        return host, port
    except:
        return None, None

def http_request(url, data=None, timeout=10):
    """Make HTTP request using urllib (no external dependencies)"""
    try:
        if data:
            data = json.dumps(data).encode('utf-8')
            req = urllib.request.Request(url, data=data, headers={'Content-Type': 'application/json'})
        else:
            req = urllib.request.Request(url)
        
        with urllib.request.urlopen(req, timeout=timeout) as response:
            return response.getcode(), json.loads(response.read().decode('utf-8'))
    except urllib.error.HTTPError as e:
        return e.code, None
    except Exception:
        return None, None

def check_beacon_validator_readiness(url):
    """Check if Beacon node is ready for validator duties"""
    print_colored("\n🔍 CHECKING BEACON CHAIN - VALIDATOR READINESS", Color.YELLOW + Color.BOLD)
    print_colored("-" * 50, Color.YELLOW)
    
    host, port = parse_url(url)
    if not host:
        print_colored("❌ Invalid Beacon URL format", Color.RED)
        return {"ready": False, "score": 0}
    
    results = {"ready": False, "score": 0, "issues": []}
    
    # Test 1: Connection
    print(f"[{datetime.now().strftime('%H:%M:%S')}] Testing connection to {host}:{port}...")
    if not test_connection(host, port):
        print_colored(f"❌ Cannot connect to {host}:{port}", Color.RED)
        results["issues"].append("Connection failed")
        return results
    
    print_colored(f"✅ Connection successful", Color.GREEN)
    results["score"] += 20
    
    # Test 2: Node Health
    print(f"[{datetime.now().strftime('%H:%M:%S')}] Checking node health...")
    status_code, _ = http_request(f"{url}/eth/v1/node/health")
    if status_code == 200:
        print_colored("✅ Node is healthy", Color.GREEN)
        results["score"] += 25
    else:
        print_colored("❌ Node health check failed", Color.RED)
        results["issues"].append("Node unhealthy")
        return results
    
    # Test 3: Sync Status (Critical for validators)
    print(f"[{datetime.now().strftime('%H:%M:%S')}] Checking sync status...")
    status_code, sync_data = http_request(f"{url}/eth/v1/node/syncing")
    if status_code == 200 and sync_data:
        is_syncing = sync_data.get("data", {}).get("is_syncing", True)
        if not is_syncing:
            print_colored("✅ Node is fully synced - READY FOR VALIDATOR", Color.GREEN)
            results["score"] += 30
        else:
            print_colored("❌ Node is still syncing - NOT READY FOR VALIDATOR", Color.RED)
            results["issues"].append("Still syncing")
            return results
    else:
        print_colored("⚠️  Could not verify sync status", Color.YELLOW)
        results["issues"].append("Sync status unknown")
    
    # Test 4: Peer Count (Important for attestations)
    print(f"[{datetime.now().strftime('%H:%M:%S')}] Checking peer connections...")
    status_code, peers_data = http_request(f"{url}/eth/v1/node/peers")
    if status_code == 200 and peers_data:
        peer_count = len(peers_data.get("data", []))
        if peer_count >= 50:
            print_colored(f"✅ Excellent peer count: {peer_count} (optimal for validators)", Color.GREEN)
            results["score"] += 15
        elif peer_count >= 20:
            print_colored(f"✅ Good peer count: {peer_count} (sufficient for validators)", Color.GREEN)
            results["score"] += 10
        elif peer_count >= 5:
            print_colored(f"⚠️  Low peer count: {peer_count} (risky for validators)", Color.YELLOW)
            results["score"] += 5
            results["issues"].append("Low peer count")
        else:
            print_colored(f"❌ Very low peer count: {peer_count} (dangerous for validators)", Color.RED)
            results["issues"].append("Critical: Very low peers")
    
    # Test 5: Response Time (Critical for attestations)
    print(f"[{datetime.now().strftime('%H:%M:%S')}] Testing response time...")
    start_time = time.time()
    status_code, _ = http_request(f"{url}/eth/v1/beacon/headers/head")
    response_time = (time.time() - start_time) * 1000
    
    if response_time < 500:
        print_colored(f"✅ Excellent response time: {response_time:.0f}ms", Color.GREEN)
        results["score"] += 10
    elif response_time < 1000:
        print_colored(f"✅ Good response time: {response_time:.0f}ms", Color.GREEN)
        results["score"] += 5
    elif response_time < 2000:
        print_colored(f"⚠️  Slow response time: {response_time:.0f}ms", Color.YELLOW)
        results["issues"].append("Slow response")
    else:
        print_colored(f"❌ Very slow response: {response_time:.0f}ms (risk of missed attestations)", Color.RED)
        results["issues"].append("Critical: Very slow response")
    
    results["ready"] = results["score"] >= 85
    return results

def check_sepolia_validator_readiness(url):
    """Check if Sepolia RPC is ready for validator duties"""
    print_colored("\n🔍 CHECKING SEPOLIA RPC - VALIDATOR READINESS", Color.YELLOW + Color.BOLD)
    print_colored("-" * 47, Color.YELLOW)
    
    host, port = parse_url(url)
    if not host:
        print_colored("❌ Invalid Sepolia URL format", Color.RED)
        return {"ready": False, "score": 0}
    
    results = {"ready": False, "score": 0, "issues": []}
    
    # Test 1: Connection
    print(f"[{datetime.now().strftime('%H:%M:%S')}] Testing connection to {host}:{port}...")
    if not test_connection(host, port):
        print_colored(f"❌ Cannot connect to {host}:{port}", Color.RED)
        results["issues"].append("Connection failed")
        return results
    
    print_colored(f"✅ Connection successful", Color.GREEN)
    results["score"] += 20
    
    # Test 2: RPC Functionality
    print(f"[{datetime.now().strftime('%H:%M:%S')}] Testing RPC functionality...")
    payload = {"jsonrpc": "2.0", "method": "eth_chainId", "params": [], "id": 1}
    status_code, response = http_request(url, payload)
    
    if status_code == 200 and response and "result" in response:
        chain_id = int(response["result"], 16)
        if chain_id == 11155111:
            print_colored("✅ Confirmed Sepolia testnet", Color.GREEN)
            results["score"] += 25
        else:
            print_colored(f"⚠️  Unexpected chain ID: {chain_id}", Color.YELLOW)
            results["score"] += 10
    else:
        print_colored("❌ RPC not responding correctly", Color.RED)
        results["issues"].append("RPC failed")
        return results
    
    # Test 3: Sync Status
    print(f"[{datetime.now().strftime('%H:%M:%S')}] Checking sync status...")
    payload = {"jsonrpc": "2.0", "method": "eth_syncing", "params": [], "id": 1}
    status_code, response = http_request(url, payload)
    
    if status_code == 200 and response and "result" in response:
        sync_result = response["result"]
        if sync_result is False:
            print_colored("✅ Node is fully synced", Color.GREEN)
            results["score"] += 30
        else:
            print_colored("❌ Node is syncing - not ready for validator", Color.RED)
            results["issues"].append("Still syncing")
            return results
    
    # Test 4: Latest Block Check
    print(f"[{datetime.now().strftime('%H:%M:%S')}] Checking latest block...")
    payload = {"jsonrpc": "2.0", "method": "eth_blockNumber", "params": [], "id": 1}
    status_code, response = http_request(url, payload)
    
    if status_code == 200 and response and "result" in response:
        latest_block = int(response["result"], 16)
        print_colored(f"✅ Latest block: {latest_block:,}", Color.GREEN)
        results["score"] += 15
    
    # Test 5: Response Time Test
    print(f"[{datetime.now().strftime('%H:%M:%S')}] Testing response speed...")
    start_time = time.time()
    payload = {"jsonrpc": "2.0", "method": "eth_blockNumber", "params": [], "id": 1}
    status_code, response = http_request(url, payload)
    response_time = (time.time() - start_time) * 1000
    
    if response_time < 300:
        print_colored(f"✅ Excellent response time: {response_time:.0f}ms", Color.GREEN)
        results["score"] += 10
    elif response_time < 1000:
        print_colored(f"✅ Good response time: {response_time:.0f}ms", Color.GREEN)
        results["score"] += 5
    else:
        print_colored(f"⚠️  Slow response: {response_time:.0f}ms", Color.YELLOW)
        results["issues"].append("Slow RPC response")
    
    results["ready"] = results["score"] >= 85
    return results

def print_validator_assessment(beacon_results, sepolia_results):
    """Print final validator readiness assessment"""
    print_colored("\n🎯 VALIDATOR READINESS ASSESSMENT", Color.BLUE + Color.BOLD)
    print_colored("="*60, Color.BLUE)
    
    beacon_score = beacon_results.get("score", 0)
    sepolia_score = sepolia_results.get("score", 0)
    overall_score = (beacon_score + sepolia_score) / 2
    
    print()
    print_colored("📊 READINESS SCORES:", Color.CYAN + Color.BOLD)
    print(f"   Beacon Chain: {beacon_score}/100")
    print(f"   Sepolia RPC:  {sepolia_score}/100")
    print(f"   Overall:      {overall_score:.0f}/100")
    print()
    
    # Overall Assessment
    if overall_score >= 90:
        print_colored("🟢 EXCELLENT - READY FOR VALIDATOR DUTIES", Color.GREEN + Color.BOLD)
        print_colored("   Your nodes are highly reliable for validator operations", Color.GREEN)
        print_colored("   ✅ Low risk of missed attestations", Color.GREEN)
        print_colored("   ✅ Excellent performance for validator rewards", Color.GREEN)
        
    elif overall_score >= 75:
        print_colored("🟡 GOOD - SUITABLE FOR VALIDATOR WITH MINOR RISKS", Color.YELLOW + Color.BOLD)
        print_colored("   Your nodes should work well for validators", Color.YELLOW)
        print_colored("   ⚠️  Monitor performance closely", Color.YELLOW)
        
    elif overall_score >= 60:
        print_colored("🟠 MARGINAL - HIGH RISK FOR VALIDATOR", Color.YELLOW + Color.BOLD)
        print_colored("   Your nodes may cause missed attestations", Color.YELLOW)
        print_colored("   ⚠️  Fix issues before running validator", Color.YELLOW)
        
    else:
        print_colored("🔴 NOT READY - DO NOT RUN VALIDATOR", Color.RED + Color.BOLD)
        print_colored("   Your nodes will likely cause significant penalties", Color.RED)
        print_colored("   ❌ Fix all issues before considering validator duties", Color.RED)
    
    print()
    
    # Specific Issues
    all_issues = beacon_results.get("issues", []) + sepolia_results.get("issues", [])
    if all_issues:
        print_colored("⚠️  ISSUES TO FIX:", Color.YELLOW + Color.BOLD)
        for issue in all_issues:
            print(f"   • {issue}")
        print()
    
    # Validator-specific recommendations
    print_colored("💡 VALIDATOR RECOMMENDATIONS:", Color.CYAN + Color.BOLD)
    
    if beacon_score < 85:
        print("   🔧 Beacon Chain:")
        print("      • Ensure node is fully synced before running validator")
        print("      • Maintain at least 20+ peers (50+ recommended)")
        print("      • Monitor response times < 500ms")
        print("      • Set up monitoring and alerts")
    
    if sepolia_score < 85:
        print("   🔧 Sepolia RPC:")
        print("      • Ensure RPC is fully synced")
        print("      • Optimize RPC response times")
        print("      • Consider using backup RPC endpoints")
    
    print("   📈 General:")
    print("      • Set up redundant connections")
    print("      • Monitor both nodes 24/7")
    print("      • Have backup plans for emergencies")
    print("      • Test during low-stakes periods first")
    
    print_colored("\n" + "="*60, Color.BLUE)
    
    return overall_score >= 75

def main():
    """Main execution function"""
    try:
        print_header()
        
        # Get user input
        beacon_url, sepolia_url = get_user_input()
        
        print_colored("\n🚀 Starting validator readiness assessment...", Color.BLUE + Color.BOLD)
        
        # Run comprehensive checks
        beacon_results = check_beacon_validator_readiness(beacon_url)
        sepolia_results = check_sepolia_validator_readiness(sepolia_url)
        
        # Print assessment
        validator_ready = print_validator_assessment(beacon_results, sepolia_results)
        
        # Exit with appropriate code
        sys.exit(0 if validator_ready else 1)
        
    except KeyboardInterrupt:
        print_colored("\n\n⚠️  Assessment cancelled by user", Color.YELLOW)
        sys.exit(1)
    except Exception as e:
        print_colored(f"\n❌ Unexpected error: {str(e)}", Color.RED)
        sys.exit(1)

if __name__ == "__main__":
    main()
