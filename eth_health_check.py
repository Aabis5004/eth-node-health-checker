#!/usr/bin/env python3
"""
Simple Ethereum Node Health Checker
Just run this script and enter your RPC URLs when prompted
"""

import requests
import socket
import sys
from datetime import datetime

# Simple color support (works without colorama)
class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    CYAN = '\033[0;36m'
    WHITE = '\033[0;37m'
    BOLD = '\033[1m'
    END = '\033[0m'

def print_colored(message, color=Colors.WHITE):
    """Print colored message"""
    print(f"{color}{message}{Colors.END}")

def print_header():
    """Print welcome header"""
    print_colored("\n" + "="*60, Colors.BLUE)
    print_colored("🚀 ETHEREUM NODE HEALTH CHECKER", Colors.CYAN + Colors.BOLD)
    print_colored("Enter your node URLs and get instant health status", Colors.WHITE)
    print_colored("="*60, Colors.BLUE)

def get_user_input():
    """Get RPC URLs from user"""
    print_colored("\n📝 Please enter your node information:", Colors.YELLOW + Colors.BOLD)
    print()
    
    # Get Beacon Chain URL
    print_colored("🔗 Beacon Chain Node:", Colors.CYAN)
    print("   Examples: http://localhost:5052, http://192.168.1.100:5052")
    beacon_url = input("   Enter Beacon URL: ").strip()
    
    # Default to localhost if empty
    if not beacon_url:
        beacon_url = "http://localhost:5052"
        print_colored(f"   Using default: {beacon_url}", Colors.YELLOW)
    
    print()
    
    # Get Sepolia RPC URL  
    print_colored("🔗 Sepolia RPC Node:", Colors.CYAN)
    print("   Examples: http://localhost:8545, http://192.168.1.100:8545")
    sepolia_url = input("   Enter Sepolia URL: ").strip()
    
    # Default to localhost if empty
    if not sepolia_url:
        sepolia_url = "http://localhost:8545"
        print_colored(f"   Using default: {sepolia_url}", Colors.YELLOW)
    
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
    """Parse URL to get host and port"""
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

def check_beacon_node(url):
    """Check Beacon Chain node health"""
    print_colored("\n🔍 CHECKING BEACON CHAIN NODE", Colors.YELLOW + Colors.BOLD)
    print_colored("-" * 35, Colors.YELLOW)
    
    # Parse URL
    host, port = parse_url(url)
    if not host:
        print_colored("❌ Invalid URL format", Colors.RED)
        return False
    
    # Test connection
    timestamp = datetime.now().strftime("%H:%M:%S")
    print(f"[{timestamp}] Testing connection to {host}:{port}...")
    
    if not test_port(host, port):
        print_colored(f"❌ Cannot connect to {host}:{port}", Colors.RED)
        print_colored("   Possible issues:", Colors.YELLOW)
        print("   • Beacon node is not running")
        print("   • Port 5052 is blocked by firewall")
        print("   • Wrong IP address or port")
        return False
    
    print_colored(f"✅ Port {port} is accessible", Colors.GREEN)
    
    # Test Beacon API
    try:
        print(f"[{datetime.now().strftime('%H:%M:%S')}] Checking beacon node health...")
        response = requests.get(f"{url}/eth/v1/node/health", timeout=15)
        
        if response.status_code == 200:
            print_colored("✅ Beacon node is healthy and responding", Colors.GREEN)
            
            # Check sync status
            try:
                sync_response = requests.get(f"{url}/eth/v1/node/syncing", timeout=15)
                if sync_response.status_code == 200:
                    sync_data = sync_response.json()
                    is_syncing = sync_data.get("data", {}).get("is_syncing", True)
                    if not is_syncing:
                        print_colored("✅ Beacon node is fully synced", Colors.GREEN)
                    else:
                        print_colored("⚠️  Beacon node is still syncing (this is normal)", Colors.YELLOW)
            except:
                print_colored("⚠️  Could not check sync status", Colors.YELLOW)
            
            # Check peers
            try:
                peers_response = requests.get(f"{url}/eth/v1/node/peers", timeout=15)
                if peers_response.status_code == 200:
                    peers_data = peers_response.json()
                    peer_count = len(peers_data.get("data", []))
                    if peer_count > 0:
                        print_colored(f"✅ Connected to {peer_count} peers", Colors.GREEN)
                    else:
                        print_colored("⚠️  No peers connected", Colors.YELLOW)
                else:
                    print_colored("⚠️  Could not check peer count", Colors.YELLOW)
            except:
                print_colored("⚠️  Could not check peer count", Colors.YELLOW)
            
            return True
            
        else:
            print_colored(f"❌ Beacon node health check failed (HTTP {response.status_code})", Colors.RED)
            print_colored("   Possible issues:", Colors.YELLOW)
            print("   • Beacon node API is not enabled")
            print("   • Wrong URL or endpoint")
            return False
            
    except requests.exceptions.Timeout:
        print_colored("❌ Request timeout - beacon node is too slow to respond", Colors.RED)
        return False
    except requests.exceptions.ConnectionError:
        print_colored("❌ Connection failed - beacon node API not accessible", Colors.RED)
        return False
    except Exception as e:
        print_colored(f"❌ Error: {str(e)}", Colors.RED)
        return False

