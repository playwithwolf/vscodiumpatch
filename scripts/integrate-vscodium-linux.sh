#!/bin/bash
# =============================================================================
# VSCodium Electron-Updater 集成脚本启动器
# 专用于 Linux
# =============================================================================

set -e

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INTEGRATE_SCRIPT="$SCRIPT_DIR/integrate-vscodium.sh"

# 检测 Linux 发行版
detect_distro() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo "$ID"
    elif [[ -f /etc/redhat-release ]]; then
        echo "rhel"
    elif [[ -f /etc/debian_version ]]; then
        echo "debian"
    else
        echo "unknown"
    fi
}

# Linux 特定配置检查
check_linux_requirements() {
    echo "检查 Linux 环境..."
    local distro=$(detect_distro)
    echo "检测到的发行版: $distro"
    
    # 检查基本构建工具
    local missing_tools=()
    
    if ! command -v gcc &> /dev/null && ! command -v clang &> /dev/null; then
        missing_tools+=("gcc 或 clang")
    fi
    
    if ! command -v make &> /dev/null; then
        missing_tools+=("make")
    fi
    
    if ! command -v python3 &> /dev/null; then
        missing_tools+=("python3")
    fi
    
    if ! command -v node &> /dev/null; then
        missing_tools+=("nodejs")
    fi
    
    if ! command -v npm &> /dev/null; then
        missing_tools+=("npm")
    fi
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        echo "❌ 错误: 缺少必要工具: ${missing_tools[*]}"
        echo
        echo "安装建议 ($distro):"
        case $distro in
            ubuntu|debian)
                echo "sudo apt update"
                echo "sudo apt install -y build-essential python3 python3-pip nodejs npm git"
                ;;
            fedora)
                echo "sudo dnf install -y gcc gcc-c++ make python3 python3-pip nodejs npm git"
                ;;
            centos|rhel)
                echo "sudo yum install -y gcc gcc-c++ make python3 python3-pip nodejs npm git"
                echo "# 或者使用 dnf (较新版本)"
                echo "sudo dnf install -y gcc gcc-c++ make python3 python3-pip nodejs npm git"
                ;;
            arch)
                echo "sudo pacman -S base-devel python nodejs npm git"
                ;;
            opensuse*)
                echo "sudo zypper install -y gcc gcc-c++ make python3 python3-pip nodejs npm git"
                ;;
            *)
                echo "请根据你的发行版安装相应的开发工具包"
                ;;
        esac
        exit 1
    fi
    
    # 检查 Node.js 版本
    local node_version=$(node --version | sed 's/v//')
    local major_version=$(echo $node_version | cut -d. -f1)
    
    if [[ $major_version -lt 16 ]]; then
        echo "⚠️  警告: Node.js 版本过低 ($node_version)，建议使用 16.x 或更高版本"
        echo "升级建议:"
        echo "# 使用 NodeSource 仓库"
        echo "curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -"
        echo "sudo apt-get install -y nodejs"
    fi
    
    echo "✅ Linux 环境检查通过"
}

# 设置 Linux 特定的环境变量
setup_linux_env() {
    # 设置编译环境
    export CC=${CC:-gcc}
    export CXX=${CXX:-g++}
    
    # 设置 Python 路径
    if command -v python3 &> /dev/null; then
        export PYTHON="$(which python3)"
    fi
    
    # 增加文件描述符限制（编译时可能需要）
    ulimit -n 8192 2>/dev/null || true
    
    # 设置内存限制（避免 OOM）
    if [[ -z "$NODE_OPTIONS" ]]; then
        export NODE_OPTIONS="--max-old-space-size=4096"
    fi
}

# 检查系统资源
check_system_resources() {
    echo "检查系统资源..."
    
    # 检查内存
    local mem_gb=$(free -g | awk '/^Mem:/{print $2}')
    if [[ $mem_gb -lt 4 ]]; then
        echo "⚠️  警告: 系统内存较少 (${mem_gb}GB)，编译可能较慢或失败"
        echo "建议: 关闭其他应用程序，或增加交换空间"
    fi
    
    # 检查磁盘空间
    local disk_gb=$(df -BG . | awk 'NR==2{print $4}' | sed 's/G//')
    if [[ $disk_gb -lt 10 ]]; then
        echo "⚠️  警告: 磁盘空间不足 (${disk_gb}GB)，可能无法完成编译"
        echo "建议: 清理磁盘空间或选择其他目录"
    fi
    
    echo "✅ 系统资源检查完成"
}

# 主函数
main() {
    echo "==============================================="
    echo "VSCodium Electron-Updater 集成脚本 (Linux)"
    echo "==============================================="
    echo
    
    # Linux 环境检查
    check_linux_requirements
    
    # 系统资源检查
    check_system_resources
    
    # 设置环境
    setup_linux_env
    
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
        echo "🎉 Linux 集成完成！"
        echo
        echo "Linux 特定提示:"
        echo "1. 如果编译过程中出现内存不足，可以增加交换空间"
        echo "2. 某些发行版可能需要额外的开发包"
        echo "3. 打包的应用可以在大多数 Linux 发行版上运行"
        echo
    else
        echo
        echo "❌ 集成失败"
        echo
        echo "Linux 常见问题解决:"
        echo "1. 权限问题: sudo chown -R \$USER ~/.npm"
        echo "2. 依赖问题: 安装相应的开发包"
        echo "3. 内存不足: 增加交换空间或关闭其他程序"
        echo "4. Node.js 版本: 升级到 LTS 版本"
        echo
        exit 1
    fi
}

# 显示帮助
if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    cat << EOF
VSCodium Electron-Updater 集成脚本 (Linux 版)

这是专为 Linux 优化的集成脚本启动器。

使用方法:
  $0                    # 执行集成
  $0 -h, --help        # 显示此帮助信息

Linux 特定要求:
  - 构建工具链 (gcc/clang, make)
  - Python 3
  - Node.js 16+ 和 npm
  - Git

系统要求:
  - 内存: 4GB+ 推荐
  - 磁盘: 10GB+ 可用空间

支持的发行版:
  - Ubuntu/Debian
  - Fedora
  - CentOS/RHEL
  - Arch Linux
  - openSUSE
  - 其他主流发行版
EOF
    exit 0
fi

# 执行主函数
main "$@"