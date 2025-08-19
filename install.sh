#!/bin/bash

# Simple Ethereum Node Health Checker
echo "🚀 Ethereum Node Health Checker"
echo "================================"

# Check Python
if ! python3 -c "import sys; sys.exit(0)" 2>/dev/null; then
    echo "❌ Python 3 required"
    echo "Install: sudo apt install python3"
    exit 1
fi

# Check requests
if ! python3 -c "import requests" 2>/dev/null; then
    echo "📦 Installing requests..."
    python3 -m pip install --user requests 2>/dev/null || {
        echo "❌ Please install requests: pip3 install requests"
        exit 1
    }
fi

echo "✅ Ready to check your nodes"

# Download and run the health checker
python3 -c '
import requests
import socket
import sys
import time
from datetime import datetime

def print_header():
    print("\n" + "="*60)
    print("🚀 ETHEREUM VALIDATOR NODE HEALTH CHECKER")
    print("Check if your nodes are ready for validator duties")
    print("="*60)

def get_rpc_from_user():
    print("\n📝 Please enter your node RPC endpoints:")
    print()
    
    print("🔗 BEACON CHAIN RPC:")
    print("   Examples:")
    print("   • http://localhost:5052")
    print("   • http://192.168.1.100:5052")
    print("   • https://beacon.yournode.com")
    beacon_rpc = input("\n👉 Enter Beacon RPC URL: ").strip()
    
    if not beacon_rpc:
        beacon_rpc = "http://localhost:5052"
        print(f"   Using default: {beacon_rpc}")
    
    print(f"✅ Beacon RPC: {beacon_rpc}")
    
    print("\n🔗 SEPOLIA RPC:")
    print("   Examples:")
    print("   • http://localhost:8545")
    print("   • http://192.168.1.100:8545")
    print("   • https://sepolia.yournode.com")
    sepolia_rpc = input("\n👉 Enter Sepolia RPC URL: ").strip()
    
    if not sepolia_rpc:
        sepolia_rpc = "http://localhost:8545"
        print(f"   Using default: {sepolia_rpc}")
    
    print(f"✅ Sepolia RPC: {sepolia_rpc}")
    
    return beacon_rpc, sepolia_rpc

def test_connection(url):
    try:
        if "://" in url:
            parts = url.split("://")[1]
        else:
            parts = url
        
        if ":" in parts:
            host = parts.split(":")[0]
            port = int(parts.split(":")[1].split("/")[0])
        else:
            host = parts.split("/")[0]
            port = 80
        
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(5)
        result = sock.connect_ex((host, port))
        sock.close()
        return result == 0
    except:
        return False

