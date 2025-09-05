# =============================================================================
# VSCodium Electron-Updater 快速集成脚本
# 适用于 Windows PowerShell
# 一键完成所有集成步骤
# =============================================================================

# 快速配置（可在此处直接修改）
# =============================================================================
# 请修改以下配置为你的实际值
$VSCODIUM_SOURCE_PATH = ".."                      # VSCodium 源码路径（相对路径，指向上级目录）
$UPDATE_SERVER_URL = "http://localhost:3000"       # 更新服务器地址
$CUSTOM_VERSION = ""                               # 自定义版本号（留空使用原版本）
# =============================================================================

# 获取脚本目录
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# 日志函数
function Write-Log {
    param([string]$Message)
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$Timestamp] $Message"
}

# 显示配置信息
function Show-Config {
    Write-Host "==========================================="
    Write-Host "VSCodium Electron-Updater 快速集成"
    Write-Host "==========================================="
    Write-Host "源码路径: $VSCODE_SOURCE_PATH"
    Write-Host "更新服务器: $UPDATE_SERVER_URL"
    Write-Host "自定义版本: $(if ($CUSTOM_VERSION) { $CUSTOM_VERSION } else { '使用原版本' })"
    Write-Host "==========================================="
    Write-Host
}

# 检查配置
function Test-Config {
    if ([string]::IsNullOrEmpty($VSCODE_SOURCE_PATH) -or $VSCODE_SOURCE_PATH -eq "C:\path\to\vscode") {
        Write-Log "❌ 错误: 请在脚本顶部设置正确的 VSCODE_SOURCE_PATH"
        Write-Log "请编辑此脚本文件，修改第 8 行的路径配置"
        exit 1
    }
    
    if (-not (Test-Path $VSCODE_SOURCE_PATH)) {
        Write-Log "❌ 错误: 源码路径不存在: $VSCODE_SOURCE_PATH"
        exit 1
    }
    
    $GitPath = Join-Path $VSCODIUM_SOURCE_PATH ".git"
    if (-not (Test-Path $GitPath)) {
        Write-Log "❌ 错误: 不是 Git 仓库: $VSCODIUM_SOURCE_PATH"
        exit 1
    }
}

# 更新配置文件
function Update-ConfigFile {
    $ConfigFile = Join-Path $ScriptDir "config.ps1"
    
    Write-Log "更新配置文件..."
    
    $ConfigContent = @"
# VSCodium Electron-Updater 集成脚本配置文件
# 由快速集成脚本自动生成

# 路径配置
`$VSCODIUM_SOURCE_PATH = "$VSCODIUM_SOURCE_PATH"
`$PATCHES_DIR = "..\patches-vscodium"
`$LOG_FILE = ".\integration.log"

# 更新服务器配置
`$UPDATE_SERVER_URL = "$UPDATE_SERVER_URL"

# 版本配置
`$CUSTOM_VERSION = "$CUSTOM_VERSION"

# 依赖版本配置
`$ELECTRON_UPDATER_VERSION = "^6.1.7"
`$ELECTRON_LOG_VERSION = "^5.0.1"

# 构建配置
`$AUTO_INSTALL_DEPS = `$true
`$AUTO_BUILD = `$false
`$BUILD_COMMAND = "npm run compile"

# 高级配置
`$GIT_APPLY_ARGS = "--ignore-space-change --ignore-whitespace"
`$CREATE_BACKUP = `$true
`$BACKUP_DIR = ".\backup"
"@
    
    Set-Content -Path $ConfigFile -Value $ConfigContent -Encoding UTF8
    Write-Log "✅ 配置文件已更新"
}

# 主函数
function Main {
    Show-Config
    
    # 检查配置
    Test-Config
    
    # 更新配置文件
    Update-ConfigFile
    
    # 运行集成脚本
    Write-Log "开始执行集成..."
    
    $IntegrateScript = Join-Path $ScriptDir "integrate-vscodium.ps1"
    if (Test-Path $IntegrateScript) {
        & $IntegrateScript
        if ($LASTEXITCODE -eq 0) {
            Write-Log "🎉 快速集成完成！"
        } else {
            Write-Log "❌ 集成失败，错误代码: $LASTEXITCODE"
            exit $LASTEXITCODE
        }
    } else {
        Write-Log "❌ 错误: 集成脚本不存在: $IntegrateScript"
        exit 1
    }
}

# 显示帮助
if ($args -contains "-h" -or $args -contains "--help") {
    Write-Host @"
VSCodium Electron-Updater 快速集成脚本

这是一个一键集成脚本，会自动完成所有必要步骤。

使用前请先修改脚本顶部的配置：
  - VSCODE_SOURCE_PATH: 你的 VSCode 源码路径
  - UPDATE_SERVER_URL: 你的更新服务器地址
  - CUSTOM_VERSION: 自定义版本号（可选）

使用方法:
  .\quick-integrate.ps1        # 执行快速集成
  .\quick-integrate.ps1 -h     # 显示此帮助信息

注意:
  - 请确保已安装 Git 和 npm
  - 请确保 VSCode 源码目录存在且为 Git 仓库
  - 集成完成后请使用 electron-builder 打包应用
"@
    exit 0
}

# 执行主函数
Main