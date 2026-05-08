# =============================================================================
# windows-env-configure.ps1 - Windows Development Environment Setup Script
# =============================================================================
#
# Description:
#   Automated setup script for Windows development environment including
#   Chocolatey, git, Python (uv), Volta (Node.js), Oh My Posh,
#   PowerToys, PSReadLine, and WSL.
#
# Usage:
#   .\windows-env-configure.ps1 [-Proxy PROXY] [-SkipWSL]
#
# Options:
#   -Proxy PROXY   HTTP/HTTPS proxy server (e.g., "localhost:7890")
#   -SkipWSL      Skip WSL installation
#
# Requirements:
#   - Windows 10/11
#   - PowerShell 5.1+ or PowerShell 7+
#   - Administrator privileges for Chocolatey
#
# =============================================================================

param(
    [string]$Proxy = "",
    [switch]$SkipWSL
)

$ErrorActionPreference = "Stop"

function write_info {
    param([string]$Message)
    Write-Host "==> $Message"
}

function write_error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
    exit 1
}

function install_chocolatey {
    write_info "Installing Chocolatey..."
    if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
        try {
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
            Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        } catch { write_error "Failed to install Chocolatey: $_" }
    } else { write_info "Chocolatey already installed" }
}

function setup_git_account {
    write_info "Installing Git via Chocolatey..."
    choco install git -y
    write_info "Git global setting"
    git config --global alias.st status
    git config --global alias.cmt commit
    git config --global alias.ck checkout
    git config --global credential.helper store
    write_info "Done"
}

function install_volta {
    write_info "Installing Volta..."
    if (Get-Command volta -ErrorAction SilentlyContinue) {
        write_info "Volta already installed, removing..."
        Remove-Item -Recurse -Force "$env:VOLTA_HOME" -ErrorAction SilentlyContinue
    }
    choco install volta -y
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    volta install node
    volta install pnpm
    volta install bun
    write_info "Done"
}

function install_python {
    write_info "Installing Python via Chocolatey and uv..."
    # Install Python via Chocolatey
    choco install python --version=3.12.0 -y

    # Install uv for package management
    if (Get-Command uv -ErrorAction SilentlyContinue) {
        write_info "uv already installed, skipping..."
    } else {
        irm https://astral.sh/uv/install.ps1 | iex
    }
    # Reload PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

    # Configure pip mirror
    pip config set global.index-url https://mirrors.sustech.edu.cn/pypi/web/simple
    write_info "Done"
}

function install_oh_my_posh {
    write_info "Installing Oh My Posh..."
    choco install oh-my-posh -y
}

function install_powertoys {
    write_info "Installing PowerToys..."
    winget install Microsoft.PowerToys --accept-source-agreements --accept-package-agreements
}

function install_psreadline {
    write_info "Installing PSReadLine..."
    Install-Module -Name PSReadLine -Scope CurrentUser -Force
}

function setup_wsl {
    write_info "Setting up WSL..."
    if ($SkipWSL) { write_info "Skipping WSL installation"; return }
    if ($Proxy) { $env:HTTP_PROXY = "http://$Proxy"; $env:HTTPS_PROXY = "http://$Proxy" }
    wsl --install
    wsl --install kali
}

function install {
    write_info "Starting Windows development environment setup..."
    install_chocolatey
    setup_git_account
    install_volta
    install_python
    install_oh_my_posh
    install_powertoys
    install_psreadline
    setup_wsl
    write_info "Setup complete!"
}

install