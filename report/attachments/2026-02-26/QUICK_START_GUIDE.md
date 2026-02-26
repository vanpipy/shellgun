# 安全加固脚本快速使用指南

## 🚀 快速开始

### 1. 准备脚本
```bash
# 进入workspace目录
cd /home/admin/.openclaw/workspace-hacker

# 查看脚本
ls -la security-hardening-script.sh

# 赋予执行权限
chmod +x security-hardening-script.sh
```

### 2. 运行加固脚本
```bash
# 使用root权限运行
sudo bash security-hardening-script.sh
```

### 3. 监控执行过程
脚本执行期间会显示彩色状态信息：
- 🔵 蓝色: 信息提示
- 🟢 绿色: 成功完成
- 🟡 黄色: 警告提示
- 🔴 红色: 错误信息

### 4. 查看结果
```bash
# 查看审计日志
sudo cat /var/log/security-hardening-audit.log

# 查看备份文件
sudo ls -la /root/security-backups-*/
```

## 📋 核心功能速查

### 安全检查命令
```bash
# 防火墙状态
sudo firewall-cmd --state
sudo firewall-cmd --list-all

# SSH配置
sudo grep -E "^(PermitRootLogin|AllowUsers)" /etc/ssh/sshd_config

# 监控脚本
ls -la /usr/local/bin/security-monitor
ls -la /usr/local/bin/check-security-updates
```

### 日常维护命令
```bash
# 查看今日安全报告
sudo tail -50 /var/log/security-monitor.log

# 检查失败登录
sudo tail -20 /var/log/failed-ssh.log

# 手动运行完整检查
sudo /usr/local/bin/security-monitor
```

### 日志文件位置
```
/var/log/security-hardening-audit.log    # 加固审计日志
/var/log/security-monitor.log           # 每日安全报告
/var/log/failed-ssh.log                 # SSH失败登录
/var/log/security-updates.log           # 安全更新记录
```

## ⚠️ 重要提醒

### 执行前确认
1. ✅ 当前SSH连接稳定
2. ✅ 有云控制台VNC备用访问
3. ✅ 重要数据已备份
4. ✅ 了解回滚步骤

### 执行后验证
1. 🔍 测试新SSH连接
2. 🔍 验证服务正常运行
3. 🔍 检查监控日志
4. 🔍 确认备份文件

## 🔄 快速回滚

如果出现问题，按顺序执行：

```bash
# 1. 恢复SSH配置
sudo cp /root/security-backups-*/sshd_config.backup /etc/ssh/sshd_config
sudo systemctl restart sshd

# 2. 关闭防火墙
sudo systemctl stop firewalld
sudo systemctl disable firewalld

# 3. 测试SSH连接
ssh admin@服务器IP
```

## 📞 紧急支持

### 无法SSH连接时
1. 通过云控制台VNC访问
2. 查看审计日志定位问题
3. 使用备份文件恢复

### 查看详细日志
```bash
# 完整的审计跟踪
sudo cat /var/log/security-hardening-audit.log

# 系统日志中的安全事件
sudo journalctl -u sshd --since "today"
sudo journalctl -u firewalld --since "today"
```

## 🎯 最佳实践

### 执行时机
- 📅 业务低峰期
- 👥 有同事协助时
- 💾 数据备份完成后

### 验证步骤
1. 脚本执行完成后等待2分钟
2. 从新终端测试SSH连接
3. 验证关键业务服务
4. 检查监控系统是否正常工作

### 后续维护
- 每日查看安全监控日志
- 每周检查更新状态
- 每月审查配置有效性

---

**提示**: 完整文档请查看 `SECURITY_HARDENING_README.md`  
**脚本位置**: `/home/admin/.openclaw/workspace-hacker/security-hardening-script.sh`  
**生成时间**: 2026-02-26 08:10 GMT+8