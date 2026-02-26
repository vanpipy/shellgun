#!/bin/bash
# ============================================================================
# 系统安全加固脚本
# 版本: 1.0
# 生成时间: 2026-02-26 08:10 GMT+8
# 生成会话: agent:hacker:main
# 目标系统: Alibaba Cloud Linux 3.2104 U12.3
# ============================================================================

set -e  # 遇到错误立即退出
set -u  # 使用未定义变量时报错

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 审计日志文件
AUDIT_LOG="/var/log/security-hardening-audit.log"
BACKUP_DIR="/root/security-backups-$(date +%Y%m%d_%H%M%S)"

# ============================================================================
# 1. 初始化检查
# ============================================================================
initialize() {
    log_info "开始系统安全加固"
    log_info "系统信息: $(uname -a)"
    log_info "当前用户: $(whoami)"
    log_info "工作目录: $(pwd)"
    
    # 创建备份目录
    mkdir -p "$BACKUP_DIR"
    log_info "备份目录创建: $BACKUP_DIR"
    
    # 创建审计日志
    echo "=== 安全加固审计日志 ===" > "$AUDIT_LOG"
    echo "开始时间: $(date)" >> "$AUDIT_LOG"
    echo "系统: $(uname -a)" >> "$AUDIT_LOG"
    echo "用户: $(whoami)" >> "$AUDIT_LOG"
    echo "" >> "$AUDIT_LOG"
}

# ============================================================================
# 2. 防火墙配置
# ============================================================================
configure_firewall() {
    log_info "配置防火墙..."
    
    # 备份当前配置
    if systemctl is-active firewalld >/dev/null 2>&1; then
        sudo firewall-cmd --list-all > "$BACKUP_DIR/firewalld-backup.txt"
    fi
    
    # 启用并配置防火墙
    sudo systemctl enable firewalld
    sudo systemctl start firewalld
    
    # 添加SSH服务
    sudo firewall-cmd --permanent --add-service=ssh
    sudo firewall-cmd --reload
    
    # 验证配置
    if sudo firewall-cmd --state | grep -q "running"; then
        log_success "防火墙已启用并运行"
        echo "防火墙状态: 运行中" >> "$AUDIT_LOG"
        echo "允许服务: $(sudo firewall-cmd --list-services)" >> "$AUDIT_LOG"
    else
        log_error "防火墙启动失败"
        return 1
    fi
}

# ============================================================================
# 3. SSH安全加固
# ============================================================================
harden_ssh() {
    log_info "加固SSH配置..."
    
    local ssh_config="/etc/ssh/sshd_config"
    local backup_file="$BACKUP_DIR/sshd_config.backup"
    
    # 备份原始配置
    sudo cp "$ssh_config" "$backup_file"
    log_info "SSH配置已备份到: $backup_file"
    
    # 应用安全配置
    log_info "应用SSH安全配置..."
    
    # 禁用root登录
    sudo sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' "$ssh_config"
    
    # 禁用密码认证（如果已使用密钥）
    sudo sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' "$ssh_config"
    
    # 添加用户限制（根据实际情况修改）
    if ! grep -q "^AllowUsers" "$ssh_config"; then
        echo "AllowUsers admin" | sudo tee -a "$ssh_config"
    fi
    
    # 添加连接超时设置
    if ! grep -q "^ClientAliveInterval" "$ssh_config"; then
        echo "ClientAliveInterval 300" | sudo tee -a "$ssh_config"
        echo "ClientAliveCountMax 2" | sudo tee -a "$ssh_config"
    fi
    
    # 添加登录尝试限制
    if ! grep -q "^MaxAuthTries" "$ssh_config"; then
        echo "MaxAuthTries 3" | sudo tee -a "$ssh_config"
        echo "MaxSessions 10" | sudo tee -a "$ssh_config"
    fi
    
    # 测试配置语法
    if sudo sshd -t; then
        log_success "SSH配置语法正确"
    else
        log_error "SSH配置语法错误，恢复备份"
        sudo cp "$backup_file" "$ssh_config"
        return 1
    fi
    
    # 重启SSH服务
    sudo systemctl restart sshd
    
    # 验证服务状态
    if sudo systemctl is-active sshd >/dev/null; then
        log_success "SSH服务重启成功"
        echo "SSH配置变更:" >> "$AUDIT_LOG"
        grep -E "^(PermitRootLogin|PasswordAuthentication|AllowUsers|ClientAlive|MaxAuthTries)" "$ssh_config" >> "$AUDIT_LOG"
    else
        log_error "SSH服务重启失败"
        return 1
    fi
}

