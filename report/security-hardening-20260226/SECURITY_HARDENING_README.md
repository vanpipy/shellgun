# 系统安全加固脚本文档

## 概述

本脚本用于对Alibaba Cloud Linux 3系统进行全面的安全加固。脚本基于实际的安全审计结果和最佳实践，提供了自动化的安全配置和监控方案。

## 脚本信息

- **文件名**: `security-hardening-script.sh`
- **版本**: 1.0
- **生成时间**: 2026-02-26 08:10 GMT+8
- **生成会话**: agent:hacker:main
- **目标系统**: Alibaba Cloud Linux 3.2104 U12.3
- **脚本位置**: `/home/admin/.openclaw/workspace-hacker/security-hardening-script.sh`

## 安全加固内容

### 1. 防火墙配置
- 启用firewalld服务
- 配置默认拒绝所有入站连接
- 仅允许SSH服务（22端口）
- 设置开机自启

### 2. SSH安全加固
- 禁用root用户直接SSH登录
- 禁用密码认证（强制使用密钥）
- 限制允许登录的用户（仅admin）
- 配置连接超时设置（300秒）
- 限制登录尝试次数（最多3次）
- 限制并发会话数（最多10个）

### 3. 系统更新管理
- 创建安全更新检查脚本
- 配置每日自动检查安全更新
- 记录更新检查日志
- 30天日志轮转

### 4. 安全监控系统
- SSH失败登录监控
- 综合安全状态监控
- 每日自动安全报告
- 系统日志集成

### 5. 安全更新安装
- 自动检查可用安全更新
- 一键安装所有安全更新
- 安装结果记录和验证

## 审计和备份

### 审计日志
- **位置**: `/var/log/security-hardening-audit.log`
- **内容**: 所有加固操作的详细记录
- **格式**: 时间戳 + 操作描述 + 结果

### 配置备份
- **位置**: `/root/security-backups-YYYYMMDD_HHMMSS/`
- **内容**: 
  - SSH配置文件备份
  - 防火墙配置备份
  - 原始系统状态

### 监控日志
1. **安全更新日志**: `/var/log/security-updates.log`
2. **SSH失败登录**: `/var/log/failed-ssh.log`
3. **综合监控报告**: `/var/log/security-monitor.log`
4. **所有日志保留**: 30天

## 使用方法

### 首次运行
```bash
# 1. 赋予执行权限
chmod +x security-hardening-script.sh

# 2. 使用root权限运行
sudo bash security-hardening-script.sh

# 3. 查看审计日志
sudo cat /var/log/security-hardening-audit.log
```

### 日常维护
```bash
# 查看每日安全报告
sudo cat /var/log/security-monitor.log | tail -50

# 检查失败登录
sudo cat /var/log/failed-ssh.log | tail -20

# 手动运行安全监控
sudo /usr/local/bin/security-monitor

# 手动检查安全更新
sudo /usr/local/bin/check-security-updates
```

### 验证加固效果
```bash
# 检查防火墙状态
sudo firewall-cmd --state
sudo firewall-cmd --list-all

# 检查SSH配置
sudo grep -E "^(PermitRootLogin|AllowUsers|PasswordAuthentication)" /etc/ssh/sshd_config

# 检查监控脚本
ls -la /usr/local/bin/security-monitor
ls -la /usr/local/bin/check-security-updates
ls -la /usr/local/bin/monitor-failed-logins

# 检查Cron任务
ls -la /etc/cron.daily/security-*
```

## 安全配置详情

### SSH配置变更
```bash
# 主要变更项
PermitRootLogin no              # 禁用root登录
PasswordAuthentication no       # 禁用密码认证
AllowUsers admin               # 仅允许admin用户
ClientAliveInterval 300        # 连接超时300秒
ClientAliveCountMax 2          # 最多2次心跳失败
MaxAuthTries 3                 # 最多3次认证尝试
MaxSessions 10                 # 最多10个并发会话
```

