#!/bin/bash
# =============================================================================
# VSCodium Electron-Updater 快速集成脚本
# 适用于 Linux/macOS
# 一键完成所有集成步骤
# =============================================================================

set -e

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 快速配置（可在此处直接修改）
# =============================================================================
# 请修改以下配置为你的实际值
VSCODE_SOURCE_PATH="/path/to/vscode"          # VSCode 源码路径
UPDATE_SERVER_URL="http://localhost:3000"     # 更新服务器地址
CUSTOM_VERSION=""                             # 自定义版本号（留空使用原版本）
# =============================================================================

# 日志函数
log() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message"
}

# 显示配置信息
show_config() {
    echo "==========================================="
    echo "VSCodium Electron-Updater 快速集成"
    echo "==========================================="
    echo "源码路径: $VSCODE_SOURCE_PATH"
    echo "更新服务器: $UPDATE_SERVER_URL"
    echo "自定义版本: ${CUSTOM_VERSION:-'使用原版本'}"
    echo "==========================================="
    echo
}

# 检查配置
check_config() {
    if [[ -z "$VSCODE_SOURCE_PATH" ]] || [[ "$VSCODE_SOURCE_PATH" == "/path/to/vscode" ]]; then
        log "❌ 错误: 请在脚本顶部设置正确的 VSCODE_SOURCE_PATH"
        log "请编辑此脚本文件，修改第 12 行的路径配置"
        exit 1
    fi
    
    if [[ ! -d "$VSCODE_SOURCE_PATH" ]]; then
        log "❌ 错误: 源码路径不存在: $VSCODE_SOURCE_PATH"
        exit 1
    fi
    
    if [[ ! -d "$VSCODE_SOURCE_PATH/.git" ]]; then
        log "❌ 错误: 不是 Git 仓库: $VSCODE_SOURCE_PATH"
        exit 1
    fi
}

# 更新配置文件
update_config_file() {
    local config_file="$SCRIPT_DIR/config.sh"
    
    log "更新配置文件..."
    
    # 创建临时配置
    cat > "$config_file" << EOF
#!/bin/bash
# VSCodium Electron-Updater 集成脚本配置文件
# 由快速集成脚本自动生成

# 路径配置
VSCODE_SOURCE_PATH="$VSCODE_SOURCE_PATH"
PATCHES_DIR="../patches-vscodium"
LOG_FILE="./integration.log"

# 更新服务器配置
UPDATE_SERVER_URL="$UPDATE_SERVER_URL"

# 版本配置
CUSTOM_VERSION="$CUSTOM_VERSION"

# 依赖版本配置
ELECTRON_UPDATER_VERSION="^6.1.7"
ELECTRON_LOG_VERSION="^5.0.1"

# 构建配置
AUTO_INSTALL_DEPS=true
AUTO_BUILD=false
BUILD_COMMAND="npm run compile"

# 高级配置
GIT_APPLY_ARGS="--ignore-space-change --ignore-whitespace"
CREATE_BACKUP=true
BACKUP_DIR="./backup"
EOF
    
    log "✅ 配置文件已更新"
}

# 主函数
main() {
    show_config
    
    # 检查配置
    check_config
    
    # 更新配置文件
    update_config_file
    
    # 运行集成脚本
    log "开始执行集成..."
    
    if [[ -f "$SCRIPT_DIR/integrate-vscodium.sh" ]]; then
        bash "$SCRIPT_DIR/integrate-vscodium.sh"
    else
        log "❌ 错误: 集成脚本不存在: $SCRIPT_DIR/integrate-vscodium.sh"
        exit 1
    fi
    
    log "🎉 快速集成完成！"
}

# 显示帮助
if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    cat << EOF
VSCodium Electron-Updater 快速集成脚本

这是一个一键集成脚本，会自动完成所有必要步骤。

使用前请先修改脚本顶部的配置：
  - VSCODE_SOURCE_PATH: 你的 VSCode 源码路径
  - UPDATE_SERVER_URL: 你的更新服务器地址
  - CUSTOM_VERSION: 自定义版本号（可选）

使用方法:
  $0                    # 执行快速集成
  $0 -h, --help        # 显示此帮助信息

注意:
  - 请确保已安装 Git 和 npm
  - 请确保 VSCode 源码目录存在且为 Git 仓库
  - 集成完成后请使用 electron-builder 打包应用
EOF
    exit 0
fi

# 执行主函数
main