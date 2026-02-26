太棒了！经历了这一路从零开始的配置，我们不仅搭建了一个安全的服务器，更建立了一套完整的方法论。现在，我将结合我们讨论的所有内容，为你生成两份总结性文档。

---

# 📚 文档一：阿里云裸机安全配置完全手册

## 文档信息
- **版本**：v1.0
- **适用系统**：Alibaba Linux / CentOS Stream (dnf 包管理器)
- **目标用户**：需要从零开始搭建安全云服务器的开发者
- **核心原则**：纵深防御、最小权限、密钥优先

---

## 一、安全配置总览

### 1.1 安全架构图
```
┌─────────────────────────────────────┐
│     第一层：阿里云安全组              │
│  （云平台防火墙，第一道防线）          │
├─────────────────────────────────────┤
│     第二层：系统防火墙 (FirewallD)    │
│  （服务器内部防火墙，第二道防线）       │
├─────────────────────────────────────┤
│     第三层：SSH 安全强化              │
│  （密钥认证、非标端口、用户白名单）     │
├─────────────────────────────────────┤
│     第四层：用户权限控制               │
│  （最小权限账户、目录权限严格限制）     │
├─────────────────────────────────────┤
│     第五层：入侵防御 (Fail2ban)       │
│  （自动封禁暴力破解）                  │
└─────────────────────────────────────┘
```

### 1.2 安全配置清单
| 层级 | 配置项 | 预期状态 | 验证命令 |
|------|--------|----------|----------|
| 云平台 | 安全组端口 | 仅开放必要端口 | 阿里云控制台 |
| 防火墙 | FirewallD | 运行中，仅放行 SSH 端口 | `sudo firewall-cmd --list-all` |
| SSH 服务 | 密码登录 | 禁用 | `sudo grep PasswordAuthentication /etc/ssh/sshd_config` |
| SSH 服务 | Root 登录 | 禁用 | `sudo grep PermitRootLogin /etc/ssh/sshd_config` |
| SSH 服务 | 端口 | 非标（如 22222） | `sudo grep Port /etc/ssh/sshd_config` |
| SSH 服务 | 用户白名单 | 仅允许专用账户 | `sudo grep AllowUsers /etc/ssh/sshd_config` |
| 用户权限 | .ssh 目录 | 700，所有者正确 | `ls -ld ~/.ssh` |
| 用户权限 | authorized_keys | 600，所有者正确 | `ls -l ~/.ssh/authorized_keys` |
| 入侵防御 | Fail2ban | 运行中 | `sudo systemctl status fail2ban` |

---

## 二、自动化安全配置脚本

### 2.1 脚本文件结构
```
server-security-init/
├── 01-init-system.sh          # 系统初始化
├── 02-create-user.sh           # 创建专用账户
├── 03-configure-ssh.sh         # SSH 强化配置
├── 04-configure-firewall.sh    # 防火墙配置
├── 05-install-fail2ban.sh      # 入侵防御
├── lib/
│   └── common.sh               # 公共函数库
└── config.conf                 # 配置文件
```

### 2.2 配置文件 config.conf
```bash
#!/bin/bash
# 安全配置参数文件

# 用户配置
APP_USER="app"                    # 专用账户名
APP_USER_HOME="/home/$APP_USER"   # 家目录

# SSH 配置
SSH_PORT="22222"                   # 自定义 SSH 端口
SSH_KEY_TYPE="rsa"                 # 密钥类型 (rsa/ed25519)
SSH_KEY_BITS="4096"                # RSA 密钥长度

# 防火墙配置
FIREWALL_PORTS=(
    "$SSH_PORT/tcp"                 # SSH 端口
    # "80/tcp"                       # HTTP（如需开放）
    # "443/tcp"                      # HTTPS（如需开放）
)

# Fail2ban 配置
FAIL2BAN_BANTIME="3600"             # 封禁时间（秒）
FAIL2BAN_FINDTIME="600"              # 统计窗口（秒）
FAIL2BAN_MAXRETRY="3"                # 最大重试次数
```