# ============================================================================
# 4. 系统更新管理
# ============================================================================
configure_updates() {
    log_info "配置系统更新管理..."
    
    # 创建安全更新检查脚本
    local update_script="/usr/local/bin/check-security-updates"
    sudo tee "$update_script" > /dev/null << 'EOF'
#!/bin/bash
# 安全更新检查脚本
LOG_FILE="/var/log/security-updates.log"
DATE=$(date "+%Y-%m-%d %H:%M:%S")

echo "=== 安全更新检查 $DATE ===" >> $LOG_FILE

if command -v dnf &> /dev/null; then
    dnf check-update --security 2>/dev/null | grep -v "Last metadata" >> $LOG_FILE
    UPDATE_COUNT=$(dnf check-update --security 2>/dev/null | grep -c -E "^[a-zA-Z0-9]" || echo 0)
elif command -v yum &> /dev/null; then
    yum check-update --security 2>/dev/null | tail -n +3 >> $LOG_FILE
    UPDATE_COUNT=$(yum check-update --security 2>/dev/null | tail -n +3 | wc -l)
else
    echo "无法检查更新" >> $LOG_FILE
    UPDATE_COUNT=0
fi

echo "发现 $UPDATE_COUNT 个安全更新" >> $LOG_FILE
echo "" >> $LOG_FILE

if [ $UPDATE_COUNT -gt 0 ]; then
    logger -t security-updates "发现 $UPDATE_COUNT 个安全更新需要安装"
fi

find /var/log/security-updates.log -mtime +30 -delete 2>/dev/null || true
EOF
    
    sudo chmod +x "$update_script"
    
    # 创建cron任务
    local cron_script="/etc/cron.daily/security-update-check"
    sudo tee "$cron_script" > /dev/null << 'EOF'
#!/bin/bash
/usr/local/bin/check-security-updates
EOF
    
    sudo chmod +x "$cron_script"
    
    log_success "系统更新管理配置完成"
    echo "更新检查脚本: $update_script" >> "$AUDIT_LOG"
    echo "Cron任务: $cron_script" >> "$AUDIT_LOG"
}

