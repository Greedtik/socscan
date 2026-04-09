#!/bin/bash
# ==============================================================================
# SOC Scanner v20.1 (Ultimate Go-Bag Edition - Pure Bash)
# ==============================================================================
# Description: Lightweight, agentless Incident Response scanner for Linux.
# Features: Malware, RevShell, Ports, Users, Persistence, Docker, & CVE Online
# ==============================================================================

set -e
set -o pipefail

# ==========================================
# CONSTANTS & COLORS
# ==========================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# ==========================================
# UTILITIES & DETECTION
# ==========================================
cleanup() {
    echo -e "\n${YELLOW}[!] Scan interrupted. Cleaning up...${NC}"
    exit 1
}
trap cleanup SIGINT SIGTERM

detect_os() {
    if [ -f /etc/os-release ]; then
        source /etc/os-release
        OS_ID=$ID
        OS_NAME=$PRETTY_NAME
    else
        OS_ID="unknown"
        OS_NAME="Unknown Linux"
    fi
}

# ==========================================
# SCANNER MODULES
# ==========================================

malware_scan() {
    echo -e "\n${BLUE}[*] Starting Malware & Crypto Miner Scan...${NC}"
    
    local known_miners=("xmrig" "kdevtmpfsi" "kinsing" "sysupdate" "networkservice")
    echo -ne "    - Checking known miner processes... "
    local f=false
    for m in "${known_miners[@]}"; do
        if pgrep -f "$m" > /dev/null 2>&1; then
            echo -e "\n      ${RED}[FOUND ALERT]${NC} Miner detected: $m"; f=true
        fi
    done
    [ "$f" = false ] && echo -e "${GREEN}[OK]${NC}"

    echo -ne "    - Checking /tmp for hidden executables... "
    local tmp_execs=$(find /tmp /var/tmp -maxdepth 2 -type f -executable 2>/dev/null || true)
    if [ -n "$tmp_execs" ]; then
        echo -e "\n      ${RED}[FOUND ALERT]${NC} Suspicious files found in temp dirs:"
        echo "$tmp_execs" | sed 's/^/        -> /'
    else 
        echo -e "${GREEN}[OK]${NC}"
    fi
}

reverse_shell_scan() {
    echo -e "\n${BLUE}[*] Starting Reverse Shell Scan...${NC}"
    
    echo -ne "    - Checking network-connected shells... "
    local rev=$(ss -tap 2>/dev/null | grep -E "bash|sh|zsh" | grep "ESTAB" || true)
    if [ -n "$rev" ]; then
        echo -e "\n      ${RED}[FOUND ALERT]${NC} Active shell connection found:"
        echo "$rev" | sed 's/^/        -> /'
    else 
        echo -e "${GREEN}[OK]${NC}"
    fi
}

port_scan() {
    echo -e "\n${BLUE}[*] Starting Suspicious Port Scan...${NC}"
    
    local ports=(4444 31337 1337 666 4141 8888)
    local lp=$(ss -tulnp 2>/dev/null | awk '{print $5}' | awk -F':' '{print $NF}' | sort -u)
    
    echo -ne "    - Checking commonly abused ports... "
    local f=false
    for p in "${ports[@]}"; do
        if echo "$lp" | grep -qx "$p"; then
            if [ "$f" = false ]; then
                echo -e "\n      ${RED}[FOUND ALERT]${NC} Suspicious ports listening:"
                f=true
            fi
            
            local service_desc="Unknown / Custom Backdoor"
            case $p in
                4444) service_desc="Metasploit Default / Reverse Shell" ;;
                31337) service_desc="BackOrifice / Elite RAT" ;;
                1337) service_desc="Generic Hacker Port / RAT" ;;
                666) service_desc="Doom / Remote Administration Trojan" ;;
                4141) service_desc="Metasploit / Generic Shell" ;;
                8888) service_desc="Common Web Shell / C2 Port" ;;
            esac
            
            echo -e "        -> Port $p is OPEN! (Known for: ${YELLOW}$service_desc${NC})"
        fi
    done
    [ "$f" = false ] && echo -e "${GREEN}[OK]${NC}"
}

user_scan() {
    echo -e "\n${BLUE}[*] Starting Privileged Users Scan...${NC}"
    
    echo -ne "    - Checking non-root UID 0 accounts... "
    local u0=$(awk -F: '($3 == "0" && $1 != "root") {print $1}' /etc/passwd)
    if [ -n "$u0" ]; then
        echo -e "\n      ${RED}[FOUND ALERT]${NC} Rogue Admin Account: $u0"
    else 
        echo -e "${GREEN}[OK]${NC}"
    fi

    echo -ne "    - Checking for empty password accounts... "
    local ep=$(awk -F: '($2 == "") {print $1}' /etc/shadow 2>/dev/null || true)
    if [ -n "$ep" ]; then
        echo -e "\n      ${RED}[FOUND ALERT]${NC} No password set for user: $ep"
    else 
        echo -e "${GREEN}[OK]${NC}"
    fi
}

persistence_scan() {
    echo -e "\n${BLUE}[*] Starting Persistence Scan...${NC}"
    
    echo -ne "    - Checking suspicious Cron jobs... "
    local c=$(grep -Erw "curl|wget|base64|bash -i" /etc/cron* /var/spool/cron 2>/dev/null || true)
    if [ -n "$c" ]; then
        echo -e "\n      ${RED}[FOUND ALERT]${NC} Cron Backdoor found:"
        echo "$c" | head -n 3 | sed 's/^/        -> /'
    else 
        echo -e "${GREEN}[OK]${NC}"
    fi
}