### 2.3 公共函数库 lib/common.sh
```bash
#!/bin/bash
# 公共函数库

set -e  # 任何命令失败就退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志函数
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${BLUE}[STEP]${NC} $1"; }

# 检查 root 权限
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "此脚本需要 root 权限，请使用 sudo 运行"
        exit 1
    fi
}

# 检测操作系统
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VER=$VERSION_ID
        log_info "检测到系统: $OS $VER"
    else
        log_error "无法检测操作系统类型"
        exit 1
    fi
}

# 安装软件包（适配 dnf/apt）
install_packages() {
    local packages=("$@")
    
    if [[ "$OS" == "centos" ]] || [[ "$OS" == "rhel" ]] || [[ "$OS" == "alinux" ]]; then
        dnf install -y "${packages[@]}"
    elif [[ "$OS" == "ubuntu" ]] || [[ "$OS" == "debian" ]]; then
        apt update && apt install -y "${packages[@]}"
    else
        log_error "不支持的操作系统: $OS"
        exit 1
    fi
}

# 备份文件
backup_file() {
    local file=$1
    if [ -f "$file" ]; then
        cp "$file" "$file.bak.$(date +%Y%m%d%H%M%S)"
        log_info "已备份: $file"
    fi
}
```

### 2.4 系统初始化 01-init-system.sh
```bash
#!/bin/bash
# 第一阶段：系统初始化

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/config.conf"

# 显示标题
cat << "EOF"
╔════════════════════════════════════════╗
║    第一阶段：系统初始化                  ║
╚════════════════════════════════════════╝
EOF

# 检查权限
check_root
detect_os

# 更新系统
log_step "更新系统软件包"
install_packages epel-release  # 可选，增加软件源
dnf update -y

# 安装基础工具
log_step "安装基础工具"
install_packages curl wget git vim net-tools telnet

# 设置主机名（可选）
read -p "是否设置主机名？(y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    read -p "请输入主机名: " HOSTNAME
    hostnamectl set-hostname "$HOSTNAME"
    log_info "主机名已设置为: $HOSTNAME"
fi

# 设置时区
timedatectl set-timezone Asia/Shanghai
log_info "时区已设置为: Asia/Shanghai"

# 检查 SELinux 状态（CentOS/RHEL 系列）
if command -v getenforce &>/dev/null; then
    log_info "SELinux 状态: $(getenforce)"
    # 建议保持 enforcing 模式，但需要正确配置上下文
fi

log_info "系统初始化完成！"
```

### 2.5 创建专用账户 02-create-user.sh
```bash
#!/bin/bash
# 第二阶段：创建专用账户

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/config.conf"

cat << "EOF"
╔════════════════════════════════════════╗
║    第二阶段：创建专用账户                ║
╚════════════════════════════════════════╝
EOF

check_root

# 创建用户
if id "$APP_USER" &>/dev/null; then
    log_warn "用户 $APP_USER 已存在"
else
    log_step "创建用户 $APP_USER"
    useradd -m -s /bin/bash "$APP_USER"
    log_info "用户创建成功"
fi

# 设置临时密码
log_step "设置临时密码（用于首次 ssh-copy-id）"
passwd "$APP_USER"

# 确保用户不在 sudo 组
if groups "$APP_USER" | grep -q "wheel\|sudo"; then
    log_warn "用户 $APP_USER 在 sudo 组中，正在移除..."
    gpasswd -d "$APP_USER" wheel 2>/dev/null || true
    gpasswd -d "$APP_USER" sudo 2>/dev/null || true
fi

# 创建 .ssh 目录并设置权限
log_step "准备 SSH 目录"
mkdir -p "$APP_USER_HOME/.ssh"
chmod 700 "$APP_USER_HOME/.ssh"
chown "$APP_USER:$APP_USER" "$APP_USER_HOME/.ssh"

log_info "第二阶段完成！"
cat << EOF

${GREEN}下一步操作：${NC}
1. 在本地执行：ssh-copy-id -i ~/.ssh/id_rsa.pub $APP_USER@<服务器IP> -p 22
2. 测试密钥登录成功后，执行第三阶段脚本
EOF
```

