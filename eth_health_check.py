#!/usr/bin/env python3
"""
Ethereum Node Health Checker - Professional monitoring tool
Checks Beacon Chain and Sepolia RPC node health, connectivity, and status
"""

import requests
import json
import socket
import sys
import argparse
import time
from datetime import datetime

try:
    from colorama import init, Fore, Style
    init()
    HAS_COLOR = True
except ImportError:
    HAS_COLOR = False

try:
    from tabulate import tabulate
    HAS_TABULATE = True
except ImportError:
    HAS_TABULATE = False

class NodeHealthChecker:
    def __init__(self, timeout=15):
        self.timeout = timeout
        self.results = {}
        
    def colored_print(self, message, color="white", style="normal"):
        """Print colored text if colorama is available"""
        if not HAS_COLOR:
            print(message)
            return
            
        colors = {
            "red": Fore.RED,
            "green": Fore.GREEN, 
            "yellow": Fore.YELLOW,
            "blue": Fore.BLUE,
            "cyan": Fore.CYAN,
            "white": Fore.WHITE
        }
        
        styles = {
            "bright": Style.BRIGHT,
            "normal": Style.NORMAL
        }
        
        color_code = colors.get(color, Fore.WHITE)
        style_code = styles.get(style, Style.NORMAL)
        print(f"{style_code}{color_code}{message}{Style.RESET_ALL}")
    
    def print_header(self):
        """Print the application header"""
        self.colored_print("\n" + "="*70, "blue", "bright")
        self.colored_print("🚀 ETHEREUM NODE HEALTH CHECKER", "cyan", "bright")
        self.colored_print("Professional monitoring for your Ethereum infrastructure", "white")
        self.colored_print("="*70, "blue", "bright")
    
    def print_section(self, title):
        """Print a section header"""
        self.colored_print(f"\n📋 {title}", "yellow", "bright")
        self.colored_print("-" * (len(title) + 4), "yellow")
    
    def log_result(self, message, status="info"):
        """Log a result with timestamp and status icon"""
        timestamp = datetime.now().strftime("%H:%M:%S")
        
        status_map = {
            "success": ("green", "✅"),
            "error": ("red", "❌"), 
            "warning": ("yellow", "⚠️"),
            "info": ("blue", "ℹ️")
        }
        
        color, icon = status_map.get(status, ("white", "•"))
        self.colored_print(f"[{timestamp}] {icon} {message}", color)
    
    def test_connection(self, host, port):
        """Test if a TCP port is accessible"""
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(self.timeout)
            result = sock.connect_ex((host, port))
            sock.close()
            return result == 0
        except Exception:
            return False
    
    def parse_url(self, url, default_port):
        """Parse URL to extract host and port"""
        try:
            if "://" in url:
                protocol, rest = url.split("://", 1)
                if ":" in rest:
                    host, port_part = rest.split(":", 1)
                    port = int(port_part.split("/")[0])
                else:
                    host = rest.split("/")[0]
                    port = 443 if protocol == "https" else default_port
            else:
                if ":" in url:
                    host, port = url.split(":")
                    port = int(port)
                else:
                    host = url
                    port = default_port
            return host, port
        except Exception:
            return None, None
    
    def check_beacon_node(self, url):
        """Check Beacon node comprehensive health"""
        self.print_section("BEACON CHAIN NODE")
        
        host, port = self.parse_url(url, 5052)
        if not host:
            self.log_result(f"Invalid Beacon URL format: {url}", "error")
            return {"reachable": False, "healthy": False, "synced": False, "peers": 0}
        
        beacon_results = {
            "reachable": False,
            "healthy": False, 
            "synced": False,
            "peers": 0,
            "version": "Unknown"
        }
        
        # Test port connectivity
        if not self.test_connection(host, port):
            self.log_result(f"Cannot connect to {host}:{port}", "error")
            self.log_result("Check: Is your beacon node running? Firewall open?", "warning")
            return beacon_results
        
        self.log_result(f"Port {port} is open on {host}", "success")
        beacon_results["reachable"] = True
        
        try:
            # Check node health
            response = requests.get(f"{url}/eth/v1/node/health", timeout=self.timeout)
            if response.status_code == 200:
                beacon_results["healthy"] = True
                self.log_result("Beacon node is responding and healthy", "success")
            else:
                self.log_result(f"Beacon node health check failed (HTTP {response.status_code})", "error")
        except Exception as e:
            self.log_result(f"Failed to check beacon health: {str(e)}", "error")
        
        try:
            # Check sync status
            response = requests.get(f"{url}/eth/v1/node/syncing", timeout=self.timeout)
            if response.status_code == 200:
                sync_data = response.json()
                is_syncing = sync_data.get("data", {}).get("is_syncing", True)
                if not is_syncing:
                    beacon_results["synced"] = True
                    self.log_result("Beacon node is fully synced", "success")
                else:
                    self.log_result("Beacon node is still syncing (this is normal)", "warning")
            
            # Check peer count
            response = requests.get(f"{url}/eth/v1/node/peers", timeout=self.timeout)
            if response.status_code == 200:
                peers_data = response.json()
                peer_count = len(peers_data.get("data", []))
                beacon_results["peers"] = peer_count
                if peer_count > 0:
                    self.log_result(f"Connected to {peer_count} peers", "success")
                else:
                    self.log_result("No peers connected (check network connectivity)", "warning")
            
            # Check version
            response = requests.get(f"{url}/eth/v1/node/version", timeout=self.timeout)
            if response.status_code == 200:
                version_data = response.json()
                version = version_data.get("data", {}).get("version", "Unknown")
                beacon_results["version"] = version
                self.log_result(f"Node version: {version}", "info")
                
        except Exception as e:
            self.log_result(f"Error checking beacon details: {str(e)}", "error")
        
        return beacon_results
    
    def check_sepolia_rpc(self, url):
        """Check Sepolia RPC node comprehensive health"""
        self.print_section("SEPOLIA RPC NODE")
        
        host, port = self.parse_url(url, 8545)
        if not host:
            self.log_result(f"Invalid Sepolia URL format: {url}", "error")
            return {"reachable": False, "synced": False, "chain_id": 0, "latest_block": 0, "peers": 0}
        
        sepolia_results = {
            "reachable": False,
            "synced": False,
            "chain_id": 0,
            "latest_block": 0,
            "peers": 0
        }
        
        # Test port connectivity
        if not self.test_connection(host, port):
            self.log_result(f"Cannot connect to {host}:{port}", "error")
            self.log_result("Check: Is your Sepolia node running? Firewall open?", "warning")
            return sepolia_results
        
        self.log_result(f"Port {port} is open on {host}", "success")
        sepolia_results["reachable"] = True
        
        try:
            # Check chain ID (should be 11155111 for Sepolia)
            payload = {"jsonrpc": "2.0", "method": "eth_chainId", "params": [], "id": 1}
            response = requests.post(url, json=payload, timeout=self.timeout)
            if response.status_code == 200:
                chain_id = int(response.json().get("result", "0x0"), 16)
                sepolia_results["chain_id"] = chain_id
                if chain_id == 11155111:
                    self.log_result("✓ Confirmed Sepolia testnet (Chain ID: 11155111)", "success")
                else:
                    self.log_result(f"Warning: Unexpected chain ID: {chain_id}", "warning")
            
            # Check latest block
            payload = {"jsonrpc": "2.0", "method": "eth_blockNumber", "params": [], "id": 1}
            response = requests.post(url, json=payload, timeout=self.timeout)
            if response.status_code == 200:
                block_hex = response.json().get("result", "0x0")
                latest_block = int(block_hex, 16)
                sepolia_results["latest_block"] = latest_block
                self.log_result(f"Latest block: {latest_block:,}", "success")
            
            # Check sync status
            payload = {"jsonrpc": "2.0", "method": "eth_syncing", "params": [], "id": 1}
            response = requests.post(url, json=payload, timeout=self.timeout)
            if response.status_code == 200:
                sync_result = response.json().get("result")
                if sync_result is False:
                    sepolia_results["synced"] = True
                    self.log_result("Sepolia node is fully synced", "success")
                else:
                    self.log_result("Sepolia node is syncing (this is normal for new nodes)", "warning")
            
            # Check peer count
            payload = {"jsonrpc": "2.0", "method": "net_peerCount", "params": [], "id": 1}
            response = requests.post(url, json=payload, timeout=self.timeout)
            if response.status_code == 200:
                peer_hex = response.json().get("result", "0x0")
                peer_count = int(peer_hex, 16)
                sepolia_results["peers"] = peer_count
                if peer_count > 0:
                    self.log_result(f"Connected to {peer_count} peers", "success")
                else:
                    self.log_result("No peers connected (check network connectivity)", "warning")
                    
        except Exception as e:
            self.log_result(f"Error checking Sepolia RPC: {str(e)}", "error")
        
        return sepolia_results
    
    def print_summary(self, beacon_results, sepolia_results):
        """Print comprehensive summary of all health checks"""
        self.print_section("HEALTH CHECK SUMMARY")
        
        # Determine overall status
        beacon_healthy = beacon_results.get("reachable", False) and beacon_results.get("healthy", False)
        sepolia_healthy = sepolia_results.get("reachable", False)
        
        self.colored_print("📊 OVERALL NODE STATUS:", "cyan", "bright")
        
        # Beacon status
        if beacon_healthy:
            if beacon_results.get("synced", False):
                self.colored_print("   🟢 Beacon Chain: HEALTHY & SYNCED", "green")
            else:
                self.colored_print("   🟡 Beacon Chain: HEALTHY (syncing)", "yellow")
        else:
            self.colored_print("   🔴 Beacon Chain: OFFLINE/UNHEALTHY", "red")
        
        # Sepolia status  
        if sepolia_healthy:
            if sepolia_results.get("synced", False):
                self.colored_print("   🟢 Sepolia RPC: HEALTHY & SYNCED", "green")
            else:
                self.colored_print("   🟡 Sepolia RPC: HEALTHY (syncing)", "yellow")
        else:
            self.colored_print("   🔴 Sepolia RPC: OFFLINE/UNREACHABLE", "red")
        
        # Detailed metrics
        self.colored_print("\n📈 DETAILED METRICS:", "cyan", "bright")
        
        if HAS_TABULATE:
            # Use tabulate for nice table formatting
            table_data = [
                ["Beacon Peers", beacon_results.get("peers", "N/A")],
                ["Sepolia Peers", sepolia_results.get("peers", "N/A")], 
                ["Sepolia Chain ID", sepolia_results.get("chain_id", "N/A")],
                ["Latest Block", f"{sepolia_results.get('latest_block', 'N/A'):,}" if sepolia_results.get('latest_block') else "N/A"],
                ["Beacon Version", beacon_results.get("version", "N/A")]
            ]
            print(tabulate(table_data, headers=["Metric", "Value"], tablefmt="grid"))
        else:
            # Fallback to simple formatting
            print(f"   • Beacon Peers: {beacon_results.get('peers', 'N/A')}")
            print(f"   • Sepolia Peers: {sepolia_results.get('peers', 'N/A')}")
            print(f"   • Chain ID: {sepolia_results.get('chain_id', 'N/A')}")
            latest_block = sepolia_results.get('latest_block', 'N/A')
            if isinstance(latest_block, int):
                print(f"   • Latest Block: {latest_block:,}")
            else:
                print(f"   • Latest Block: {latest_block}")
            print(f"   • Beacon Version: {beacon_results.get('version', 'N/A')}")
        
        # Troubleshooting section
        if not beacon_healthy or not sepolia_healthy:
            self.colored_print("\n🔧 TROUBLESHOOTING TIPS:", "yellow", "bright")
            
            if not beacon_healthy:
                print("   Beacon Chain Issues:")
                print("   • Check if beacon node service is running: sudo systemctl status beacon-node")
                print("   • Verify port 5052 is open in firewall: sudo ufw allow 5052")
                print("   • Ensure beacon node allows external connections (--http-address 0.0.0.0)")
                print("   • Check beacon node logs: journalctl -u beacon-node -f")
            
            if not sepolia_healthy:
                print("   Sepolia RPC Issues:")
                print("   • Check if geth/sepolia service is running: sudo systemctl status geth")  
                print("   • Verify port 8545 is open in firewall: sudo ufw allow 8545")
                print("   • Ensure RPC allows external connections (--http.addr 0.0.0.0)")
                print("   • Check sepolia node logs: journalctl -u geth -f")
            
            print("\n   General troubleshooting:")
            print("   • Verify sufficient disk space: df -h")
            print("   • Check memory usage: free -h")
            print("   • Test internet connectivity: ping 8.8.8.8")
            print("   • Restart services if needed: sudo systemctl restart [service-name]")
        
        return beacon_healthy and sepolia_healthy