### 防火墙规则
```bash
# 允许的服务
- ssh (22端口)
- cockpit (管理界面，如有)
- dhcpv6-client (IPv6 DHCP)

# 默认策略
- 默认区域: public
- 默认动作: 拒绝所有入站
- 记录拒绝的连接
```

### 监控脚本功能

#### 1. check-security-updates
- 每日检查安全更新
- 记录到 `/var/log/security-updates.log`
- 通过系统日志发送通知

#### 2. monitor-failed-logins
- 监控SSH失败登录尝试
- 高频率攻击自动告警
- 记录到 `/var/log/failed-ssh.log`

#### 3. security-monitor
- 综合安全状态检查
- 包含5个维度的检查
- 生成每日安全报告

## 风险管理和回滚

### 已知风险
1. **SSH访问中断**: 如果配置错误可能导致无法SSH登录
2. **服务影响**: 防火墙可能影响其他网络服务
3. **更新风险**: 安全更新可能导致服务不兼容

### 回滚方案
```bash
# 1. 恢复SSH配置
sudo cp /root/security-backups-*/sshd_config.backup /etc/ssh/sshd_config
sudo systemctl restart sshd

# 2. 禁用防火墙
sudo systemctl stop firewalld
sudo systemctl disable firewalld

# 3. 删除监控脚本
sudo rm -f /usr/local/bin/security-monitor
sudo rm -f /usr/local/bin/check-security-updates
sudo rm -f /usr/local/bin/monitor-failed-logins
sudo rm -f /etc/cron.daily/security-*

# 4. 恢复更新配置
# 根据备份文件恢复
```

### 应急联系方式
- 如果SSH无法连接，通过云控制台VNC访问
- 检查 `/var/log/security-hardening-audit.log` 了解具体操作
- 使用备份文件恢复配置

## 合规性和标准

### 遵循的安全标准
1. **CIS Benchmarks**: 遵循CIS Linux安全基准
2. **NIST SP 800-53**: 符合NIST安全控制框架
3. **ISO 27001**: 符合信息安全管理要求

### 安全控制点
- **AC-3**: 访问控制
- **AC-7**: 失败登录处理
- **SC-7**: 边界保护
- **SI-4**: 安全监控

## 维护计划

### 每日任务
- 检查 `/var/log/security-monitor.log`
- 查看失败登录记录
- 验证关键服务状态

### 每周任务
- 审查安全更新日志
- 分析攻击模式
- 备份审计日志

### 每月任务
- 审查所有安全配置
- 更新安全脚本
- 进行安全漏洞扫描

### 每季度任务
- 全面安全审计
- 更新安全策略
- 员工安全培训

## 故障排除

### 常见问题

#### Q1: SSH连接被拒绝
```bash
# 检查防火墙
sudo firewall-cmd --list-services | grep ssh

# 检查SSH服务
sudo systemctl status sshd

# 检查配置
sudo sshd -t
```

#### Q2: 监控脚本不工作
```bash
# 检查执行权限
ls -la /usr/local/bin/security-monitor

# 检查Cron配置
ls -la /etc/cron.daily/

# 手动运行测试
sudo /usr/local/bin/security-monitor
```

#### Q3: 安全更新失败
```bash
# 检查网络连接
ping mirrors.aliyun.com

# 检查仓库配置
cat /etc/yum.repos.d/*.repo | grep -i aliyun

# 清理缓存
sudo dnf clean all
```

### 联系支持
- 查看详细日志: `/var/log/security-hardening-audit.log`
- 检查备份文件: `/root/security-backups-*/`
- 参考本文档的"回滚方案"部分

## 版本历史

### v1.0 (2026-02-26)
- 初始版本发布
- 包含完整的安全加固功能
- 详细的审计和监控
- 完整的文档说明

## 免责声明

本脚本按"原样"提供，不提供任何明示或暗示的担保。使用本脚本产生的任何风险由用户自行承担。建议在生产环境使用前在测试环境充分测试。

---

**最后更新**: 2026-02-26  
**维护者**: OpenClaw Security Team  
**文档版本**: 1.0