### 2.6 SSH 强化配置 03-configure-ssh.sh
```bash
#!/bin/bash
# 第三阶段：SSH 强化配置

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/config.conf"

cat << "EOF"
╔════════════════════════════════════════╗
║    第三阶段：SSH 强化配置               ║
╚════════════════════════════════════════╝
EOF

check_root

# 备份 SSH 配置
backup_file "/etc/ssh/sshd_config"

# 生成新的 SSH 配置
log_step "生成新的 SSH 配置"
cat > /etc/ssh/sshd_config << EOF
# SSH 服务配置 - 生成于 $(date)

# 端口设置
Port $SSH_PORT

# 协议版本
Protocol 2

# 认证设置
PubkeyAuthentication yes
PasswordAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication no

# 登录限制
PermitRootLogin no
MaxAuthTries 3
MaxSessions 10
AllowUsers $APP_USER

# 禁止默认管理员登录（可选）
DenyUsers admin

# 超时设置
ClientAliveInterval 300
ClientAliveCountMax 2

# 日志设置
LogLevel INFO

# 主机密钥
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key

# 其他安全设置
StrictModes yes
IgnoreRhosts yes
HostbasedAuthentication no
EOF

# 检查配置语法
log_step "检查配置语法"
if ! sshd -t; then
    log_error "SSH 配置语法错误"
    exit 1
fi

# 重启 SSH 服务
log_step "重启 SSH 服务"
systemctl restart sshd

log_info "SSH 配置完成！"
cat << EOF

${GREEN}重要提醒：${NC}
1. 在关闭当前会话前，新开终端测试：
   ssh -p $SSH_PORT $APP_USER@<服务器IP>
2. 测试成功后，执行第四阶段脚本
EOF
```

### 2.7 防火墙配置 04-configure-firewall.sh
```bash
#!/bin/bash
# 第四阶段：防火墙配置

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/config.conf"

cat << "EOF"
╔════════════════════════════════════════╗
║    第四阶段：防火墙配置                 ║
╚════════════════════════════════════════╝
EOF

check_root

# 安装 firewalld
log_step "安装 firewalld"
install_packages firewalld

# 启动防火墙
log_step "启动防火墙服务"
systemctl start firewalld
systemctl enable firewalld

# 清空默认规则（可选）
# firewall-cmd --zone=public --remove-service=ssh --permanent

# 添加自定义端口
log_step "配置防火墙规则"
for port in "${FIREWALL_PORTS[@]}"; do
    firewall-cmd --permanent --add-port="$port"
    log_info "放行端口: $port"
done

# 可选：放行服务（如果使用标准端口）
# firewall-cmd --permanent --add-service=http
# firewall-cmd --permanent --add-service=https

# 重载防火墙
firewall-cmd --reload

# 显示最终规则
log_step "当前防火墙规则"
firewall-cmd --list-all

log_info "防火墙配置完成！"
```

### 2.8 入侵防御配置 05-install-fail2ban.sh
```bash
#!/bin/bash
# 第五阶段：Fail2ban 配置

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/config.conf"

cat << "EOF"
╔════════════════════════════════════════╗
║    第五阶段：Fail2ban 配置              ║
╚════════════════════════════════════════╝
EOF

check_root

# 安装 fail2ban
log_step "安装 fail2ban"
install_packages fail2ban

# 创建 jail.local 配置
log_step "生成 Fail2ban 配置"
cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
bantime = $FAIL2BAN_BANTIME
findtime = $FAIL2BAN_FINDTIME
maxretry = $FAIL2BAN_MAXRETRY
ignoreip = 127.0.0.1/8 ::1

[sshd]
enabled = true
port = $SSH_PORT
logpath = %(sshd_log)s
EOF

# CentOS/RHEL 系列使用不同的日志路径
if [[ "$OS" == "centos" ]] || [[ "$OS" == "rhel" ]] || [[ "$OS" == "alinux" ]]; then
    sed -i 's|%(sshd_log)s|/var/log/secure|' /etc/fail2ban/jail.local
fi

# 启动服务
log_step "启动 Fail2ban"
systemctl start fail2ban
systemctl enable fail2ban

# 查看状态
sleep 2
fail2ban-client status sshd

log_info "Fail2ban 配置完成！"
```

