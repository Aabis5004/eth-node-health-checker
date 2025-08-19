#!/usr/bin/env python3
"""
Enhanced Ethereum Node Health Checker - Professional monitoring tool
Provides consistent results with detailed diagnostics and performance analysis
"""

import requests
import json
import socket
import sys
import argparse
import time
import threading
import psutil
import statistics
from datetime import datetime, timedelta
from concurrent.futures import ThreadPoolExecutor, as_completed

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
        self.colored_print("Professional monitoring with detailed diagnostics and performance analysis", "white")
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
    
    def measure_latency(self, func, *args, **kwargs):
        """Measure function execution time and return result with timing"""
        start_time = time.time()
        try:
            result = func(*args, **kwargs)
            end_time = time.time()
            latency = (end_time - start_time) * 1000  # Convert to milliseconds
            return result, latency, None
        except Exception as e:
            end_time = time.time()
            latency = (end_time - start_time) * 1000
            return None, latency, str(e)
    
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
                    "Check: netstat -tlnp | grep {port}"
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
    
    def check_beacon_node_enhanced(self, url):
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
    
    def check_sepolia_rpc_enhanced(self, url):
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
                
                # Get multiple recent blocks to analyze block times
                recent_blocks = []
                for i in range(5):
                    block_num = latest_block - i
                    if block_num > 0:
                        block_payload = {"jsonrpc": "2.0", "method": "eth_getBlockByNumber", 
                                       "params": [hex(block_num), False], "id": 1}
                        block_response, _ = self.make_request_with_retry('POST', url, json=block_payload)
                        
                        if block_response and block_response.status_code == 200:
                            block_data = block_response.json().get("result", {})
                            if block_data:
                                timestamp = int(block_data.get("timestamp", "0x0"), 16)
                                recent_blocks.append({
                                    'number': block_num,
                                    'timestamp': timestamp
                                })
                
                # Analyze block times
                if len(recent_blocks) >= 2:
                    recent_blocks.sort(key=lambda x: x['number'])
                    block_times = []
                    
                    for i in range(1, len(recent_blocks)):
                        time_diff = recent_blocks[i]['timestamp'] - recent_blocks[i-1]['timestamp']
                        block_times.append(time_diff)
                    
                    if block_times:
                        avg_block_time = statistics.mean(block_times)
                        last_block_time = time.time() - recent_blocks[-1]['timestamp']
                        
                        sepolia_results["block_time_analysis"] = {
                            "avg_block_time": avg_block_time,
                            "last_block_age": last_block_time
                        }
                        
                        if last_block_time > 60:  # More than 1 minute since last block
                            self.log_result(f"Last block is {last_block_time:.0f}s old - may be syncing", "warning")
                            sepolia_results["issues"].append("Node may be behind on sync")
                        else:
                            self.log_result(f"Recent block activity (last: {last_block_time:.0f}s ago)", "success")
                        
                        if avg_block_time > 20:  # Sepolia should be ~12s
                            self.log_result(f"Block time seems slow: {avg_block_time:.1f}s average", "warning")
                        else:
                            self.log_result(f"Block time healthy: {avg_block_time:.1f}s average", "success")
                            
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
    
    def print_enhanced_summary(self, beacon_results, sepolia_results):
        """Print comprehensive summary with detailed diagnostics"""
        self.print_section("COMPREHENSIVE HEALTH SUMMARY")
        
        # Overall status
        beacon_healthy = beacon_results.get("reachable", False) and beacon_results.get("healthy", False)
        sepolia_healthy = sepolia_results.get("reachable", False)
        
        self.colored_print("📊 OVERALL STATUS:", "cyan", "bright")
        
        # Beacon status with details
        if beacon_healthy:
            if beacon_results.get("synced", False):
                self.colored_print("   🟢 Beacon Chain: OPTIMAL (healthy & synced)", "green")
            else:
                self.colored_print("   🟡 Beacon Chain: FUNCTIONAL (healthy, syncing)", "yellow")
        else:
            self.colored_print("   🔴 Beacon Chain: CRITICAL (offline/unhealthy)", "red")
        
        # Sepolia status with details
        if sepolia_healthy:
            if sepolia_results.get("synced", False):
                self.colored_print("   🟢 Sepolia RPC: OPTIMAL (reachable & synced)", "green")
            else:
                self.colored_print("   🟡 Sepolia RPC: FUNCTIONAL (reachable, syncing)", "yellow")
        else:
            self.colored_print("   🔴 Sepolia RPC: CRITICAL (unreachable)", "red")
        
        # Performance metrics
        self.colored_print("\n⚡ PERFORMANCE METRICS:", "cyan", "bright")
        
        if HAS_TABULATE:
            perf_table = []
            
            # Beacon performance
            if "health_check" in beacon_results.get("performance", {}):
                health_perf = beacon_results["performance"]["health_check"]
                perf_table.append(["Beacon Health Check", f"{health_perf['avg_latency']:.0f}ms", 
                                 f"{health_perf['attempts']} attempts"])
            
            if "sync_check" in beacon_results.get("performance", {}):
                sync_perf = beacon_results["performance"]["sync_check"]
                perf_table.append(["Beacon Sync Check", f"{sync_perf['avg_latency']:.0f}ms",
                                 f"{sync_perf['attempts']} attempts"])
            
            # Sepolia performance
            if "chain_id_check" in sepolia_results.get("performance", {}):
                chain_perf = sepolia_results["performance"]["chain_id_check"]
                perf_table.append(["Sepolia Chain ID", f"{chain_perf['avg_latency']:.0f}ms",
                                 f"{chain_perf['attempts']} attempts"])
            
            if "block_number_check" in sepolia_results.get("performance", {}):
                block_perf = sepolia_results["performance"]["block_number_check"]
                perf_table.append(["Sepolia Block Query", f"{block_perf['avg_latency']:.0f}ms",
                                 f"{block_perf['attempts']} attempts"])
            
            if perf_table:
                print(tabulate(perf_table, headers=["Operation", "Avg Latency", "Attempts"], tablefmt="grid"))
        
        # Detailed metrics table
        self.colored_print("\n📈 DETAILED METRICS:", "cyan", "bright")
        
        if HAS_TABULATE:
            metrics_table = [
                ["Beacon Peers", beacon_results.get("peers", "N/A")],
                ["Sepolia Peers", sepolia_results.get("peers", "N/A")],
                ["Chain ID", sepolia_results.get("chain_id", "N/A")],
                ["Latest Block", f"{sepolia_results.get('latest_block', 'N/A'):,}" if sepolia_results.get('latest_block') else "N/A"],
                ["Beacon Version", beacon_results.get("version", "N/A")]
            ]
            
            # Add block time analysis if available
            if "block_time_analysis" in sepolia_results:
                bta = sepolia_results["block_time_analysis"]
                if "avg_block_time" in bta:
                    metrics_table.append(["Avg Block Time", f"{bta['avg_block_time']:.1f}s"])
                if "last_block_age" in bta:
                    metrics_table.append(["Last Block Age", f"{bta['last_block_age']:.0f}s"])
            
            print(tabulate(metrics_table, headers=["Metric", "Value"], tablefmt="grid"))
        else:
            # Fallback formatting
            print(f"   • Beacon Peers: {beacon_results.get('peers', 'N/A')}")
            print(f"   • Sepolia Peers: {sepolia_results.get('peers', 'N/A')}")
            print(f"   • Chain ID: {sepolia_results.get('chain_id', 'N/A')}")
            latest_block = sepolia_results.get('latest_block', 'N/A')
            if isinstance(latest_block, int):
                print(f"   • Latest Block: {latest_block:,}")
            else:
                print(f"   • Latest Block: {latest_block}")
            print(f"   • Beacon Version: {beacon_results.get('version', 'N/A')}")
        
        # Issues and recommendations
        all_issues = beacon_results.get("issues", []) + sepolia_results.get("issues", [])
        
        if all_issues:
            self.colored_print("\n🚨 IDENTIFIED ISSUES:", "red", "bright")
            for i, issue in enumerate(all_issues, 1):
                self.colored_print(f"   {i}. {issue}", "red")
        
        # Specific recommendations based on issues
        if not beacon_healthy or not sepolia_healthy or all_issues:
            self.print_detailed_troubleshooting(beacon_results, sepolia_results)
        
        # Performance recommendations
        self.print_performance_recommendations(beacon_results, sepolia_results)
        
        return beacon_healthy and sepolia_healthy
    
    def print_detailed_troubleshooting(self, beacon_results, sepolia_results):
        """Print detailed troubleshooting based on specific issues found"""
        self.colored_print("\n🔧 DETAILED TROUBLESHOOTING:", "yellow", "bright")
        
        beacon_healthy = beacon_results.get("reachable", False) and beacon_results.get("healthy", False)
        sepolia_healthy = sepolia_results.get("reachable", False)
        
        if not beacon_results.get("reachable", False):
            self.colored_print("\n🔴 BEACON NODE CONNECTION ISSUES:", "red", "bright")
            print("   Immediate actions:")
            print("   1. Check if beacon service is running:")
            print("      sudo systemctl status lighthouse-bn  # or your beacon client")
            print("   2. Check beacon logs for errors:")
            print("      sudo journalctl -u lighthouse-bn -f --no-pager")
            print("   3. Verify port accessibility:")
            print("      sudo netstat -tlnp | grep 5052")
            print("   4. Test local connection:")
            print("      curl -f http://localhost:5052/eth/v1/node/health")
            print("   5. Check firewall rules:")
            print("      sudo ufw status | grep 5052")
        
        elif not beacon_results.get("healthy", False):
            self.colored_print("\n🟡 BEACON NODE HEALTH ISSUES:", "yellow", "bright")
            print("   Health endpoint responding but indicating issues:")
            print("   1. Check detailed beacon logs:")
            print("      sudo journalctl -u lighthouse-bn --since '1 hour ago'")
            print("   2. Verify disk space (beacon nodes need significant space):")
            print("      df -h")
            print("   3. Check memory usage:")
            print("      free -h && top -p $(pgrep lighthouse)")
            print("   4. Verify network connectivity:")
            print("      ping eth2-beacon-mainnet.infura.io")
        
        if not sepolia_results.get("reachable", False):
            self.colored_print("\n🔴 SEPOLIA RPC CONNECTION ISSUES:", "red", "bright")
            print("   Immediate actions:")
            print("   1. Check if Sepolia/Geth service is running:")
            print("      sudo systemctl status geth  # or your execution client")
            print("   2. Check execution client logs:")
            print("      sudo journalctl -u geth -f --no-pager")
            print("   3. Verify RPC port is open and bound correctly:")
            print("      sudo netstat -tlnp | grep 8545")
            print("   4. Test RPC locally:")
            print("      curl -X POST -H 'Content-Type: application/json' \\")
            print("           -d '{\"jsonrpc\":\"2.0\",\"method\":\"eth_chainId\",\"params\":[],\"id\":1}' \\")
            print("           http://localhost:8545")
            print("   5. Check if RPC is enabled with correct settings:")
            print("      # Geth should start with: --http --http.addr 0.0.0.0 --http.port 8545")
        
        # Sync-specific issues
        if beacon_results.get("reachable") and not beacon_results.get("synced"):
            self.colored_print("\n🟡 BEACON SYNC ISSUES:", "yellow", "bright")
            peer_count = beacon_results.get("peers", 0)
            if peer_count < 10:
                print("   Low peer count affecting sync:")
                print("   1. Check network connectivity and NAT settings")
                print("   2. Verify beacon node discovery settings")
                print("   3. Consider adding bootstrap nodes")
            print("   Monitor sync progress:")
            print("   curl -s http://localhost:5052/eth/v1/node/syncing | jq")
        
        if sepolia_results.get("reachable") and not sepolia_results.get("synced"):
            self.colored_print("\n🟡 SEPOLIA SYNC ISSUES:", "yellow", "bright")
            peer_count = sepolia_results.get("peers", 0)
            if peer_count < 5:
                print("   Low peer count affecting sync:")
                print("   1. Check execution client peer discovery")
                print("   2. Verify network connectivity")
                print("   3. Consider adding static peers")
            print("   Monitor sync progress:")
            print("   curl -X POST -H 'Content-Type: application/json' \\")
            print("        -d '{\"jsonrpc\":\"2.0\",\"method\":\"eth_syncing\",\"params\":[],\"id\":1}' \\")
            print("        http://localhost:8545")
        
        # Hardware-specific recommendations
        self.colored_print("\n💻 HARDWARE CONSIDERATIONS:", "blue", "bright")
        
        # Analyze performance metrics for hardware recommendations
        high_latency_detected = False
        avg_latencies = []
        
        for node_results in [beacon_results, sepolia_results]:
            for check_name, perf_data in node_results.get("performance", {}).items():
                if isinstance(perf_data, dict) and "avg_latency" in perf_data:
                    avg_latency = perf_data["avg_latency"]
                    avg_latencies.append(avg_latency)
                    if avg_latency > 1000:  # >1 second
                        high_latency_detected = True
        
        if high_latency_detected:
            print("   High latency detected - consider hardware upgrades:")
            print("   1. SSD storage (NVMe preferred for better I/O)")
            print("   2. More RAM (32GB+ recommended for full nodes)")
            print("   3. Better CPU (multi-core for better performance)")
            print("   4. Faster network connection")
        
        if avg_latencies:
            avg_overall_latency = statistics.mean(avg_latencies)
            if avg_overall_latency > 500:
                print(f"   Overall average latency: {avg_overall_latency:.0f}ms (consider optimization)")
            else:
                print(f"   Overall average latency: {avg_overall_latency:.0f}ms (acceptable)")
    
    def print_performance_recommendations(self, beacon_results, sepolia_results):
        """Print performance optimization recommendations"""
        self.colored_print("\n⚡ PERFORMANCE OPTIMIZATION:", "magenta", "bright")
        
        # Analyze all performance metrics
        all_latencies = []
        slow_operations = []
        
        for node_name, node_results in [("Beacon", beacon_results), ("Sepolia", sepolia_results)]:
            for check_name, perf_data in node_results.get("performance", {}).items():
                if isinstance(perf_data, dict) and "avg_latency" in perf_data:
                    latency = perf_data["avg_latency"]
                    all_latencies.append(latency)
                    
                    if latency > 2000:  # >2 seconds
                        slow_operations.append(f"{node_name} {check_name}: {latency:.0f}ms")
        
        if slow_operations:
            print("   Slow operations detected:")
            for op in slow_operations:
                print(f"   • {op}")
            print("\n   Optimization suggestions:")
            print("   1. Restart services to clear any memory issues")
            print("   2. Check for background processes consuming resources")
            print("   3. Monitor disk I/O: iotop -ao")
            print("   4. Consider increasing service resource limits")
        
        # Peer count optimization
        beacon_peers = beacon_results.get("peers", 0)
        sepolia_peers = sepolia_results.get("peers", 0)
        
        if beacon_peers < 20 or sepolia_peers < 10:
            print("   Peer connectivity optimization:")
            if beacon_peers < 20:
                print(f"   • Beacon peers ({beacon_peers}) below optimal (20+)")
            if sepolia_peers < 10:
                print(f"   • Sepolia peers ({sepolia_peers}) below optimal (10+)")
            print("   Suggestions:")
            print("   - Check NAT/firewall for P2P ports")
            print("   - Consider port forwarding for better connectivity")
            print("   - Add bootstrap/static nodes if available")
        
        # Block time analysis recommendations
        if "block_time_analysis" in sepolia_results:
            bta = sepolia_results["block_time_analysis"]
            if "last_block_age" in bta and bta["last_block_age"] > 30:
                print("   Block freshness optimization:")
                print(f"   • Last block is {bta['last_block_age']:.0f}s old")
                print("   • Consider sync status and peer connectivity")
        
        if all_latencies:
            avg_latency = statistics.mean(all_latencies)
            max_latency = max(all_latencies)
            
            print(f"\n   📊 Latency Summary:")
            print(f"   • Average: {avg_latency:.0f}ms")
            print(f"   • Maximum: {max_latency:.0f}ms")
            
            if avg_latency < 200:
                print("   • Status: Excellent performance! 🚀")
            elif avg_latency < 500:
                print("   • Status: Good performance ✅")
            elif avg_latency < 1000:
                print("   • Status: Acceptable performance ⚠️")
            else:
                print("   • Status: Performance needs improvement 🐌")

def main():
    parser = argparse.ArgumentParser(
        description="Enhanced Ethereum Node Health Checker - Professional monitoring with detailed diagnostics",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Quick check with default settings
  python3 eth_health_check.py
  
  # Check remote nodes with custom timeout
  python3 eth_health_check.py --beacon http://1.2.3.4:5052 --sepolia http://1.2.3.4:8545 --timeout 30
  
  # Thorough check with more retries
  python3 eth_health_check.py --retries 5 --timeout 20
  
  # Check only beacon node
  python3 eth_health_check.py --sepolia ""
  
  # Monitor mode (check every 60 seconds)
  python3 eth_health_check.py --monitor 60
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
                       help="Number of retry attempts (default: 3)")
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
            beacon_results = checker.check_beacon_node_enhanced(args.beacon)
        
        if args.sepolia:
            sepolia_results = checker.check_sepolia_rpc_enhanced(args.sepolia)
        
        # Print summary and determine overall health
        all_healthy = checker.print_enhanced_summary(beacon_results, sepolia_results)
        
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