# ============================================================================
# 5. 安全监控配置
# ============================================================================
configure_monitoring() {
    log_info "配置安全监控..."
    
    # SSH失败登录监控
    local ssh_monitor="/usr/local/bin/monitor-failed-logins"
    sudo tee "$ssh_monitor" > /dev/null << 'EOF'
#!/bin/bash
LOG_FILE="/var/log/failed-ssh.log"
DATE=$(date "+%Y-%m-%d %H:%M:%S")

echo "=== SSH失败登录检查 $DATE ===" >> $LOG_FILE

TODAY=$(date "+%b %d")
FAILED_COUNT=$(journalctl -u sshd --since "today" 2>/dev/null | grep -i "fail\|invalid" | wc -l)

if [ $FAILED_COUNT -gt 0 ]; then
    echo "发现 $FAILED_COUNT 次失败SSH登录尝试" >> $LOG_FILE
    journalctl -u sshd --since "today" 2>/dev/null | grep -i "fail\|invalid" | tail -5 >> $LOG_FILE
    
    if [ $FAILED_COUNT -gt 10 ]; then
        logger -t ssh-security "高频率失败登录尝试: $FAILED_COUNT 次"
    fi
else
    echo "无失败SSH登录尝试" >> $LOG_FILE
fi

echo "" >> $LOG_FILE
find /var/log/failed-ssh.log -mtime +30 -delete 2>/dev/null || true
EOF
    
    sudo chmod +x "$ssh_monitor"
    
    # 综合安全监控
    local security_monitor="/usr/local/bin/security-monitor"
    sudo tee "$security_monitor" > /dev/null << 'EOF'
#!/bin/bash
LOG_FILE="/var/log/security-monitor.log"
DATE=$(date "+%Y-%m-%d %H:%M:%S")

echo "=== 综合安全监控报告 $DATE ===" >> $LOG_FILE
echo "" >> $LOG_FILE

echo "1. 系统安全更新检查:" >> $LOG_FILE
/usr/local/bin/check-security-updates > /dev/null 2>&1
tail -5 /var/log/security-updates.log 2>/dev/null | grep -v "===" >> $LOG_FILE
echo "" >> $LOG_FILE

echo "2. SSH安全检查:" >> $LOG_FILE
/usr/local/bin/monitor-failed-logins > /dev/null 2>&1
tail -5 /var/log/failed-ssh.log 2>/dev/null | grep -v "===" >> $LOG_FILE
echo "" >> $LOG_FILE

echo "3. 网络端口检查:" >> $LOG_FILE
ss -tuln 2>/dev/null | grep "LISTEN" | awk '{print "  端口:", $5, "状态: 监听中"}' >> $LOG_FILE
echo "" >> $LOG_FILE

echo "4. 防火墙状态:" >> $LOG_FILE
if systemctl is-active firewalld >/dev/null 2>&1; then
    echo "   firewalld: 运行中" >> $LOG_FILE
else
    echo "   防火墙: 未启用" >> $LOG_FILE
fi
echo "" >> $LOG_FILE

echo "5. 磁盘使用检查:" >> $LOG_FILE
df -h / | tail -1 | awk '{print "  根分区使用率:", $5}' >> $LOG_FILE
echo "" >> $LOG_FILE

echo "=== 监控完成 ===" >> $LOG_FILE
echo "" >> $LOG_FILE
find /var/log/security-monitor.log -mtime +30 -delete 2>/dev/null || true
EOF
    
    sudo chmod +x "$security_monitor"
    
    # 创建每日监控cron
    local daily_monitor="/etc/cron.daily/security-monitor"
    sudo tee "$daily_monitor" > /dev/null << 'EOF'
#!/bin/bash
/usr/local/bin/security-monitor
SUMMARY=$(tail -20 /var/log/security-monitor.log 2>/dev/null | grep -E "⚠️|运行中|使用率|发现" || echo "安全监控运行完成")
logger -t security-monitor "每日安全检查: $SUMMARY"
EOF
    
    sudo chmod +x "$daily_monitor"
    
    log_success "安全监控配置完成"
    echo "监控脚本配置:" >> "$AUDIT_LOG"
    echo "  - SSH失败登录监控: $ssh_monitor" >> "$AUDIT_LOG"
    echo "  - 综合安全监控: $security_monitor" >> "$AUDIT_LOG"
    echo "  - 每日Cron任务: $daily_monitor" >> "$AUDIT_LOG"
}

