#!/bin/bash

# Enhanced Ethereum Node Health Checker - Install Script
# Based on original install.sh with improvements for consistency and reliability

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
SCRIPT_NAME="eth-health-checker"
INSTALL_DIR="$HOME/.eth-health-checker"
VERSION="2.0.0"

echo -e "${BLUE}"
cat << "EOF"
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║        🚀 ENHANCED ETHEREUM NODE HEALTH CHECKER 🚀          ║
║                                                              ║
║   Professional monitoring with consistent results           ║
║   • Retry logic for reliable results                        ║
║   • Detailed problem diagnosis                              ║
║   • Performance metrics and analysis                        ║
║   • System resource monitoring                              ║
║   • Multiple monitoring modes                               ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_step() {
    echo -e "\n${BLUE}[STEP]${NC} $1"
}

# Check requirements
check_requirements() {
    print_step "Checking system requirements..."
    
    if command -v python3 &> /dev/null; then
        PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
        print_status "✅ Python 3 found (version $PYTHON_VERSION)"
    else
        print_error "❌ Python 3 required. Install with:"
        print_error "  Ubuntu/Debian: sudo apt install python3 python3-pip"
        print_error "  CentOS/RHEL: sudo yum install python3 python3-pip"
        exit 1
    fi
}

# Install dependencies with multiple fallback methods
install_dependencies() {
    print_step "Installing dependencies..."
    
    # Method 1: Try pip3 with --user
    if pip3 install --user requests colorama tabulate psutil &>/dev/null; then
        print_status "✅ Dependencies installed via pip3"
        return 0
    fi
    
    # Method 2: Try with --break-system-packages (for newer Python versions)
    print_warning "Trying alternative installation method..."
    if pip3 install --user --break-system-packages requests colorama tabulate psutil &>/dev/null; then
        print_status "✅ Dependencies installed (with --break-system-packages)"
        return 0
    fi
    
    # Method 3: Try system package manager
    print_warning "Trying system package manager..."
    if command -v apt &>/dev/null; then
        if sudo apt update &>/dev/null && sudo apt install -y python3-requests python3-colorama python3-psutil &>/dev/null; then
            print_status "✅ Dependencies installed via apt"
            return 0
        fi
    elif command -v yum &>/dev/null; then
        if sudo yum install -y python3-requests &>/dev/null; then
            print_status "✅ Basic dependencies installed via yum"
            return 0
        fi
    fi
    
    # Method 4: Continue without optional dependencies
    print_warning "⚠️ Could not install colorama/tabulate/psutil (optional dependencies)"
    print_warning "⚠️ Health checker will work but without colors/tables/system monitoring"
    print_status "✅ Continuing installation..."
    return 0
}

# Create installation directory
create_install_dir() {
    print_step "Setting up installation..."
    rm -rf "$INSTALL_DIR" 2>/dev/null || true
    mkdir -p "$INSTALL_DIR"
    print_status "✅ Installation directory ready"
}

# Download main script from GitHub or use embedded version
download_script() {
    print_step "Setting up health checker..."
    
    # Try to download from GitHub
    GITHUB_USER="Aabis5004"
    SCRIPT_URL="https://raw.githubusercontent.com/${GITHUB_USER}/eth-node-health-checker/main/eth_health_check.py"
    
    # Try downloading with curl or wget
    if command -v curl >/dev/null 2>&1; then
        if curl -fsSL "$SCRIPT_URL" -o "$INSTALL_DIR/eth_health_check.py" 2>/dev/null; then
            print_status "✅ Downloaded from GitHub"
            chmod +x "$INSTALL_DIR/eth_health_check.py"
            return 0
        fi
    elif command -v wget >/dev/null 2>&1; then
        if wget -q "$SCRIPT_URL" -O "$INSTALL_DIR/eth_health_check.py" 2>/dev/null; then
            print_status "✅ Downloaded from GitHub"
            chmod +x "$INSTALL_DIR/eth_health_check.py"
            return 0
        fi
    fi
    
    # Fallback to embedded script
    print_warning "GitHub download failed, using embedded version"
    create_embedded_script
}