def check_beacon_health(rpc_url):
    print("\n🔍 CHECKING BEACON CHAIN NODE")
    print("-" * 35)
    
    score = 0
    issues = []
    
    print(f"⏳ Testing connection to {rpc_url}...")
    if not test_connection(rpc_url):
        print("❌ Cannot connect to Beacon RPC")
        print("   Check: Node running? Firewall? Correct URL?")
        return score, ["Connection failed"]
    
    print("✅ Connection successful")
    score += 20
    
    try:
        print("⏳ Checking node health...")
        response = requests.get(f"{rpc_url}/eth/v1/node/health", timeout=10)
        if response.status_code == 200:
            print("✅ Beacon node is healthy")
            score += 25
        else:
            print(f"❌ Health check failed (HTTP {response.status_code})")
            issues.append("Health check failed")
            return score, issues
        
        print("⏳ Checking sync status...")
        response = requests.get(f"{rpc_url}/eth/v1/node/syncing", timeout=10)
        if response.status_code == 200:
            data = response.json()
            is_syncing = data.get("data", {}).get("is_syncing", True)
            if not is_syncing:
                print("✅ Node is FULLY SYNCED - Ready for validator")
                score += 30
            else:
                print("⚠️  Node is SYNCING - Not ready for validator yet")
                issues.append("Still syncing")
                score += 10
        
        print("⏳ Checking peer connections...")
        response = requests.get(f"{rpc_url}/eth/v1/node/peers", timeout=10)
        if response.status_code == 200:
            data = response.json()
            peer_count = len(data.get("data", []))
            if peer_count >= 30:
                print(f"✅ Excellent peers: {peer_count} (great for validators)")
                score += 15
            elif peer_count >= 10:
                print(f"✅ Good peers: {peer_count} (sufficient for validators)")
                score += 10
            elif peer_count >= 3:
                print(f"⚠️  Low peers: {peer_count} (risky for validators)")
                score += 5
                issues.append("Low peer count")
            else:
                print(f"❌ Very few peers: {peer_count} (not suitable)")
                issues.append("Very low peers")
        
        print("⏳ Testing response speed...")
        start = time.time()
        response = requests.get(f"{rpc_url}/eth/v1/beacon/headers/head", timeout=10)
        response_time = (time.time() - start) * 1000
        
        if response_time < 500:
            print(f"✅ Fast response: {response_time:.0f}ms (excellent)")
            score += 10
        elif response_time < 1500:
            print(f"✅ Good response: {response_time:.0f}ms (acceptable)")
            score += 5
        else:
            print(f"⚠️  Slow response: {response_time:.0f}ms (may affect validator)")
            issues.append("Slow response")
        
        print("⏳ Checking blob support...")
        try:
            response = requests.get(f"{rpc_url}/eth/v1/beacon/blob_sidecars/head", timeout=10)
            if response.status_code == 200:
                print("✅ Blob support available")
                score += 5
            elif response.status_code == 404:
                print("✅ Blob endpoint available (no blobs in current block)")
                score += 5
            else:
                print("⚠️  Blob support unclear")
        except:
            print("⚠️  Could not check blob support")
    
    except Exception as e:
        print(f"❌ Error checking beacon: {str(e)}")
        issues.append(f"Check error: {str(e)}")
    
    return score, issues

def check_sepolia_health(rpc_url):
    print("\n🔍 CHECKING SEPOLIA RPC NODE")
    print("-" * 32)
    
    score = 0
    issues = []
    
    print(f"⏳ Testing connection to {rpc_url}...")
    if not test_connection(rpc_url):
        print("❌ Cannot connect to Sepolia RPC")
        print("   Check: Node running? Firewall? Correct URL?")
        return score, ["Connection failed"]
    
    print("✅ Connection successful")
    score += 20
    
    try:
        print("⏳ Testing RPC functionality...")
        payload = {"jsonrpc": "2.0", "method": "eth_chainId", "params": [], "id": 1}
        response = requests.post(rpc_url, json=payload, timeout=10)
        
        if response.status_code == 200:
            data = response.json()
            if "result" in data:
                chain_id = int(data["result"], 16)
                if chain_id == 11155111:
                    print("✅ Confirmed Sepolia testnet")
                    score += 25
                else:
                    print(f"⚠️  Chain ID: {chain_id} (expected 11155111 for Sepolia)")
                    score += 15
                    issues.append(f"Wrong chain: {chain_id}")
        else:
            print("❌ RPC call failed")
            issues.append("RPC failed")
            return score, issues
        
        print("⏳ Checking sync status...")
        payload = {"jsonrpc": "2.0", "method": "eth_syncing", "params": [], "id": 1}
        response = requests.post(rpc_url, json=payload, timeout=10)
        
        if response.status_code == 200:
            data = response.json()
            if "result" in data:
                sync_result = data["result"]
                if sync_result is False:
                    print("✅ Node is FULLY SYNCED")
                    score += 30
                else:
                    print("⚠️  Node is SYNCING - Not ready for validator")
                    issues.append("Still syncing")
                    score += 10
        
        print("⏳ Checking latest block...")
        payload = {"jsonrpc": "2.0", "method": "eth_blockNumber", "params": [], "id": 1}
        response = requests.post(rpc_url, json=payload, timeout=10)
        
        if response.status_code == 200:
            data = response.json()
            if "result" in data:
                block_num = int(data["result"], 16)
                print(f"✅ Latest block: {block_num:,}")
                score += 15
        
        print("⏳ Testing response speed...")
        start = time.time()
        payload = {"jsonrpc": "2.0", "method": "eth_blockNumber", "params": [], "id": 1}
        response = requests.post(rpc_url, json=payload, timeout=10)
        response_time = (time.time() - start) * 1000
        
        if response_time < 300:
            print(f"✅ Fast response: {response_time:.0f}ms (excellent)")
            score += 10
        elif response_time < 1000:
            print(f"✅ Good response: {response_time:.0f}ms (acceptable)")
            score += 5
        else:
            print(f"⚠️  Slow response: {response_time:.0f}ms")
            issues.append("Slow response")
    
    except Exception as e:
        print(f"❌ Error checking Sepolia: {str(e)}")
        issues.append(f"Check error: {str(e)}")
    
    return score, issues

