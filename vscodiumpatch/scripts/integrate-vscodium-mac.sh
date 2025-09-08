#!/bin/bash
# =============================================================================
# VSCodium Electron-Updater 集成脚本启动器
# 专用于 macOS
# =============================================================================

set -e

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INTEGRATE_SCRIPT="$SCRIPT_DIR/integrate-vscodium.sh"

# macOS 特定配置检查
check_macos_requirements() {
    echo "检查 macOS 环境..."
    
    # 检查 Xcode Command Line Tools
    if ! xcode-select -p &> /dev/null; then
        echo "❌ 错误: Xcode Command Line Tools 未安装"
        echo "请运行: xcode-select --install"
        exit 1
    fi
    
    # 检查 Homebrew（可选但推荐）
    if ! command -v brew &> /dev/null; then
        echo "⚠️  警告: Homebrew 未安装，建议安装以便管理依赖"
        echo "安装命令: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    else
        echo "✅ Homebrew 已安装"
    fi
    
    # 检查 Node.js 和 npm
    if ! command -v node &> /dev/null; then
        echo "❌ 错误: Node.js 未安装"
        if command -v brew &> /dev/null; then
            echo "建议使用 Homebrew 安装: brew install node"
        else
            echo "请从 https://nodejs.org 下载安装"
        fi
        exit 1
    fi
    
    echo "✅ macOS 环境检查通过"
}

# 设置 macOS 特定的环境变量
setup_macos_env() {
    # 设置 PATH 以包含常见的开发工具路径
    export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH"
    
    # 设置 Python 路径（某些 npm 包需要）
    if command -v python3 &> /dev/null; then
        export PYTHON="$(which python3)"
    fi
    
    # 设置编译器环境
    export CC=clang
    export CXX=clang++
}

# 主函数
main() {
    echo "==============================================="
    echo "VSCodium Electron-Updater 集成脚本 (macOS)"
    echo "==============================================="
    echo
    
    # macOS 环境检查
    check_macos_requirements
    
    # 设置环境
    setup_macos_env
    
    # 检查集成脚本是否存在
    if [[ ! -f "$INTEGRATE_SCRIPT" ]]; then
        echo "❌ 错误: 集成脚本不存在: $INTEGRATE_SCRIPT"
        exit 1
    fi
    
    # 确保脚本可执行
    chmod +x "$INTEGRATE_SCRIPT"
    
    echo "正在启动集成脚本..."
    echo "脚本路径: $INTEGRATE_SCRIPT"
    echo
    
    # 执行集成脚本
    if bash "$INTEGRATE_SCRIPT" "$@"; then
        echo
        echo "🎉 macOS 集成完成！"
        echo
        echo "macOS 特定提示:"
        echo "1. 如果遇到权限问题，可能需要在系统偏好设置中允许应用运行"
        echo "2. 构建时可能需要较长时间，请耐心等待"
        echo "3. 打包的应用需要进行代码签名才能在其他 Mac 上运行"
        echo
    else
        echo
        echo "❌ 集成失败"
        echo
        echo "macOS 常见问题解决:"
        echo "1. 权限问题: sudo chown -R \$(whoami) /usr/local/lib/node_modules"
        echo "2. Python 问题: brew install python3"
        echo "3. 编译工具问题: xcode-select --install"
        echo
        exit 1
    fi
}

# 显示帮助
if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    cat << EOF
VSCodium Electron-Updater 集成脚本 (macOS 版)

这是专为 macOS 优化的集成脚本启动器。

使用方法:
  $0                    # 执行集成
  $0 -h, --help        # 显示此帮助信息

macOS 特定要求:
  - Xcode Command Line Tools
  - Node.js 和 npm
  - 推荐安装 Homebrew

注意事项:
  - 首次运行可能需要较长时间
  - 某些操作可能需要管理员权限
  - 构建的应用需要代码签名才能分发
EOF
    exit 0
fi

# 执行主函数
main "$@"