# Embedded script as fallback
create_embedded_script() {
    cat > "$INSTALL_DIR/eth_health_check.py" << 'SCRIPT_EOF'
#!/usr/bin/env python3
"""Enhanced Ethereum Node Health Checker - Professional monitoring tool"""

import requests
import json
import socket
import sys
import argparse
import time
import statistics
from datetime import datetime

# Check for optional dependencies
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
        
    def colored_print(self, message, color="white"):
        """Print colored text if available, otherwise plain text"""
        if not HAS_COLOR:
            print(message)
            return
        colors = {
            "red": Fore.RED, "green": Fore.GREEN, "yellow": Fore.YELLOW, 
            "blue": Fore.BLUE, "cyan": Fore.CYAN, "white": Fore.WHITE, "magenta": Fore.MAGENTA
        }
        print(f"{colors.get(color, Fore.WHITE)}{message}{Style.RESET_ALL}")
    
    def log_result(self, message, status="info", details=None):
        """Log a result with timestamp and status"""
        timestamp = datetime.now().strftime("%H:%M:%S")
        icons = {"success": "✅", "error": "❌", "warning": "⚠️", "info": "ℹ️", "performance": "⚡"}
        colors = {"success": "green", "error": "red", "warning": "yellow", "info": "blue", "performance": "magenta"}
        
        icon = icons.get(status, "•")
        color = colors.get(status, "white")
        
        self.colored_print(f"[{timestamp}] {icon} {message}", color)
        if details:
            for detail in details:
                self.colored_print(f"    └─ {detail}", "white")
    
    def test_connection_advanced(self, host, port):
        """Test TCP connection with retries"""
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
                attempts.append({'success': result == 0, 'latency': latency, 'attempt': attempt + 1})
                if result == 0:
                    time.sleep(0.1)
            except Exception as e:
                end_time = time.time()
                latency = (end_time - start_time) * 1000
                attempts.append({'success': False, 'latency': latency, 'attempt': attempt + 1, 'error': str(e)})
        return attempts
    
    def make_request_with_retry(self, method, url, **kwargs):
        """Make HTTP request with retry logic"""
        latencies = []
        errors = []
        for attempt in range(self.retries):
            start_time = time.time()
            try:
                if method.upper() == 'GET':
                    response = requests.get(url, timeout=self.timeout, **kwargs)
                elif method.upper() == 'POST':
                    response = requests.post(url, timeout=self.timeout, **kwargs)
                end_time = time.time()
                latency = (end_time - start_time) * 1000
                latencies.append(latency)
                if response.status_code == 200:
                    return response, {
                        'latencies': latencies, 'avg_latency': statistics.mean(latencies),
                        'attempts': attempt + 1, 'errors': errors
                    }
                else:
                    errors.append(f"HTTP {response.status_code}")
            except Exception as e:
                end_time = time.time()
                latency = (end_time - start_time) * 1000
                latencies.append(latency)
                errors.append(str(e))
                if attempt < self.retries - 1:
                    time.sleep(0.5)
        return None, {
            'latencies': latencies, 'avg_latency': statistics.mean(latencies) if latencies else 0,
            'attempts': self.retries, 'errors': errors
        }
    
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
    
    def diagnose_connection_issues(self, host, port, attempts):
        """Diagnose connection issues"""
        successful = [a for a in attempts if a['success']]
        if not successful:
            avg_latency = statistics.mean([a['latency'] for a in attempts])
            if avg_latency > (self.timeout * 1000 * 0.9):
                return "critical", [
                    "Connection timeout - service likely not running",
                    f"Check: sudo systemctl status [service-name]",
                    f"Check: sudo netstat -tlnp | grep {port}"
                ]
            else:
                return "error", [
                    "Port closed or service not responding",
                    f"Check: sudo ufw status (firewall on port {port})",
                    "Check: Service configuration and binding address"
                ]
        else:
            success_rate = len(successful) / len(attempts) * 100
            avg_latency = statistics.mean([a['latency'] for a in successful])
            if success_rate < 100:
                return "warning", [f"Intermittent connectivity ({success_rate:.0f}% success rate)"]
            elif avg_latency > 1000:
                return "warning", [f"High latency: {avg_latency:.0f}ms - consider hardware upgrade"]
            else:
                return "success", [f"Connection stable (latency: {avg_latency:.0f}ms)"]
    
    def check_system_resources(self):
        """Check system resources if psutil available"""
        if not HAS_PSUTIL:
            self.log_result("System monitoring unavailable (install psutil for system checks)", "warning")
            return
        try:
            cpu_percent = psutil.cpu_percent(interval=1)
            memory = psutil.virtual_memory()
            disk = psutil.disk_usage('/')
            
            self.log_result(f"CPU: {cpu_percent:.1f}%, Memory: {memory.percent:.1f}%, Disk: {disk.percent:.1f}%", "info")
            
            if cpu_percent > 90 or memory.percent > 90 or disk.percent > 95:
                self.log_result("High resource usage detected - may affect node performance", "warning")
        except Exception as e:
            self.log_result(f"Could not check system resources: {e}", "warning")
    
    def check_beacon_node(self, url):
        """Enhanced Beacon node check"""
        self.colored_print("\n📋 BEACON CHAIN NODE", "yellow")
        self.colored_print("-" * 20, "yellow")
        
        host, port = self.parse_url(url, 5052)
        if not host:
            self.log_result(f"Invalid URL: {url}", "error")
            return {"reachable": False, "healthy": False, "issues": ["Invalid URL"]}
        
        beacon_results = {"reachable": False, "healthy": False, "synced": False, "peers": 0, "issues": []}
        
        # Test connection with diagnosis
        self.log_result("Testing beacon connection stability...", "info")
        attempts = self.test_connection_advanced(host, port)
        status, details = self.diagnose_connection_issues(host, port, attempts)
        self.log_result(f"Connection analysis complete", status, details)
        
        if not any(attempt['success'] for attempt in attempts):
            beacon_results["issues"].extend(details)
            return beacon_results
        
        beacon_results["reachable"] = True
        
        # Test health endpoint
        response, perf_data = self.make_request_with_retry('GET', f"{url}/eth/v1/node/health")
        if response and response.status_code == 200:
            beacon_results["healthy"] = True
            self.log_result("Beacon node is healthy", "success")
            self.log_result(f"Health check latency: {perf_data['avg_latency']:.0f}ms", "performance")
            
            # Check sync status
            sync_response, _ = self.make_request_with_retry('GET', f"{url}/eth/v1/node/syncing")
            if sync_response and sync_response.status_code == 200:
                try:
                    sync_data = sync_response.json()
                    is_syncing = sync_data.get("data", {}).get("is_syncing", True)
                    if not is_syncing:
                        beacon_results["synced"] = True
                        self.log_result("Beacon node is fully synced", "success")
                    else:
                        self.log_result("Beacon node is syncing", "warning")
                        sync_distance = sync_data.get("data", {}).get("sync_distance", 0)
                        if sync_distance > 100:
                            beacon_results["issues"].append(f"Syncing behind by {sync_distance} slots")
                except Exception:
                    pass
            
            # Check peers
            peers_response, _ = self.make_request_with_retry('GET', f"{url}/eth/v1/node/peers")
            if peers_response and peers_response.status_code == 200:
                try:
                    peers_data = peers_response.json()
                    peer_count = len(peers_data.get("data", []))
                    beacon_results["peers"] = peer_count
                    
                    if peer_count >= 20:
                        self.log_result(f"Excellent peer connectivity: {peer_count} peers", "success")
                    elif peer_count >= 10:
                        self.log_result(f"Good peer connectivity: {peer_count} peers", "success")
                    elif peer_count >= 3:
                        self.log_result(f"Minimal peer connectivity: {peer_count} peers", "warning")
                        beacon_results["issues"].append("Low peer count may affect sync performance")
                    else:
                        self.log_result(f"Poor peer connectivity: {peer_count} peers", "error")
                        beacon_results["issues"].append("Very low peer count - check network connectivity")
                except Exception:
                    pass
        else:
            error_details = [f"Health endpoint failed after {perf_data['attempts']} attempts"]
            self.log_result("Beacon health check failed", "error", error_details)
            beacon_results["issues"].extend(error_details)
        
        return beacon_results
    
    def check_sepolia_rpc(self, url):
        """Enhanced Sepolia RPC check"""
        self.colored_print("\n📋 SEPOLIA RPC NODE", "yellow")
        self.colored_print("-" * 18, "yellow")
        
        host, port = self.parse_url(url, 8545)
        if not host:
            self.log_result(f"Invalid URL: {url}", "error")
            return {"reachable": False, "issues": ["Invalid URL"]}
        
        sepolia_results = {"reachable": False, "synced": False, "chain_id": 0, "latest_block": 0, "peers": 0, "issues": []}
        
        # Test connection with diagnosis
        self.log_result("Testing RPC connection stability...", "info")
        attempts = self.test_connection_advanced(host, port)
        status, details = self.diagnose_connection_issues(host, port, attempts)
        self.log_result(f"RPC connection analysis complete", status, details)
        
        if not any(attempt['success'] for attempt in attempts):
            sepolia_results["issues"].extend(details)
            return sepolia_results
        
        sepolia_results["reachable"] = True
        
        # Test chain ID
        payload = {"jsonrpc": "2.0", "method": "eth_chainId", "params": [], "id": 1}
        response, perf_data = self.make_request_with_retry('POST', url, json=payload)
        
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
                
                # Test latest block
                block_payload = {"jsonrpc": "2.0", "method": "eth_blockNumber", "params": [], "id": 1}
                block_response, block_perf = self.make_request_with_retry('POST', url, json=block_payload)
                if block_response and block_response.status_code == 200:
                    block_hex = block_response.json().get("result", "0x0")
                    latest_block = int(block_hex, 16)
                    sepolia_results["latest_block"] = latest_block
                    self.log_result(f"Latest block: {latest_block:,}", "success")
                    self.log_result(f"Block query latency: {block_perf['avg_latency']:.0f}ms", "performance")
                
                # Check sync status
                sync_payload = {"jsonrpc": "2.0", "method": "eth_syncing", "params": [], "id": 1}
                sync_response, _ = self.make_request_with_retry('POST', url, json=sync_payload)
                if sync_response and sync_response.status_code == 200:
                    sync_result = sync_response.json().get("result")
                    if sync_result is False:
                        sepolia_results["synced"] = True
                        self.log_result("Sepolia node is fully synced", "success")
                    else:
                        self.log_result("Sepolia node is syncing", "warning")
                        if isinstance(sync_result, dict):
                            current_block = int(sync_result.get("currentBlock", "0x0"), 16)
                            highest_block = int(sync_result.get("highestBlock", "0x0"), 16)
                            blocks_behind = highest_block - current_block
                            if blocks_behind > 1000:
                                sepolia_results["issues"].append(f"Syncing: {blocks_behind:,} blocks behind")
                
                # Check peers
                peer_payload = {"jsonrpc": "2.0", "method": "net_peerCount", "params": [], "id": 1}
                peer_response, _ = self.make_request_with_retry('POST', url, json=peer_payload)
                if peer_response and peer_response.status_code == 200:
                    peer_hex = peer_response.json().get("result", "0x0")
                    peer_count = int(peer_hex, 16)
                    sepolia_results["peers"] = peer_count
                    
                    if peer_count >= 10:
                        self.log_result(f"Good peer connectivity: {peer_count} peers", "success")
                    elif peer_count >= 3:
                        self.log_result(f"Minimal peer connectivity: {peer_count} peers", "warning")
                        sepolia_results["issues"].append("Low peer count may affect sync performance")
                    else:
                        self.log_result(f"Poor peer connectivity: {peer_count} peers", "error")
                        sepolia_results["issues"].append("Very low peer count - check network connectivity")
                
            except Exception as e:
                self.log_result(f"Error parsing RPC response: {e}", "error")
                sepolia_results["issues"].append(f"RPC parsing error: {e}")
        else:
            error_details = [f"RPC check failed after {perf_data['attempts']} attempts"]
            self.log_result("Sepolia RPC check failed", "error", error_details)
            sepolia_results["issues"].extend(error_details)
        
        return sepolia_results
    
    def print_summary(self, beacon_results, sepolia_results):
        """Print comprehensive summary"""
        self.colored_print("\n📊 HEALTH SUMMARY", "cyan")
        self.colored_print("-" * 16, "cyan")
        
        beacon_healthy = beacon_results.get("reachable", False) and beacon_results.get("healthy", False)
        sepolia_healthy = sepolia_results.get("reachable", False)
        
        # Status
        if beacon_healthy:
            if beacon_results.get("synced", False):
                self.colored_print("🟢 Beacon Chain: OPTIMAL (healthy & synced)", "green")
            else:
                self.colored_print("🟡 Beacon Chain: FUNCTIONAL (healthy, syncing)", "yellow")
        else:
            self.colored_print("🔴 Beacon Chain: CRITICAL (offline/unhealthy)", "red")
        
        if sepolia_healthy:
            if sepolia_results.get("synced", False):
                self.colored_print("🟢 Sepolia RPC: OPTIMAL (reachable & synced)", "green")
            else:
                self.colored_print("🟡 Sepolia RPC: FUNCTIONAL (reachable, syncing)", "yellow")
        else:
            self.colored_print("🔴 Sepolia RPC: CRITICAL (unreachable)", "red")
        
        # Metrics
        self.colored_print("\n📈 KEY METRICS:", "blue")
        print(f"   • Beacon Peers: {beacon_results.get('peers', 'N/A')}")
        print(f"   • Sepolia Peers: {sepolia_results.get('peers', 'N/A')}")
        print(f"   • Chain ID: {sepolia_results.get('chain_id', 'N/A')}")
        latest_block = sepolia_results.get('latest_block', 'N/A')
        if isinstance(latest_block, int):
            print(f"   • Latest Block: {latest_block:,}")
        else:
            print(f"   • Latest Block: {latest_block}")
        
        # Issues and quick fixes
        all_issues = beacon_results.get("issues", []) + sepolia_results.get("issues", [])
        if all_issues:
            self.colored_print("\n🚨 IDENTIFIED ISSUES:", "red")
            for i, issue in enumerate(all_issues, 1):
                self.colored_print(f"   {i}. {issue}", "red")
            
            self.colored_print("\n🔧 QUICK FIXES:", "yellow")
            if not beacon_results.get("reachable", False):
                print("   Beacon Issues:")
                print("   • sudo systemctl status lighthouse-bn")
                print("   • sudo systemctl restart lighthouse-bn")
                print("   • sudo ufw allow 5052")
            
            if not sepolia_results.get("reachable", False):
                print("   Sepolia Issues:")
                print("   • sudo systemctl status geth")
                print("   • sudo systemctl restart geth")
                print("   • sudo ufw allow 8545")
        
        return beacon_healthy and sepolia_healthy

def main():
    parser = argparse.ArgumentParser(description="Enhanced Ethereum Node Health Checker")
    parser.add_argument("--beacon", default="http://localhost:5052", help="Beacon node URL")
    parser.add_argument("--sepolia", default="http://localhost:8545", help="Sepolia RPC URL")
    parser.add_argument("--timeout", type=int, default=15, help="Timeout in seconds")
    parser.add_argument("--retries", type=int, default=3, help="Number of retries for consistency")
    parser.add_argument("--monitor", type=int, help="Monitor mode: check every N seconds")
    parser.add_argument("--no-system-check", action="store_true", help="Skip system resource check")
    args = parser.parse_args()
    
    def run_check():
        checker = EnhancedNodeHealthChecker(timeout=args.timeout, retries=args.retries)
        
        checker.colored_print("\n" + "="*60, "blue")
        checker.colored_print("🚀 ENHANCED ETHEREUM NODE HEALTH CHECKER v2.0", "cyan")
        checker.colored_print("Professional monitoring with consistent results", "white")
        checker.colored_print("="*60, "blue")
        
        if not args.no_system_check:
            checker.colored_print("\n📊 SYSTEM CHECK", "yellow")
            checker.colored_print("-" * 14, "yellow")
            checker.check_system_resources()
        
        beacon_results = {}
        sepolia_results = {}
        
        if args.beacon:
            beacon_results = checker.check_beacon_node(args.beacon)
        if args.sepolia:
            sepolia_results = checker.check_sepolia_rpc(args.sepolia)
        
        all_healthy = checker.print_summary(beacon_results, sepolia_results)
        
        checker.colored_print("\n" + "="*60, "blue")
        current_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        
        if all_healthy:
            checker.colored_print(f"🎉 All systems healthy! Last checked: {current_time}", "green")
        else:
            checker.colored_print(f"⚠️ Issues detected. Last checked: {current_time}", "yellow")
        checker.colored_print("="*60, "blue")
        
        return all_healthy
    
    if args.monitor:
        print(f"🔄 Monitor mode: checking every {args.monitor} seconds")
        print("Press Ctrl+C to stop monitoring")
        try:
            while True:
                run_check()
                if args.monitor > 30:
                    for remaining in range(args.monitor, 0, -1):
                        print(f"\r⏱️  Next check in {remaining} seconds... ", end="", flush=True)
                        time.sleep(1)
                    print()
                else:
                    time.sleep(args.monitor)
        except KeyboardInterrupt:
            print("\n🛑 Monitoring stopped")
    else:
        healthy = run_check()
        sys.exit(0 if healthy else 1)

if __name__ == "__main__":
    main()
SCRIPT_EOF

    chmod +x "$INSTALL_DIR/eth_health_check.py"
    print_status "✅ Enhanced health checker ready"
}