def print_final_assessment(beacon_score, beacon_issues, sepolia_score, sepolia_issues):
    print("\n🎯 VALIDATOR READINESS ASSESSMENT")
    print("="*50)
    
    total_score = (beacon_score + sepolia_score) / 2
    all_issues = beacon_issues + sepolia_issues
    
    print(f"\n📊 SCORES:")
    print(f"   Beacon Chain: {beacon_score}/100")
    print(f"   Sepolia RPC:  {sepolia_score}/100")
    print(f"   Overall:      {total_score:.0f}/100")
    
    print(f"\n🎯 VALIDATOR READINESS:")
    if total_score >= 85 and len(all_issues) == 0:
        print("🟢 EXCELLENT - READY FOR VALIDATOR")
        print("   ✅ Your nodes are ready for validator duties")
        print("   ✅ Low risk of missed attestations")
        ready = True
    elif total_score >= 70 and "Still syncing" not in str(all_issues):
        print("🟡 GOOD - SUITABLE FOR VALIDATOR")
        print("   ✅ Your nodes should work for validators")
        print("   ⚠️  Monitor performance")
        ready = True
    elif total_score >= 50:
        print("🟠 MARGINAL - RISKY FOR VALIDATOR")
        print("   ⚠️  Your nodes may cause issues")
        print("   ⚠️  Fix problems before running validator")
        ready = False
    else:
        print("🔴 NOT READY - DO NOT RUN VALIDATOR")
        print("   ❌ Your nodes will likely cause missed attestations")
        print("   ❌ Fix all issues first")
        ready = False
    
    if all_issues:
        print(f"\n⚠️  ISSUES TO FIX:")
        for i, issue in enumerate(set(all_issues), 1):
            print(f"   {i}. {issue}")
    
    print(f"\n💡 RECOMMENDATIONS:")
    print("   • Ensure both nodes are fully synced")
    print("   • Maintain good internet connection")
    print("   • Keep response times under 1 second")
    print("   • Monitor node health regularly")
    print("   • Have backup RPC endpoints ready")
    
    print("="*50)
    return ready

def main():
    try:
        print_header()
        beacon_rpc, sepolia_rpc = get_rpc_from_user()
        
        print("\n🚀 Starting health check...")
        print("   Testing your nodes for validator readiness...")
        
        beacon_score, beacon_issues = check_beacon_health(beacon_rpc)
        sepolia_score, sepolia_issues = check_sepolia_health(sepolia_rpc)
        
        ready = print_final_assessment(beacon_score, beacon_issues, sepolia_score, sepolia_issues)
        
        if ready:
            print("\n🎉 Your nodes look good for validator operations!")
        else:
            print("\n⚠️  Please fix the issues before running a validator.")
        
        sys.exit(0 if ready else 1)
        
    except KeyboardInterrupt:
        print("\n\n⚠️  Health check cancelled")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Error: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main()
'