### 2.9 主控脚本 run-all.sh
```bash
#!/bin/bash
# 主控脚本：按顺序执行所有配置

echo "╔════════════════════════════════════════╗"
echo "║    阿里云服务器安全初始化主控脚本      ║"
echo "╚════════════════════════════════════════╝"
echo

# 检查配置文件
if [ ! -f "config.conf" ]; then
    echo "错误：找不到 config.conf 文件"
    exit 1
fi

# 加载配置
source config.conf

echo "配置信息："
echo "  用户名: $APP_USER"
echo "  SSH端口: $SSH_PORT"
echo "  防火墙端口: ${FIREWALL_PORTS[*]}"
echo

read -p "是否继续？(y/n): " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 0
fi

# 执行各阶段脚本
for script in 01-init-system.sh 02-create-user.sh; do
    if [ -f "$script" ]; then
        echo
        echo "执行 $script ..."
        bash "$script"
        read -p "按回车继续..."
    else
        echo "警告：找不到 $script"
    fi
done

echo
echo "基础配置完成！请完成以下手动步骤："
echo "1. 在本地执行：ssh-copy-id -i ~/.ssh/id_rsa.pub $APP_USER@<服务器IP> -p 22"
echo "2. 测试密钥登录成功后，继续执行后续脚本"
```

---

## 三、关键配置点详解

### 3.1 SSH 目录权限黄金法则
```
目录/文件        | 权限 | 所有者 | 说明
----------------|------|--------|--------------------
/home/app       | 755  | app:app | 家目录
/home/app/.ssh  | 700  | app:app | SSH 配置目录
authorized_keys | 600  | app:app | 授权密钥文件
```

**为什么必须这样？**
- `700` 确保只有 `app` 能进入 `.ssh` 目录
- `600` 确保只有 `app` 能读写密钥文件
- 任何过宽松的权限（如 `777`）都会导致 SSH 拒绝使用

### 3.2 两种登录方式的本质区别
| 方式 | 命令 | 会话类型 | 环境变量 | 推荐度 |
|------|------|----------|----------|--------|
| SSH 直接登录 | `ssh app@server` | 全新会话 | 纯净 | ⭐⭐⭐⭐⭐ |
| su 切换 | `su - app` | 继承会话 | 可能污染 | ⭐⭐ |
| sudo 切换 | `sudo -u app -i` | 模拟登录 | 较纯净 | ⭐⭐⭐⭐ |

**关键发现**：必须坚持用 SSH 直接登录目标用户，避免使用 `su` 切换，否则可能导致 Volta/npm 等工具的权限问题。

### 3.3 防火墙双层防护
1. **阿里云安全组**：云平台级防护，放行必要端口
2. **FirewallD**：系统级防护，精细化控制

**验证命令**：
```bash
# 检查云平台安全组：阿里云控制台 → 防火墙
# 检查系统防火墙
sudo firewall-cmd --list-all
```

### 3.4 Volta/npm 权限问题解决方案
```bash
# 黄金法则：永远用 SSH 直接登录目标用户
ssh app@server

# 所有操作都在此会话中完成
volta install node
volta install pnpm

# 避免使用 su 切换
# su - app  ❌ 可能导致权限问题
```

---

## 四、故障排查速查表

| 现象 | 可能原因 | 排查命令 | 解决方案 |
|------|----------|----------|----------|
| 连接超时 | 防火墙阻挡 | `telnet <IP> <端口>` | 检查安全组和 FirewallD |
| 连接被拒 | 服务未监听 | `sudo ss -tlnp | grep <端口>` | 检查 SSH 配置和状态 |
| 权限拒绝 | 密钥/目录权限错 | `sudo journalctl -u sshd -f` | 修复权限为 700/600 |
| 量子警告 | 服务器 OpenSSH 版本低 | `ssh -V` | 升级服务器或本地配置 |
| Volta 报错 | 环境变量污染 | `echo $VOLTA_HOME` | 用 SSH 重新登录 |

---

## 五、安全配置检查清单

### 初始化阶段
- [ ] 更新系统：`sudo dnf update -y`
- [ ] 安装基础工具：curl, wget, git, vim
- [ ] 设置时区：`timedatectl set-timezone Asia/Shanghai`
- [ ] 检查 SELinux 状态（建议 enforcing）

### 用户阶段
- [ ] 创建专用账户：`app`
- [ ] 设置临时密码
- [ ] 确保用户不在 sudo 组
- [ ] 创建 `.ssh` 目录（权限 700）

### SSH 阶段
- [ ] 修改端口为非标（22222）
- [ ] 禁用密码登录
- [ ] 禁用 root 登录
- [ ] 设置用户白名单（AllowUsers）
- [ ] 测试密钥登录成功
- [ ] 备份 SSH 配置

### 防火墙阶段
- [ ] 启动 firewalld
- [ ] 放行自定义 SSH 端口
- [ ] 重载防火墙
- [ ] 验证规则生效

