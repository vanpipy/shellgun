#!/bin/bash

# Hacker Self-Exploration Mission - Security Reconnaissance Script
# Date: 2026-02-26
# Target: Current device (iZ2zedf3ol9okhg02pvpynZ)

echo "================================================"
echo "HACKER SELF-EXPLORATION MISSION"
echo "Security Reconnaissance Report"
echo "Date: $(date)"
echo "Target: $(hostname)"
echo "================================================"

REPORT_DIR="/home/admin/.openclaw/workspace-hacker/shellgun-new/report/DetectYouself"
mkdir -p $REPORT_DIR

# Function to log output
log() {
    echo "$1" | tee -a $REPORT_DIR/reconnaissance.log
}

log "Starting security reconnaissance at $(date)"
log ""

# 1. ATTACK SURFACE ANALYSIS
log "=== 1. ATTACK SURFACE ANALYSIS ==="
log ""

log "1.1 Network Interfaces:"
ip addr show | tee -a $REPORT_DIR/network_interfaces.txt
log ""

log "1.2 Open Ports (netstat):"
netstat -tulpn 2>/dev/null | tee -a $REPORT_DIR/open_ports_netstat.txt
log ""

log "1.3 Open Ports (ss):"
ss -tulpn | tee -a $REPORT_DIR/open_ports_ss.txt
log ""

log "1.4 Listening Services:"
sudo lsof -i -P -n | grep LISTEN 2>/dev/null | tee -a $REPORT_DIR/listening_services.txt
log ""

log "1.5 Service Versions (critical services):"
log "SSH Version:"
sshd -V 2>&1 | head -1 | tee -a $REPORT_DIR/service_versions.txt
log ""
log "Nginx/Apache (if installed):"
which nginx && nginx -v 2>&1 | tee -a $REPORT_DIR/service_versions.txt
which apache2 && apache2 -v 2>&1 | tee -a $REPORT_DIR/service_versions.txt
log ""

# 2. PRIVILEGE ESCALATION PATHS
log "=== 2. PRIVILEGE ESCALATION ANALYSIS ==="
log ""

log "2.1 Current User Privileges:"
id | tee -a $REPORT_DIR/user_privileges.txt
sudo -l 2>/dev/null | tee -a $REPORT_DIR/sudo_privileges.txt
log ""

log "2.2 SUID Binaries:"
find / -type f -perm -4000 -ls 2>/dev/null | head -50 | tee -a $REPORT_DIR/suid_binaries.txt
log ""

log "2.3 SGID Binaries:"
find / -type f -perm -2000 -ls 2>/dev/null | head -50 | tee -a $REPORT_DIR/sgid_binaries.txt
log ""

log "2.4 World-Writable Files:"
find / -type f -perm -0002 ! -path "/proc/*" ! -path "/sys/*" 2>/dev/null | head -50 | tee -a $REPORT_DIR/world_writable_files.txt
log ""

log "2.5 Cron Jobs:"
crontab -l 2>/dev/null | tee -a $REPORT_DIR/cron_jobs.txt
ls -la /etc/cron* 2>/dev/null | tee -a $REPORT_DIR/cron_directories.txt
log ""

# 3. PERSISTENCE OPPORTUNITIES
log "=== 3. PERSISTENCE ANALYSIS ==="
log ""

log "3.1 Startup Scripts:"
ls -la /etc/init.d/ 2>/dev/null | tee -a $REPORT_DIR/init_scripts.txt
ls -la /etc/systemd/system/ 2>/dev/null | tee -a $REPORT_DIR/systemd_services.txt
log ""

log "3.2 User Autostart:"
ls -la ~/.config/autostart/ 2>/dev/null | tee -a $REPORT_DIR/user_autostart.txt
log ""

log "3.3 SSH Authorized Keys:"
ls -la ~/.ssh/ 2>/dev/null | tee -a $REPORT_DIR/ssh_keys.txt
cat ~/.ssh/authorized_keys 2>/dev/null | tee -a $REPORT_DIR/authorized_keys.txt
log ""

# 4. DATA TREASURE HUNT
log "=== 4. DATA TREASURE HUNT ==="
log ""

log "4.1 Interesting Files:"
find /home -name "*.txt" -o -name "*.md" -o -name "*.conf" -o -name "*.config" 2>/dev/null | head -30 | tee -a $REPORT_DIR/interesting_files.txt
log ""

log "4.2 Backup Files:"
find / -name "*backup*" -o -name "*bak*" -o -name "*.old" 2>/dev/null | head -30 | tee -a $REPORT_DIR/backup_files.txt
log ""

log "4.3 Log Files (recent):"
find /var/log -type f -mtime -7 2>/dev/null | head -20 | tee -a $REPORT_DIR/recent_logs.txt
log ""

log "4.4 Configuration Files:"
ls -la /etc/*.conf 2>/dev/null | tee -a $REPORT_DIR/config_files.txt
log ""

# 5. DEFENSE EVASION ANALYSIS
log "=== 5. DEFENSE EVASION ANALYSIS ==="
log ""

log "5.1 Security Tools:"
which fail2ban 2>/dev/null | tee -a $REPORT_DIR/security_tools.txt
which ufw 2>/dev/null | tee -a $REPORT_DIR/security_tools.txt
which iptables 2>/dev/null | tee -a $REPORT_DIR/security_tools.txt
log ""

log "5.2 Firewall Rules:"
sudo iptables -L -n 2>/dev/null | tee -a $REPORT_DIR/firewall_rules.txt
log ""

log "5.3 SELinux/AppArmor Status:"
sestatus 2>/dev/null | tee -a $REPORT_DIR/selinux_status.txt
aa-status 2>/dev/null | tee -a $REPORT_DIR/apparmor_status.txt
log ""

log "5.4 Audit Logs:"
which auditd 2>/dev/null | tee -a $REPORT_DIR/audit_tools.txt
log ""

log "5.5 Process Monitoring:"
ps aux | grep -E "(audit|tripwire|ossec|aide|rkhunter|chkrootkit)" 2>/dev/null | tee -a $REPORT_DIR/process_monitoring.txt
log ""

# 6. SYSTEM INFORMATION
log "=== 6. SYSTEM INFORMATION ==="
log ""

log "6.1 Kernel Information:"
uname -a | tee -a $REPORT_DIR/system_info.txt
log ""

log "6.2 OS Release:"
cat /etc/os-release | tee -a $REPORT_DIR/os_release.txt
log ""

log "6.3 Disk Usage:"
df -h | tee -a $REPORT_DIR/disk_usage.txt
log ""

log "6.4 Memory Info:"
free -h | tee -a $REPORT_DIR/memory_info.txt
log ""

log "6.5 CPU Info:"
lscpu | head -20 | tee -a $REPORT_DIR/cpu_info.txt
log ""

log "6.6 Running Processes:"
ps aux --sort=-%cpu | head -20 | tee -a $REPORT_DIR/top_processes.txt
log ""

log "================================================"
log "Reconnaissance completed at $(date)"
log "Report saved to: $REPORT_DIR"
log "================================================"