# ============================================================================
# 6. 安装安全更新
# ============================================================================
install_security_updates() {
    log_info "检查并安装安全更新..."
    
    # 检查可用更新
    if command -v dnf &> /dev/null; then
        UPDATE_COUNT=$(sudo dnf check-update --security 2>/dev/null | grep -c -E "^[a-zA-Z0-9]" || echo 0)
    elif command -v yum &> /dev/null; then
        UPDATE_COUNT=$(sudo yum check-update --security 2>/dev/null | tail -n +3 | wc -l)
    else
        log_warning "无法检查安全更新"
        return 0
    fi
    
    if [ "$UPDATE_COUNT" -gt 0 ]; then
        log_info "发现 $UPDATE_COUNT 个安全更新，开始安装..."
        
        if command -v dnf &> /dev/null; then
            sudo dnf update --security -y
        elif command -v yum &> /dev/null; then
            sudo yum update --security -y
        fi
        
        if [ $? -eq 0 ]; then
            log_success "安全更新安装完成"
            echo "安装安全更新数量: $UPDATE_COUNT" >> "$AUDIT_LOG"
        else
            log_warning "安全更新安装过程中可能有问题"
            echo "安全更新安装可能不完整" >> "$AUDIT_LOG"
        fi
    else
        log_success "没有可用的安全更新"
        echo "安全更新状态: 系统已是最新" >> "$AUDIT_LOG"
    fi
}

# ============================================================================
# 7. 验证和报告
# ============================================================================
verify_and_report() {
    log_info "验证加固结果..."
    
    echo "" >> "$AUDIT_LOG"
    echo "=== 加固验证结果 ===" >> "$AUDIT_LOG"
    echo "验证时间: $(date)" >> "$AUDIT_LOG"
    
    # 验证防火墙
    if sudo firewall-cmd --state | grep -q "running"; then
        echo "防火墙: ✅ 运行中" >> "$AUDIT_LOG"
    else
        echo "防火墙: ❌ 未运行" >> "$AUDIT_LOG"
    fi
    
    # 验证SSH服务
    if sudo systemctl is-active sshd >/dev/null; then
        echo "SSH服务: ✅ 运行中" >> "$AUDIT_LOG"
    else
        echo "SSH服务: ❌ 未运行" >> "$AUDIT_LOG"
    fi
    
    # 验证监控脚本
    if [ -x "/usr/local/bin/security-monitor" ]; then
        echo "监控系统: ✅ 已配置" >> "$AUDIT_LOG"
    else
        echo "监控系统: ❌ 未配置" >> "$AUDIT_LOG"
    fi
    
    # 验证更新检查
    if [ -x "/usr/local/bin/check-security-updates" ]; then
        echo "更新检查: ✅ 已配置" >> "$AUDIT_LOG"
    else
        echo "更新检查: ❌ 未配置" >> "$AUDIT_LOG"
    fi
    
    # 运行一次安全监控
    log_info "运行安全监控检查..."
    sudo /usr/local/bin/security-monitor > /dev/null 2>&1
    
    log_success "安全加固完成!"
    log_info "审计日志: $AUDIT_LOG"
    log_info "备份文件: $BACKUP_DIR"
    
    echo "" >> "$AUDIT_LOG"
    echo "=== 加固完成 ===" >> "$AUDIT_LOG"
    echo "完成时间: $(date)" >> "$AUDIT_LOG"
    echo "总耗时: $SECONDS 秒" >> "$AUDIT_LOG"
}

# ============================================================================
# 主函数
# ============================================================================
main() {
    SECONDS=0  # 记录脚本运行时间
    
    log_info "========================================="
    log_info "       系统安全加固脚本 v1.0"
    log_info "========================================="
    
    # 检查root权限
    if [ "$EUID" -ne 0 ]; then
        log_error "请使用root权限运行此脚本"
        log_error "示例: sudo bash security-hardening-script.sh"
        exit 1
    fi
    
    # 执行各个步骤
    initialize
    configure_firewall
    harden_ssh
    configure_updates
    configure_monitoring
    install_security_updates
    verify_and_report
    
    log_info "========================================="
    log_info "加固完成！请查看审计日志: $AUDIT_LOG"
    log_info "========================================="
    
    # 显示重要提醒
    echo ""
    log_warning "重要提醒:"
    echo "1. SSH root登录已禁用，请使用admin用户登录"
    echo "2. 防火墙已启用，仅允许SSH访问"
    echo "3. 每日安全监控已配置，请定期检查日志"
    echo "4. 所有配置备份在: $BACKUP_DIR"
    echo ""
    
    exit 0
}

# 执行主函数
main "$@"