docker_scan() {
    if ! command -v docker &> /dev/null; then return; fi
    echo -e "\n${BLUE}[*] Starting Container Scan...${NC}"
    
    echo -ne "    - Checking privileged containers... "
    local p=$(docker ps -q | xargs -I {} docker inspect --format='{{.Name}}:{{.HostConfig.Privileged}}' {} | grep "true" || true)
    if [ -n "$p" ]; then 
        echo -e "\n      ${RED}[FOUND ALERT]${NC} Privileged container: $p"
    else 
        echo -e "${GREEN}[OK]${NC}"
    fi
}

cve_scan() {
    echo -e "\n${PURPLE}[*] Starting Targeted CVE Online Scan (via OSV API)...${NC}"
    if ! command -v curl &> /dev/null; then echo -e "    ${YELLOW}[SKIP]${NC} curl not found"; return; fi
    
    if ! timeout 2 curl -s --head https://osv.dev > /dev/null; then
        echo -e "    ${YELLOW}[SKIP]${NC} No internet access or API unreachable."; return
    fi

    local pkg="sudo"
    local ver=""
    local update_cmd=""
    local eco="Debian"
    
    # 1. จับชื่อ OS และเวอร์ชันให้แม่นยำขึ้นเพื่อลด False Positive
    if [[ "$OS_ID" == "ubuntu" ]]; then
        local os_ver=$(grep VERSION_ID /etc/os-release | cut -d'"' -f2)
        eco="Ubuntu:$os_ver"
        ver=$(dpkg -s $pkg 2>/dev/null | grep Version | awk '{print $2}')
        update_cmd="apt-get update && apt-get install --only-upgrade $pkg"
    elif [[ "$OS_ID" == "debian" ]]; then
        local os_ver=$(grep VERSION_ID /etc/os-release | cut -d'"' -f2)
        eco="Debian:$os_ver"
        ver=$(dpkg -s $pkg 2>/dev/null | grep Version | awk '{print $2}')
        update_cmd="apt-get update && apt-get install --only-upgrade $pkg"
    elif [[ "$OS_ID" == *"centos"* || "$OS_ID" == *"rhel"* || "$OS_ID" == *"rocky"* ]]; then
        ver=$(rpm -q --queryformat '%{VERSION}-%{RELEASE}' $pkg 2>/dev/null)
        update_cmd="yum update $pkg"
    fi

    if [ -z "$ver" ]; then echo -e "    - Could not detect $pkg version."; return; fi

    echo -ne "    - Comparing $pkg v$ver (on $eco) with latest vulnerabilities... "
    
    local payload="{\"version\": \"$ver\", \"package\": {\"name\": \"$pkg\", \"ecosystem\": \"$eco\"}}"
    if [[ "$OS_ID" == *"rhel"* || "$OS_ID" == *"centos"* ]]; then payload=$(echo "$payload" | sed 's/Debian/RPM/'); fi

    local res=$(curl -s -X POST -d "$payload" https://api.osv.dev/v1/query)
    
    if [[ "$res" == *"{}"* || -z "$res" ]]; then
        echo -e "${GREEN}[SAFE]${NC} No known CVEs found for this version."
    else
        echo -e "\n      ${RED}[VULNERABLE]${NC} Potential CVEs found for $pkg."
        
        # --- THE ULTIMATE FIX: Pure Bash JSON Parser (No jq, No python needed) ---
        # ใช้ grep กับ cut ดึงแค่รหัส CVE ออกมาทั้งหมด
        local cves=$(echo "$res" | grep -o '"id":"[^"]*"' | cut -d'"' -f4 | sort -u | head -n 3)
        
        for cve in $cves; do
            local block=$(echo "$res" | grep -o "\"id\":\"$cve\".*")
            local desc=$(echo "$block" | grep -o '"summary":"[^"]*"' | head -n 1 | cut -d'"' -f4)
            
            if [ -z "$desc" ]; then
                desc=$(echo "$block" | grep -o '"details":"[^"]*"' | head -n 1 | cut -d'"' -f4 | cut -c 1-80)
                [ -n "$desc" ] && desc="${desc}..."
            fi
            
            [ -z "$desc" ] && desc="No details available."
            echo "        -> $cve: $desc"
        done
        
        echo -e "      ${GREEN}[REMEDIATION]${NC} To fix, run: ${YELLOW}sudo $update_cmd${NC}"
    fi
}

# ==========================================
# MAIN EXECUTION
# ==========================================
main() {
    detect_os
    local start_time=$(date +%s)

    echo "========================================"
    echo -e "${BLUE} SOC Scanner v20.1 (Ultimate Go-Bag)${NC}"
    echo -e " Host: ${YELLOW}$(hostname)${NC}"
    echo -e " OS:   $OS_NAME"
    echo -e " Date: $(date)"
    echo "========================================"

    if [[ $EUID -ne 0 ]]; then 
        echo -e "${RED}[!] Error: Must run as root to access all system processes.${NC}"
        exit 1
    fi

    malware_scan
    reverse_shell_scan
    port_scan
    user_scan
    persistence_scan
    docker_scan
    cve_scan

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    echo -e "\n========================================"
    echo -e "${GREEN}[+] Scan Complete in $duration seconds.${NC}"
    echo "========================================"
}

main "$@"