def check_sepolia_rpc(url):
    """Check Sepolia RPC node health"""
    print_colored("\n🔍 CHECKING SEPOLIA RPC NODE", Colors.YELLOW + Colors.BOLD)
    print_colored("-" * 32, Colors.YELLOW)
    
    # Parse URL
    host, port = parse_url(url)
    if not host:
        print_colored("❌ Invalid URL format", Colors.RED)
        return False
    
    # Test connection
    timestamp = datetime.now().strftime("%H:%M:%S")
    print(f"[{timestamp}] Testing connection to {host}:{port}...")
    
    if not test_port(host, port):
        print_colored(f"❌ Cannot connect to {host}:{port}", Colors.RED)
        print_colored("   Possible issues:", Colors.YELLOW)
        print("   • Sepolia node is not running")
        print("   • Port 8545 is blocked by firewall") 
        print("   • Wrong IP address or port")
        return False
    
    print_colored(f"✅ Port {port} is accessible", Colors.GREEN)
    
    # Test RPC
    try:
        print(f"[{datetime.now().strftime('%H:%M:%S')}] Checking RPC functionality...")
        
        # Check chain ID
        payload = {"jsonrpc": "2.0", "method": "eth_chainId", "params": [], "id": 1}
        response = requests.post(url, json=payload, timeout=15)
        
        if response.status_code == 200:
            result = response.json()
            if "result" in result:
                chain_id = int(result["result"], 16)
                if chain_id == 11155111:
                    print_colored("✅ Confirmed Sepolia testnet (Chain ID: 11155111)", Colors.GREEN)
                else:
                    print_colored(f"⚠️  Unexpected chain ID: {chain_id}", Colors.YELLOW)
                    print_colored("   Expected: 11155111 (Sepolia)", Colors.YELLOW)
            else:
                print_colored("⚠️  Unexpected RPC response format", Colors.YELLOW)
        else:
            print_colored(f"❌ RPC request failed (HTTP {response.status_code})", Colors.RED)
            return False
        
        # Check latest block
        try:
            payload = {"jsonrpc": "2.0", "method": "eth_blockNumber", "params": [], "id": 1}
            block_response = requests.post(url, json=payload, timeout=15)
            if block_response.status_code == 200:
                block_result = block_response.json()
                if "result" in block_result:
                    latest_block = int(block_result["result"], 16)
                    print_colored(f"✅ Latest block: {latest_block:,}", Colors.GREEN)
                    
                    # Check if blocks are recent (basic sync check)
                    if latest_block > 1000000:  # Reasonable block number for Sepolia
                        print_colored("✅ Node appears to be synced", Colors.GREEN)
                    else:
                        print_colored("⚠️  Block number seems low - node might be syncing", Colors.YELLOW)
        except:
            print_colored("⚠️  Could not check latest block", Colors.YELLOW)
        
        # Check peer count
        try:
            payload = {"jsonrpc": "2.0", "method": "net_peerCount", "params": [], "id": 1}
            peers_response = requests.post(url, json=payload, timeout=15)
            if peers_response.status_code == 200:
                peers_result = peers_response.json()
                if "result" in peers_result:
                    peer_count = int(peers_result["result"], 16)
                    if peer_count > 0:
                        print_colored(f"✅ Connected to {peer_count} peers", Colors.GREEN)
                    else:
                        print_colored("⚠️  No peers connected", Colors.YELLOW)
        except:
            print_colored("⚠️  Could not check peer count", Colors.YELLOW)
        
        return True
        
    except requests.exceptions.Timeout:
        print_colored("❌ Request timeout - RPC node is too slow to respond", Colors.RED)
        return False
    except requests.exceptions.ConnectionError:
        print_colored("❌ Connection failed - RPC not accessible", Colors.RED)
        return False
    except Exception as e:
        print_colored(f"❌ Error: {str(e)}", Colors.RED)
        return False