def main():
    parser = argparse.ArgumentParser(
        description="Ethereum Node Health Checker - Professional monitoring for Beacon & Sepolia nodes",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Check local nodes (default)
  python3 eth_health_check.py
  
  # Check remote nodes
  python3 eth_health_check.py --beacon http://1.2.3.4:5052 --sepolia http://1.2.3.4:8545
  
  # Use custom timeout for slow connections
  python3 eth_health_check.py --timeout 30
  
  # Check only beacon node
  python3 eth_health_check.py --sepolia ""
        """
    )
    
    parser.add_argument("--beacon", 
                       default="http://localhost:5052",
                       help="Beacon node URL (default: http://localhost:5052)")
    parser.add_argument("--sepolia", 
                       default="http://localhost:8545", 
                       help="Sepolia RPC URL (default: http://localhost:8545)")
    parser.add_argument("--timeout", 
                       type=int, 
                       default=15,
                       help="Request timeout in seconds (default: 15)")
    parser.add_argument("--version", 
                       action="version", 
                       version="Ethereum Node Health Checker v1.0.0")
    
    args = parser.parse_args()
    
    # Create checker instance
    checker = NodeHealthChecker(timeout=args.timeout)
    
    # Print header
    checker.print_header()
    
    # Run health checks
    beacon_results = {}
    sepolia_results = {}
    
    if args.beacon:
        beacon_results = checker.check_beacon_node(args.beacon)
    
    if args.sepolia:
        sepolia_results = checker.check_sepolia_rpc(args.sepolia)
    
    # Print summary and determine exit status
    all_healthy = checker.print_summary(beacon_results, sepolia_results)
    
    # Print footer
    checker.colored_print("\n" + "="*70, "blue")
    if all_healthy:
        checker.colored_print("🎉 All systems are running well! Keep up the good work!", "green", "bright")
    else:
        checker.colored_print("⚡ Some issues detected. Check the troubleshooting tips above.", "yellow", "bright")
    checker.colored_print("="*70, "blue")
    
    # Exit with appropriate code for automation
    sys.exit(0 if all_healthy else 1)

if __name__ == "__main__":
    main()