### 入侵防御阶段
- [ ] 安装 fail2ban
- [ ] 配置自定义端口
- [ ] 启动服务
- [ ] 验证状态

### 最终验证
- [ ] SSH 密钥登录成功
- [ ] SSH 密码登录失败
- [ ] root 登录失败
- [ ] admin 登录失败（如已禁止）
- [ ] 防火墙仅开放必要端口
- [ ] fail2ban 运行中

---

## 六、经验总结

### 6.1 最重要的三条原则
1. **纵深防御**：永远不要依赖单层防护，云平台和系统都要配置
2. **最小权限**：账户、目录、端口，能不给的权限坚决不给
3. **密钥优先**：密码是临时过渡，密钥才是长久之计

### 6.2 最容易踩的三个坑
1. **权限错误**：SSH 对权限极其敏感，`755` 和 `700` 的区别就是成功和失败
2. **防火墙双忘**：只配了系统防火墙，忘了云平台安全组
3. **su 切换幻觉**：以为切换用户就彻底干净，实际环境变量还在污染

### 6.3 最有价值的三个习惯
1. **测试前保持会话**：修改 SSH 配置后，新开终端测试成功再关旧会话
2. **日志是第一老师**：遇到问题先看日志 `sudo journalctl -u sshd -f`
3. **用 SSH 直接登录**：永远不要用 `su` 切换做包管理操作

---

这份手册凝聚了我们这一路的所有探索和经验。它不是一个静态的文档，而是一个可以根据实际需求不断完善的框架。希望它能成为你未来所有云服务器配置的坚实起点。

---

# 📚 文档二：OpenClaw 阿里云安装部署手册

## 文档信息
- **版本**：v1.0
- **适用环境**：已完成安全配置的阿里云服务器
- **目标用户**：希望在安全服务器上部署 OpenClaw 的开发者
- **前置依赖**：已完成《阿里云裸机安全配置完全手册》中的所有步骤

---

## 一、部署前提检查清单

在开始安装 OpenClaw 之前，请确保服务器已满足以下条件：

### 1.1 服务器状态检查
```bash
# 1. 确认使用专用账户（非 admin）
whoami
# 应输出：app

# 2. 确认 SSH 密钥登录正常
# 已经能无密码登录，说明 SSH 配置正确

# 3. 确认防火墙端口开放情况
sudo firewall-cmd --list-all
# 至少应看到：22222/tcp（SSH端口）

# 4. 确认系统已更新
sudo dnf check-update
```

### 1.2 网络连通性检查
```bash
# 测试外部网络（用于下载依赖）
ping -c 3 github.com
ping -c 3 npmjs.com

# 测试飞书连通性（如需要）
curl -I https://open.feishu.cn
```

### 1.3 磁盘空间检查
```bash
# OpenClaw 需要约 1GB 空间
df -h /home/app
# 确认可用空间 > 2GB
```

---

## 二、依赖环境安装

### 2.1 安装 Node.js 和 npm（通过 Volta）

```bash
# 1. 安装 Volta（如果还没装）
curl https://get.volta.sh | bash

# 2. 重新加载 shell 配置
source ~/.bashrc

# 3. 验证 Volta 安装
volta --version

# 4. 通过 Volta 安装 Node.js LTS 版本
volta install node@lts

# 5. 验证 Node.js 和 npm
node --version  # 应显示 v20+ 
npm --version   # 应显示 v10+

# 6. 查看 Volta 管理的工具链
volta list
```

### 2.2 安装 pnpm（推荐）

```bash
# 使用 Volta 安装 pnpm（避免权限问题）
volta install pnpm

# 验证安装
pnpm --version
```

**重要提醒**：整个安装过程必须**通过 SSH 直接登录 `app` 用户**完成，不要使用 `su` 切换。

### 2.3 安装 Git（用于克隆代码）

```bash
# 安装 Git
sudo dnf install git -y

# 验证安装
git --version

# 配置 Git（可选）
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### 2.4 安装 PM2（进程管理，可选但推荐）

```bash
# 全局安装 PM2
volta install pm2

# 验证安装
pm2 --version
```

---

## 三、OpenClaw 安装

### 3.1 创建 OpenClaw 专用目录

```bash
# 创建应用目录（统一管理）
mkdir -p ~/apps/openclaw
cd ~/apps/openclaw