# Create wrapper command
create_wrapper() {
    print_step "Creating easy commands..."
    
    # Main wrapper command
    cat > "$INSTALL_DIR/check-nodes" << 'WRAPPER_EOF'
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
python3 "$SCRIPT_DIR/eth_health_check.py" "$@"
WRAPPER_EOF
    
    # Quick check command  
    cat > "$INSTALL_DIR/quick-check" << 'QUICK_EOF'
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "🚀 Quick Node Health Check"
python3 "$SCRIPT_DIR/eth_health_check.py" --timeout 10 --retries 2 --no-system-check
QUICK_EOF
    
    # Monitor command
    cat > "$INSTALL_DIR/monitor-nodes" << 'MONITOR_EOF'
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INTERVAL=${1:-60}
echo "🔄 Starting node monitoring (interval: ${INTERVAL}s)"
echo "Press Ctrl+C to stop"
python3 "$SCRIPT_DIR/eth_health_check.py" --monitor "$INTERVAL"
MONITOR_EOF
    
    # Diagnostic command
    cat > "$INSTALL_DIR/diagnose-nodes" << 'DIAGNOSE_EOF'
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "🔧 Comprehensive Node Diagnostics"
python3 "$SCRIPT_DIR/eth_health_check.py" --timeout 30 --retries 5
DIAGNOSE_EOF
    
    chmod +x "$INSTALL_DIR/check-nodes"
    chmod +x "$INSTALL_DIR/quick-check"
    chmod +x "$INSTALL_DIR/monitor-nodes"
    chmod +x "$INSTALL_DIR/diagnose-nodes"
    
    print_status "✅ Command tools created:"
    print_status "   • check-nodes (full diagnostics)"
    print_status "   • quick-check (fast check)"
    print_status "   • monitor-nodes [interval] (continuous monitoring)"
    print_status "   • diagnose-nodes (thorough analysis)"
}

