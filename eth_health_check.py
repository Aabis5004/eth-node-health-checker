#!/usr/bin/env python3
"""
Enhanced Ethereum Node Health Checker - Professional monitoring tool
Based on original eth_health_check.py with consistency improvements and detailed diagnostics
"""

import requests
import json
import socket
import sys
import argparse
import time
import statistics
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

try:
    import psutil
    HAS_PSUTIL = True
except ImportError:
    HAS_PSUTIL = False

class EnhancedNodeHealthChecker:
    def __init__(self, timeout=15, retries=3):
        self.timeout = timeout
        self.retries = retries
        self.results = {}
        self.performance_metrics = {}
        
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
            "white": Fore.WHITE,
            "magenta": Fore.MAGENTA
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
        self.colored_print("\n" + "="*80, "blue", "bright")
        self.colored_print("🚀 ENHANCED ETHEREUM NODE HEALTH CHECKER v2.0", "cyan", "bright")
        self.colored_print("Professional monitoring with consistent results and detailed diagnostics", "white")
        self.colored_print("="*80, "blue", "bright")
    
    def print_section(self, title):
        """Print a section header"""
        self.colored_print(f"\n📋 {title}", "yellow", "bright")
        self.colored_print("-" * (len(title) + 4), "yellow")
    
    def log_result(self, message, status="info", details=None):
        """Log a result with timestamp, status icon, and optional details"""
        timestamp = datetime.now().strftime("%H:%M:%S")
        
        status_map = {
            "success": ("green", "✅"),
            "error": ("red", "❌"), 
            "warning": ("yellow", "⚠️"),
            "info": ("blue", "ℹ️"),
            "performance": ("magenta", "⚡"),
            "critical": ("red", "🚨")
        }
        
        color, icon = status_map.get(status, ("white", "•"))
        self.colored_print(f"[{timestamp}] {icon} {message}", color)
        
        if details:
            for detail in details:
                self.colored_print(f"    └─ {detail}", "white")
    
    def test_connection_advanced(self, host, port):
        """Advanced connection test with multiple attempts and timing"""
        attempts = []
        
        for attempt in range(self.retries):
            start_time = time.time()
            try:
                sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                sock.settimeout(self.timeout)
                result = sock.connect_ex((host, port))
                sock.close()
                
                end_time = time.time()
                latency = (end_time - start_time) * 1000
                
                attempts.append({
                    'success': result == 0,
                    'latency': latency,
                    'attempt': attempt + 1
                })
                
                if result == 0:
                    time.sleep(0.1)  # Small delay between attempts
                    
            except Exception as e:
                end_time = time.time()
                latency = (end_time - start_time) * 1000
                attempts.append({
                    'success': False,
                    'latency': latency,
                    'attempt': attempt + 1,
                    'error': str(e)
                })
        
        return attempts
    
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
    
    def make_request_with_retry(self, method, url, **kwargs):
        """Make HTTP request with retry logic and performance tracking"""
        latencies = []
        errors = []
        
        for attempt in range(self.retries):
            start_time = time.time()
            try:
                if method.upper() == 'GET':
                    response = requests.get(url, timeout=self.timeout, **kwargs)
                elif method.upper() == 'POST':
                    response = requests.post(url, timeout=self.timeout, **kwargs)
                else:
                    raise ValueError(f"Unsupported method: {method}")
                
                end_time = time.time()
                latency = (end_time - start_time) * 1000
                latencies.append(latency)
                
                if response.status_code == 200:
                    return response, {
                        'latencies': latencies,
                        'avg_latency': statistics.mean(latencies),
                        'attempts': attempt + 1,
                        'errors': errors
                    }
                else:
                    errors.append(f"HTTP {response.status_code}")
                    
            except Exception as e:
                end_time = time.time()
                latency = (end_time - start_time) * 1000
                latencies.append(latency)
                errors.append(str(e))
                
                if attempt < self.retries - 1:
                    time.sleep(0.5)  # Wait before retry
        
        return None, {
            'latencies': latencies,
            'avg_latency': statistics.mean(latencies) if latencies else 0,
            'attempts': self.retries,
            'errors': errors
        }
    
    def diagnose_connection_issues(self, host, port, connection_attempts):
        """Diagnose connection issues based on test results"""
        successful_attempts = [a for a in connection_attempts if a['success']]
        failed_attempts = [a for a in connection_attempts if not a['success']]
        
        if not successful_attempts:
            # All attempts failed
            avg_latency = statistics.mean([a['latency'] for a in failed_attempts])
            
            if avg_latency > (self.timeout * 1000 * 0.9):  # Close to timeout
                return "critical", [
                    "Connection timeout - service likely not running or severely overloaded",
                    f"Average timeout: {avg_latency:.0f}ms (limit: {self.timeout*1000}ms)",
                    "Check: sudo systemctl status [service-name]",
                    f"Check: sudo netstat -tlnp | grep {port}"
                ]
            elif avg_latency > 5000:  # >5 seconds
                return "critical", [
                    "Severe network latency or system overload",
                    f"Average response time: {avg_latency:.0f}ms",
                    "Check: System resources (CPU, Memory, Disk I/O)",
                    "Check: Network connectivity and firewall rules"
                ]
            else:
                return "error", [
                    "Port closed or service not responding",
                    f"Connection refused after {avg_latency:.0f}ms",
                    f"Check: sudo ufw status (firewall on port {port})",
                    "Check: Service configuration and binding address"
                ]
        else:
            # Some successful attempts
            success_rate = len(successful_attempts) / len(connection_attempts) * 100
            avg_latency = statistics.mean([a['latency'] for a in successful_attempts])
            
            if success_rate < 100:
                return "warning", [
                    f"Intermittent connectivity ({success_rate:.0f}% success rate)",
                    f"Average latency: {avg_latency:.0f}ms",
                    "Check: Network stability and system load",
                    "Consider: Increasing timeout values"
                ]
            elif avg_latency > 1000:  # >1 second
                return "warning", [
                    "High latency detected",
                    f"Average response time: {avg_latency:.0f}ms",
                    "Check: System performance and network conditions",
                    "Consider: Hardware upgrade if consistently slow"
                ]
            else:
                return "success", [
                    f"Connection stable (latency: {avg_latency:.0f}ms)"
                ]
    
    def check_system_resources(self):
        """Check local system resources that might affect node performance"""
        if not HAS_PSUTIL:
            self.log_result("System monitoring unavailable (install psutil for system checks)", "warning")
            return
            
        try:
            cpu_percent = psutil.cpu_percent(interval=1)
            memory = psutil.virtual_memory()
            disk = psutil.disk_usage('/')
            
            self.log_result(f"System CPU usage: {cpu_percent:.1f}%", 
                          "warning" if cpu_percent > 80 else "info")
            self.log_result(f"System memory usage: {memory.percent:.1f}%", 
                          "warning" if memory.percent > 80 else "info")
            self.log_result(f"System disk usage: {disk.percent:.1f}%", 
                          "warning" if disk.percent > 90 else "info")
            
            if cpu_percent > 90:
                self.log_result("High CPU usage may affect node performance", "warning")
            if memory.percent > 90:
                self.log_result("High memory usage may affect node performance", "warning")
            if disk.percent > 95:
                self.log_result("Very high disk usage - critical for blockchain sync", "critical")
                
        except Exception as e:
            self.log_result(f"Could not check system resources: {e}", "warning")
    
    def check_beacon_node(self, url):
        """Enhanced Beacon node health check with detailed diagnostics"""
        self.print_section("BEACON CHAIN NODE - ENHANCED DIAGNOSTICS")
        
        host, port = self.parse_url(url, 5052)
        if not host:
            self.log_result(f"Invalid Beacon URL format: {url}", "error")
            return {"reachable": False, "healthy": False, "issues": ["Invalid URL format"]}
        
        beacon_results = {
            "reachable": False,
            "healthy": False, 
            "synced": False,
            "peers": 0,
            "version": "Unknown",
            "performance": {},
            "issues": []
        }
        
        # Advanced connection test
        self.log_result("Testing connection stability...", "info")
        connection_attempts = self.test_connection_advanced(host, port)
        status, details = self.diagnose_connection_issues(host, port, connection_attempts)
        
        self.log_result(f"Connection test complete", status, details)
        
        if not any(attempt['success'] for attempt in connection_attempts):
            beacon_results["issues"].extend(details)
            return beacon_results
        
        beacon_results["reachable"] = True
        
        # Health check with performance tracking
        response, perf_data = self.make_request_with_retry('GET', f"{url}/eth/v1/node/health")
        beacon_results["performance"]["health_check"] = perf_data
        
        if response and response.status_code == 200:
            beacon_results["healthy"] = True
            self.log_result("Beacon node is responding and healthy", "success")
            self.log_result(f"Health check latency: {perf_data['avg_latency']:.0f}ms", "performance")
        else:
            error_details = [
                f"Health endpoint failed after {perf_data['attempts']} attempts",
                f"Average latency: {perf_data['avg_latency']:.0f}ms",
                f"Errors: {', '.join(perf_data['errors'])}"
            ]
            self.log_result("Beacon node health check failed", "error", error_details)
            beacon_results["issues"].extend(error_details)
        
        # Sync status check
        response, perf_data = self.make_request_with_retry('GET', f"{url}/eth/v1/node/syncing")
        beacon_results["performance"]["sync_check"] = perf_data
        
        if response and response.status_code == 200:
            try:
                sync_data = response.json()
                is_syncing = sync_data.get("data", {}).get("is_syncing", True)
                
                if not is_syncing:
                    beacon_results["synced"] = True
                    self.log_result("Beacon node is fully synced", "success")
                else:
                    sync_info = sync_data.get("data", {})
                    head_slot = sync_info.get("head_slot", 0)
                    sync_distance = sync_info.get("sync_distance", 0)
                    
                    sync_details = [
                        f"Head slot: {head_slot}",
                        f"Sync distance: {sync_distance} slots behind"
                    ]
                    
                    if sync_distance > 100:
                        self.log_result("Beacon node is significantly behind", "warning", sync_details)
                        beacon_results["issues"].append(f"Syncing behind by {sync_distance} slots")
                    else:
                        self.log_result("Beacon node is catching up (near synced)", "info", sync_details)
                        
            except Exception as e:
                self.log_result(f"Error parsing sync data: {e}", "error")
        
        # Peer check with analysis
        response, perf_data = self.make_request_with_retry('GET', f"{url}/eth/v1/node/peers")
        beacon_results["performance"]["peer_check"] = perf_data
        
        if response and response.status_code == 200:
            try:
                peers_data = response.json()
                peer_count = len(peers_data.get("data", []))
                beacon_results["peers"] = peer_count
                
                if peer_count >= 50:
                    self.log_result(f"Excellent peer connectivity: {peer_count} peers", "success")
                elif peer_count >= 10:
                    self.log_result(f"Good peer connectivity: {peer_count} peers", "success")
                elif peer_count >= 3:
                    self.log_result(f"Minimal peer connectivity: {peer_count} peers", "warning")
                    beacon_results["issues"].append("Low peer count may affect sync performance")
                else:
                    self.log_result(f"Poor peer connectivity: {peer_count} peers", "error")
                    beacon_results["issues"].append("Very low peer count - check network connectivity")
                    
            except Exception as e:
                self.log_result(f"Error parsing peer data: {e}", "error")
        
        # Version check
        response, perf_data = self.make_request_with_retry('GET', f"{url}/eth/v1/node/version")
        if response and response.status_code == 200:
            try:
                version_data = response.json()
                version = version_data.get("data", {}).get("version", "Unknown")
                beacon_results["version"] = version
                self.log_result(f"Node version: {version}", "info")
            except Exception as e:
                self.log_result(f"Error getting version: {e}", "warning")
        
        return beacon_results
    
    def check_sepolia_rpc(self, url):
        """Enhanced Sepolia RPC health check with detailed diagnostics"""
        self.print_section("SEPOLIA RPC NODE - ENHANCED DIAGNOSTICS")
        
        host, port = self.parse_url(url, 8545)
        if not host:
            self.log_result(f"Invalid Sepolia URL format: {url}", "error")
            return {"reachable": False, "issues": ["Invalid URL format"]}
        
        sepolia_results = {
            "reachable": False,
            "synced": False,
            "chain_id": 0,
            "latest_block": 0,
            "peers": 0,
            "performance": {},
            "issues": [],
            "block_time_analysis": {}
        }
        
        # Advanced connection test
        self.log_result("Testing RPC connection stability...", "info")
        connection_attempts = self.test_connection_advanced(host, port)
        status, details = self.diagnose_connection_issues(host, port, connection_attempts)
        
        self.log_result(f"RPC connection test complete", status, details)
        
        if not any(attempt['success'] for attempt in connection_attempts):
            sepolia_results["issues"].extend(details)
            return sepolia_results
        
        sepolia_results["reachable"] = True
        
        # Chain ID verification
        payload = {"jsonrpc": "2.0", "method": "eth_chainId", "params": [], "id": 1}
        response, perf_data = self.make_request_with_retry('POST', url, json=payload)
        sepolia_results["performance"]["chain_id_check"] = perf_data
        
        if response and response.status_code == 200:
            try:
                chain_id = int(response.json().get("result", "0x0"), 16)
                sepolia_results["chain_id"] = chain_id
                
                if chain_id == 11155111:
                    self.log_result("✓ Confirmed Sepolia testnet (Chain ID: 11155111)", "success")
                elif chain_id == 1:
                    self.log_result("⚠️ Connected to Ethereum Mainnet instead of Sepolia", "warning")
                    sepolia_results["issues"].append("Wrong network - connected to mainnet")
                else:
                    self.log_result(f"⚠️ Unexpected chain ID: {chain_id}", "warning")
                    sepolia_results["issues"].append(f"Unknown network (Chain ID: {chain_id})")
                    
            except Exception as e:
                self.log_result(f"Error parsing chain ID: {e}", "error")
        
        # Block number and sync analysis
        payload = {"jsonrpc": "2.0", "method": "eth_blockNumber", "params": [], "id": 1}
        response, perf_data = self.make_request_with_retry('POST', url, json=payload)
        sepolia_results["performance"]["block_number_check"] = perf_data
        
        if response and response.status_code == 200:
            try:
                block_hex = response.json().get("result", "0x0")
                latest_block = int(block_hex, 16)
                sepolia_results["latest_block"] = latest_block
                
                self.log_result(f"Latest block: {latest_block:,}", "success")
                self.log_result(f"Block query latency: {perf_data['avg_latency']:.0f}ms", "performance")
                
                # Analyze block timing
                current_time = time.time()
                block_payload = {"jsonrpc": "2.0", "method": "eth_getBlockByNumber", 
                               "params": [hex(latest_block), False], "id": 1}
                block_response, _ = self.make_request_with_retry('POST', url, json=block_payload)
                
                if block_response and block_response.status_code == 200:
                    block_data = block_response.json().get("result", {})
                    if block_data:
                        block_timestamp = int(block_data.get("timestamp", "0x0"), 16)
                        block_age = current_time - block_timestamp
                        
                        sepolia_results["block_time_analysis"]["last_block_age"] = block_age
                        
                        if block_age > 60:  # More than 1 minute since last block
                            self.log_result(f"Last block is {block_age:.0f}s old - may be syncing", "warning")
                            sepolia_results["issues"].append("Node may be behind on sync")
                        else:
                            self.log_result(f"Recent block activity (last: {block_age:.0f}s ago)", "success")
                            
            except Exception as e:
                self.log_result(f"Error analyzing blocks: {e}", "error")
        
        # Sync status check
        payload = {"jsonrpc": "2.0", "method": "eth_syncing", "params": [], "id": 1}
        response, perf_data = self.make_request_with_retry('POST', url, json=payload)
        sepolia_results["performance"]["sync_check"] = perf_data
        
        if response and response.status_code == 200:
            try:
                sync_result = response.json().get("result")
                
                if sync_result is False:
                    sepolia_results["synced"] = True
                    self.log_result("Sepolia node is fully synced", "success")
                else:
                    if isinstance(sync_result, dict):
                        current_block = int(sync_result.get("currentBlock", "0x0"), 16)
                        highest_block = int(sync_result.get("highestBlock", "0x0"), 16)
                        blocks_behind = highest_block - current_block
                        
                        sync_details = [
                            f"Current block: {current_block:,}",
                            f"Highest block: {highest_block:,}",
                            f"Blocks behind: {blocks_behind:,}"
                        ]
                        
                        if blocks_behind > 1000:
                            self.log_result("Node is significantly behind", "warning", sync_details)
                            sepolia_results["issues"].append(f"Syncing: {blocks_behind:,} blocks behind")
                        else:
                            self.log_result("Node is catching up", "info", sync_details)
                    else:
                        self.log_result("Node is syncing (details unavailable)", "info")
                        
            except Exception as e:
                self.log_result(f"Error checking sync status: {e}", "error")
        
        # Peer count check
        payload = {"jsonrpc": "2.0", "method": "net_peerCount", "params": [], "id": 1}
        response, perf_data = self.make_request_with_retry('POST', url, json=payload)
        sepolia_results["performance"]["peer_check"] = perf_data
        
        if response and response.status_code == 200:
            try:
                peer_hex = response.json().get("result", "0x0")
                peer_count = int(peer_hex, 16)
                sepolia_results["peers"] = peer_count
                
                if peer_count >= 25:
                    self.log_result(f"Excellent peer connectivity: {peer_count} peers", "success")
                elif peer_count >= 10:
                    self.log_result(f"Good peer connectivity: {peer_count} peers", "success")
                elif peer_count >= 3:
                    self.log_result(f"Minimal peer connectivity: {peer_count} peers", "warning")
                    sepolia_results["issues"].append("Low peer count may affect sync performance")
                else:
                    self.log_result(f"Poor peer connectivity: {peer_count} peers", "error")
                    sepolia_results["issues"].append("Very low peer count - check network connectivity")
                    
            except Exception as e:
                self.log_result(f"Error checking peer count: {e}", "error")
        
        return sepolia_results
    
    def print_summary(self, beacon_results, sepolia_results):
        """Print comprehensive summary of all health checks"""
        self.print_section("COMPREHENSIVE HEALTH SUMMARY")
        
        # Determine overall status
        beacon_healthy = beacon_results.get("reachable", False) and beacon_results.get("healthy", False)
        sepolia_healthy = sepolia_results.get("reachable", False)
        
        self.colored_print("📊 OVERALL NODE STATUS:", "cyan", "bright")
        
        # Beacon status
        if beacon_healthy:
            if beacon_results.get("synced", False):
                self.colored_print("   🟢 Beacon Chain: OPTIMAL (healthy & synced)", "green")
            else:
                self.colored_print("   🟡 Beacon Chain: FUNCTIONAL (healthy, syncing)", "yellow")
        else:
            self.colored_print("   🔴 Beacon Chain: CRITICAL (offline/unhealthy)", "red")
        
        # Sepolia status  
        if sepolia_healthy:
            if sepolia_results.get("synced", False):
                self.colored_print("   🟢 Sepolia RPC: OPTIMAL (reachable & synced)", "green")
            else:
                self.colored_print("   🟡 Sepolia RPC: FUNCTIONAL (reachable, syncing)", "yellow")
        else:
            self.colored_print("   🔴 Sepolia RPC: CRITICAL (unreachable)", "red")
        
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
        
        # Issues and troubleshooting
        all_issues = beacon_results.get("issues", []) + sepolia_results.get("issues", [])
        
        if all_issues:
            self.colored_print("\n🚨 IDENTIFIED ISSUES:", "red", "bright")
            for i, issue in enumerate(all_issues, 1):
                self.colored_print(f"   {i}. {issue}", "red")
        
        # Troubleshooting section
        if not beacon_healthy or not sepolia_healthy:
            self.colored_print("\n🔧 TROUBLESHOOTING TIPS:", "yellow", "bright")
            
            if not beacon_healthy:
                print("   Beacon Chain Issues:")
                print("   • Check if beacon node service is running: sudo systemctl status lighthouse-bn")
                print("   • Verify port 3500 is open in firewall: sudo ufw allow 3500")
                print("   • Ensure beacon node allows external connections (--http-address 0.0.0.0)")
                print("   • Check beacon node logs: sudo journalctl -u lighthouse-bn -f")
            
            if not sepolia_healthy:
                print("   Sepolia RPC Issues:")
                print("   • Check if geth/sepolia service is running: sudo systemctl status geth")  
                print("   • Verify port 8545 is open in firewall: sudo ufw allow 8545")
                print("   • Ensure RPC allows external connections (--http.addr 0.0.0.0)")
                print("   • Check sepolia node logs: sudo journalctl -u geth -f")
            
            print("\n   General troubleshooting:")
            print("   • Verify sufficient disk space: df -h")
            print("   • Check memory usage: free -h")
            print("   • Test internet connectivity: ping 8.8.8.8")
            print("   • Restart services if needed: sudo systemctl restart [service-name]")
        
        return beacon_healthy and sepolia_healthy