def print_summary(beacon_ok, sepolia_ok):
    """Print final summary"""
    print_colored("\n📊 FINAL HEALTH SUMMARY", Colors.BLUE + Colors.BOLD)
    print_colored("="*50, Colors.BLUE)
    
    # Overall status
    if beacon_ok and sepolia_ok:
        print_colored("🎉 ALL SYSTEMS HEALTHY!", Colors.GREEN + Colors.BOLD)
        print_colored("   ✅ Beacon Chain: Working perfectly", Colors.GREEN)
        print_colored("   ✅ Sepolia RPC: Working perfectly", Colors.GREEN)
        print()
        print_colored("Your nodes are ready for use! 🚀", Colors.GREEN)
        
    elif beacon_ok or sepolia_ok:
        print_colored("⚠️  PARTIAL SUCCESS", Colors.YELLOW + Colors.BOLD)
        if beacon_ok:
            print_colored("   ✅ Beacon Chain: Working", Colors.GREEN)
        else:
            print_colored("   ❌ Beacon Chain: Issues detected", Colors.RED)
        
        if sepolia_ok:
            print_colored("   ✅ Sepolia RPC: Working", Colors.GREEN)
        else:
            print_colored("   ❌ Sepolia RPC: Issues detected", Colors.RED)
        
        print()
        print_colored("Some nodes need attention. Check the details above.", Colors.YELLOW)
        
    else:
        print_colored("❌ ISSUES DETECTED", Colors.RED + Colors.BOLD)
        print_colored("   ❌ Beacon Chain: Not working", Colors.RED)
        print_colored("   ❌ Sepolia RPC: Not working", Colors.RED)
        print()
        print_colored("Both nodes need attention. Check the troubleshooting tips above.", Colors.RED)
    
    print_colored("="*50, Colors.BLUE)

def print_troubleshooting():
    """Print troubleshooting tips"""
    print_colored("\n🔧 COMMON TROUBLESHOOTING TIPS", Colors.YELLOW + Colors.BOLD)
    print_colored("-" * 35, Colors.YELLOW)
    print()
    print_colored("If nodes are not working:", Colors.WHITE)
    print("1. Check if services are running:")
    print("   sudo systemctl status beacon-node")
    print("   sudo systemctl status geth")
    print()
    print("2. Check if ports are open:")
    print("   sudo ufw allow 5052  # Beacon")
    print("   sudo ufw allow 8545  # Sepolia")
    print()
    print("3. Check node configuration allows external access:")
    print("   Beacon: --http-address 0.0.0.0")
    print("   Geth: --http.addr 0.0.0.0")
    print()
    print("4. Check logs for errors:")
    print("   journalctl -u beacon-node -f")
    print("   journalctl -u geth -f")

def main():
    """Main function"""
    try:
        # Print header
        print_header()
        
        # Get user input
        beacon_url, sepolia_url = get_user_input()
        
        # Start health checks
        print_colored("\n🚀 Starting health checks...", Colors.BLUE + Colors.BOLD)
        
        # Check both nodes
        beacon_ok = check_beacon_node(beacon_url)
        sepolia_ok = check_sepolia_rpc(sepolia_url)
        
        # Print summary
        print_summary(beacon_ok, sepolia_ok)
        
        # Print troubleshooting if there are issues
        if not beacon_ok or not sepolia_ok:
            print_troubleshooting()
        
        # Exit with appropriate code
        if beacon_ok and sepolia_ok:
            sys.exit(0)
        else:
            sys.exit(1)
            
    except KeyboardInterrupt:
        print_colored("\n\n⚠️  Health check cancelled by user", Colors.YELLOW)
        sys.exit(1)
    except Exception as e:
        print_colored(f"\n❌ Unexpected error: {str(e)}", Colors.RED)
        sys.exit(1)

if __name__ == "__main__":
    main()