# Add to PATH and create convenience functions
setup_path_and_aliases() {
    print_step "Setting up PATH and convenience functions..."
    
    # Add to PATH if not already there
    if [[ ":$PATH:" != *":$HOME/.eth-health-checker:"* ]]; then
        echo 'export PATH="$HOME/.eth-health-checker:$PATH"' >> "$HOME/.bashrc"
        print_status "✅ Added to PATH in .bashrc"
    fi
    
    # Create convenience functions in .bashrc
    if ! grep -q "# Ethereum Health Checker Functions" "$HOME/.bashrc" 2>/dev/null; then
        cat >> "$HOME/.bashrc" << 'FUNCTIONS_EOF'

# Ethereum Health Checker Functions
alias eth-status='check-nodes'
alias eth-quick='quick-check'
alias eth-monitor='monitor-nodes'
alias eth-diagnose='diagnose-nodes'

# Function for custom node checking
eth-check() {
    if [[ $# -eq 0 ]]; then
        check-nodes
    elif [[ $# -eq 2 ]]; then
        check-nodes --beacon "$1" --sepolia "$2"
    else
        echo "Usage: eth-check [beacon_url sepolia_url]"
        echo "Example: eth-check http://192.168.1.100:5052 http://192.168.1.100:8545"
    fi
}

# Function for remote monitoring
eth-remote() {
    if [[ $# -ne 1 ]]; then
        echo "Usage: eth-remote <server_ip>"
        echo "Example: eth-remote 192.168.1.100"
        return 1
    fi
    
    local SERVER_IP="$1"
    echo "🌐 Checking remote Ethereum nodes on $SERVER_IP"
    check-nodes --beacon "http://$SERVER_IP:5052" --sepolia "http://$SERVER_IP:8545"
}
FUNCTIONS_EOF
        print_status "✅ Added convenience functions and aliases"
    fi
}

# Create uninstaller
create_uninstaller() {
    cat > "$INSTALL_DIR/uninstall" << 'UNINSTALL_EOF'
#!/bin/bash
echo "🗑️ Uninstalling Enhanced Ethereum Node Health Checker..."

# Remove from .bashrc
if [[ -f "$HOME/.bashrc" ]]; then
    # Remove PATH addition
    sed -i '/eth-health-checker/d' "$HOME/.bashrc" 2>/dev/null || true
    
    # Remove convenience functions
    sed -i '/# Ethereum Health Checker Functions/,/^$/d' "$HOME/.bashrc" 2>/dev/null || true
    
    echo "✅ Removed from .bashrc"
fi

# Remove installation directory
rm -rf "$HOME/.eth-health-checker"

echo "✅ Uninstalled successfully!"
echo ""
echo "Note: Restart your terminal or run 'source ~/.bashrc' to update your environment"
echo "The following packages were installed and can be removed manually if desired:"
echo "  pip3 uninstall requests colorama tabulate psutil"
UNINSTALL_EOF
    
    chmod +x "$INSTALL_DIR/uninstall"
}

# Print usage examples
print_usage_examples() {
    print_step "Installation Complete! 🎉"
    echo ""
    print_status "🎯 QUICK START:"
    echo "1. Restart your terminal (or run: source ~/.bashrc)"
    echo "2. Test local nodes: check-nodes"
    echo "3. Quick check: quick-check"
    echo "4. Monitor continuously: monitor-nodes 60"
    echo ""
    
    print_status "🌐 REMOTE MONITORING:"
    echo "• Check remote server: eth-remote 192.168.1.100"
    echo "• Custom URLs: eth-check http://IP:5052 http://IP:8545"
    echo ""
    
    print_status "🔧 DIAGNOSTICS:"
    echo "• Thorough analysis: diagnose-nodes"
    echo "• Custom settings: check-nodes --timeout 30 --retries 5"
    echo "• Monitor mode: check-nodes --monitor 120"
    echo ""
    
    print_status "📋 ALIASES & FUNCTIONS:"
    echo "• eth-status (same as check-nodes)"
    echo "• eth-quick (fast check)"
    echo "• eth-monitor (continuous monitoring)"
    echo "• eth-diagnose (thorough analysis)"
    echo "• eth-remote <ip> (check remote nodes)"
    echo ""
    
    print_status "🆘 HELP & SUPPORT:"
    echo "• Get help: check-nodes --help"
    echo "• Uninstall: ~/.eth-health-checker/uninstall"
    echo ""
    
    print_status "📁 Installed to: $INSTALL_DIR"
    print_status "🗑️ To uninstall: $INSTALL_DIR/uninstall"
}

# Main installation
main() {
    check_requirements
    install_dependencies
    create_install_dir
    download_script
    create_wrapper
    setup_path_and_aliases
    create_uninstaller
    
    print_usage_examples
    
    echo ""
    print_status "🚀 Ready to monitor your Ethereum nodes with enhanced diagnostics!"
    print_warning "💡 Restart your terminal or run: source ~/.bashrc"
}

main "$@"