# 创建数据目录（用于持久化存储）
mkdir -p ~/openclaw-data/{config,logs,memory}
```

### 3.2 安装 OpenClaw

OpenClaw 官方提供了多种安装方式，这里选择最稳定的方式：

```bash
# 方式一：通过 npm 全局安装（推荐）
npm install -g openclaw

# 方式二：通过 pnpm 全局安装
pnpm add -g openclaw

# 验证安装
openclaw --version
```

### 3.3 初始化 OpenClaw 配置

```bash
# 首次运行，生成配置文件
openclaw init

# 配置文件位置
ls -la ~/.openclaw/
# 应看到：openclaw.json（主配置文件）
```

### 3.4 查看默认配置

```bash
# 查看初始配置
cat ~/.openclaw/openclaw.json | jq '.' 2>/dev/null || cat ~/.openclaw/openclaw.json
```

---

## 四、OpenClaw 核心配置

### 4.1 配置文件结构

```bash
# 编辑配置文件
nano ~/.openclaw/openclaw.json
```

OpenClaw 配置文件采用 JSON 格式，主要包含以下核心部分：
- **`server`**：服务监听配置
- **`channels`**：通信渠道配置（如飞书）
- **`models`**：AI 模型配置
- **`agents`**：智能体行为配置
- **`filesystem`**：文件系统权限
- **`command`**：命令执行权限

### 4.2 基础服务配置

```json
{
  "server": {
    "port": 18789,
    "host": "127.0.0.1",
    "dashboard": true,
    "logLevel": "info"
  },
  "security": {
    "pairingRequired": true,
    "pairingTimeout": 300
  }
}
```

### 4.3 文件系统安全配置（关键！）

```json
{
  "filesystem": {
    "enabled": true,
    "allowedPaths": [
      "/home/app/openclaw-data",
      "/tmp"
    ],
    "readOnlyPaths": [
      "/etc"
    ],
    "maxFileSize": 10485760
  }
}
```

### 4.4 命令执行安全配置

```json
{
  "commandExecution": {
    "enabled": false,
    "allowedCommands": [
      "ls",
      "cat",
      "grep",
      "df"
    ],
    "dangerousPatterns": [
      "rm -rf",
      "mkfs",
      "dd"
    ]
  }
}
```

---

## 五、飞书渠道配置

### 5.1 在飞书开放平台创建应用

1. 登录 [飞书开放平台](https://open.feishu.cn/)
2. 点击"创建企业自建应用"
3. 填写应用名称（如 "OpenClaw 助手"）
4. 在"应用能力"中开启"机器人"
5. 记录以下信息：
   - **App ID**
   - **App Secret**
   - **Verification Token**
   - **Encrypt Key**

### 5.2 配置飞书权限

在"权限管理"中，添加以下权限：
```json
{
  "scopes": {
    "tenant": [
      "contact:user.base:readonly",
      "im:message",
      "im:message.group_at_msg:readonly",
      "im:message.p2p_msg:readonly",
      "im:message:send_as_bot"
    ]
  }
}
```

### 5.3 配置事件订阅

在"事件与回调"中：
1. **订阅方式**：选择"长连接"（不要用 Webhook）
2. **添加事件**：搜索并添加 `im.message.receive_v1`
3. **保存配置**

### 5.4 OpenClaw 飞书配置

在 `~/.openclaw/openclaw.json` 中添加飞书渠道：

```json
{
  "channels": {
    "feishu": {
      "enabled": true,
      "appId": "cli_xxxxxxxxxxxx",
      "appSecret": "xxxxxxxxxxxxxxxxxxxx",
      "verificationToken": "xxxxxxxxxxxx",
      "encryptKey": "xxxxxxxxxxxx",
      "webhookPath": "/feishu/webhook"
    }
  }
}
```

### 5.5 重启并测试

```bash
# 重启 OpenClaw 服务
openclaw gateway restart

# 查看状态
openclaw status
# Feishu 应显示为 ON 和 OK

# 查看实时日志（用于调试）
openclaw logs --follow
```

---

## 六、AI 模型配置

### 6.1 配置 OpenRouter（推荐）

```bash
# 设置 OpenRouter API Key
export OPENROUTER_API_KEY="sk-or-xxxxxxxxxxxxxxxx"