def main():
    parser = argparse.ArgumentParser(
        description="Enhanced Ethereum Node Health Checker - Professional monitoring with consistent results",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Check local nodes (default)
  python3 eth_health_check.py
  
  # Check remote nodes
  python3 eth_health_check.py --beacon http://1.2.3.4:5052 --sepolia http://1.2.3.4:8545
  
  # Use custom timeout and retries for consistency
  python3 eth_health_check.py --timeout 30 --retries 5
  
  # Monitor mode (continuous checking)
  python3 eth_health_check.py --monitor 60
  
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
    parser.add_argument("--retries",
                       type=int,
                       default=3,
                       help="Number of retry attempts for consistency (default: 3)")
    parser.add_argument("--monitor",
                       type=int,
                       help="Monitor mode: repeat check every N seconds")
    parser.add_argument("--no-system-check",
                       action="store_true",
                       help="Skip local system resource check")
    parser.add_argument("--version", 
                       action="version", 
                       version="Enhanced Ethereum Node Health Checker v2.0.0")
    
    args = parser.parse_args()
    
    def run_health_check():
        # Create checker instance
        checker = EnhancedNodeHealthChecker(timeout=args.timeout, retries=args.retries)
        
        # Print header
        checker.print_header()
        
        # Check system resources if not disabled
        if not args.no_system_check:
            checker.print_section("SYSTEM RESOURCE CHECK")
            checker.check_system_resources()
        
        # Run health checks
        beacon_results = {}
        sepolia_results = {}
        
        if args.beacon:
            beacon_results = checker.check_beacon_node(args.beacon)
        
        if args.sepolia:
            sepolia_results = checker.check_sepolia_rpc(args.sepolia)
        
        # Print summary and determine overall health
        all_healthy = checker.print_summary(beacon_results, sepolia_results)
        
        # Print footer
        checker.colored_print("\n" + "="*80, "blue")
        current_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        
        if all_healthy:
            checker.colored_print(f"🎉 All systems optimal! Last checked: {current_time}", "green", "bright")
        else:
            checker.colored_print(f"⚡ Issues detected. Last checked: {current_time}", "yellow", "bright")
            checker.colored_print("📋 Review the troubleshooting section above for specific fixes.", "yellow")
        
        checker.colored_print("="*80, "blue")
        
        return all_healthy
    
    # Monitor mode
    if args.monitor:
        print(f"🔄 Starting monitor mode (checking every {args.monitor} seconds)")
        print("Press Ctrl+C to stop monitoring")
        
        try:
            while True:
                all_healthy = run_health_check()
                
                if args.monitor > 30:  # Only show countdown for longer intervals
                    for remaining in range(args.monitor, 0, -1):
                        print(f"\r⏱️  Next check in {remaining} seconds... ", end="", flush=True)
                        time.sleep(1)
                    print()  # New line after countdown
                else:
                    time.sleep(args.monitor)
                    
        except KeyboardInterrupt:
            print("\n\n🛑 Monitoring stopped by user")
            sys.exit(0)
    else:
        # Single run
        all_healthy = run_health_check()
        
        # Exit with appropriate code for automation
        sys.exit(0 if all_healthy else 1)

if __name__ == "__main__":
    main()