# 或写入配置文件
```

在 `~/.openclaw/openclaw.json` 中：

```json
{
  "models": {
    "providers": {
      "openrouter": {
        "apiKey": "${OPENROUTER_API_KEY}",
        "baseUrl": "https://openrouter.ai/api/v1"
      }
    }
  },
  "agents": {
    "defaults": {
      "model": "openrouter/anthropic/claude-3.5-sonnet"
    }
  }
}
```

### 6.2 配置本地模型（Ollama，可选）

如果你有本地模型需求：

```bash
# 安装 Ollama
curl -fsSL https://ollama.com/install.sh | sh

# 下载模型
ollama pull qwen2.5:7b
```

配置文件中添加：

```json
{
  "models": {
    "providers": {
      "ollama": {
        "baseUrl": "http://localhost:11434/v1",
        "apiKey": "ollama-local",
        "models": [
          {
            "id": "qwen2.5:7b",
            "name": "Qwen2.5 7B",
            "contextWindow": 32768
          }
        ]
      }
    }
  }
}
```

### 6.3 查看可用模型

```bash
# 查看所有已配置的模型
openclaw models list

# 扫描所有可用模型（需 API Key）
openclaw models scan --provider openrouter
```

---

## 七、服务管理与监控

### 7.1 使用 PM2 管理 OpenClaw（推荐）

```bash
# 创建 PM2 配置文件
cat > ~/apps/openclaw/ecosystem.config.js << 'EOF'
module.exports = {
  apps: [{
    name: 'openclaw',
    script: 'openclaw',
    args: 'gateway',
    interpreter: 'none',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '500M',
    env: {
      NODE_ENV: 'production',
      OPENROUTER_API_KEY: process.env.OPENROUTER_API_KEY
    },
    error_file: '~/openclaw-data/logs/err.log',
    out_file: '~/openclaw-data/logs/out.log',
    log_file: '~/openclaw-data/logs/combined.log',
    time: true
  }]
};
EOF

# 启动服务
pm2 start ~/apps/openclaw/ecosystem.config.js

# 设置开机自启
pm2 startup
pm2 save

# 查看状态
pm2 status
pm2 logs openclaw
```

### 7.2 使用 systemd 管理（备选）

```bash
# 创建 systemd 服务文件
sudo nano /etc/systemd/system/openclaw.service
```

```ini
[Unit]
Description=OpenClaw AI Agent
After=network.target

[Service]
Type=simple
User=app
Group=app
WorkingDirectory=/home/app
Environment="OPENROUTER_API_KEY=sk-or-xxxxxx"
ExecStart=/home/app/.volta/bin/openclaw gateway
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

```bash
# 启用服务
sudo systemctl daemon-reload
sudo systemctl enable openclaw
sudo systemctl start openclaw
sudo systemctl status openclaw
```

### 7.3 日志监控

```bash
# 实时查看日志
pm2 logs openclaw

# 查看 OpenClaw 状态
openclaw status

# 查看系统资源占用
htop  # 或 top
```

---

## 八、防火墙端口配置（服务器内部）

### 8.1 如果需要远程访问 Dashboard

```bash
# 放行 Dashboard 端口（如需远程访问）
sudo firewall-cmd --permanent --add-port=18789/tcp
sudo firewall-cmd --reload

# 查看规则
sudo firewall-cmd --list-all
```

**安全提醒**：Dashboard 默认监听 `127.0.0.1`，只能本地访问。如需远程访问：
1. 修改配置为 `0.0.0.0`
2. 在阿里云安全组放行端口
3. **强烈建议**设置 IP 白名单或使用 SSH 隧道

### 8.2 SSH 隧道访问 Dashboard（推荐的安全方式）

```bash
# 本地建立 SSH 隧道
ssh -L 8888:127.0.0.1:18789 -p 22222 app@<服务器IP>

# 然后在本地浏览器访问
# http://localhost:8888
```

---

## 九、安全最佳实践总结

### 9.1 账户权限
- ✅ 始终使用 `app` 账户运行
- ✅ 禁止使用 root 运行任何服务
- ✅ 配置文件权限严格限制

### 9.2 文件系统
- ✅ 限制 OpenClaw 能访问的目录
- ✅ 只读目录单独配置
- ✅ 敏感文件单独保护

### 9.3 命令执行
- ✅ 默认关闭命令执行
- ✅ 如需开启，使用白名单
- ✅ 拦截危险命令模式