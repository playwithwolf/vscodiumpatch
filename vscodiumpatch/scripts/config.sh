#!/bin/bash
# =============================================================================
# VSCodium Electron-Updater 集成脚本配置文件
# 适用于 Linux/macOS
# =============================================================================

# ===== 路径配置 =====
# VSCode/VSCodium 源码路径（自动检测当前工作目录，或手动设置）
# 如果在 prepare_vscode.sh 中调用，会自动使用当前目录
VSCODE_SOURCE_PATH="../../vscode"

# 补丁文件目录（相对于脚本目录）
# 如果 vscodiumpatch 在 VSCodium 根目录下，使用相对路径
PATCHES_DIR="../patches-vscodium"

# 日志文件路径（相对于脚本目录，通常不需要修改）
LOG_FILE="./integration.log"

# ===== 更新服务器配置 =====
# 更新服务器地址（修改为你的实际服务器地址）
UPDATE_SERVER_URL="https://192.168.0.3:3000"

# ===== 版本配置 =====
# 自定义版本号（留空则使用原版本号）
CUSTOM_VERSION="1.0.1"

# ===== 依赖版本配置 =====
# electron-updater 版本
ELECTRON_UPDATER_VERSION="^6.1.7"

# electron-log 版本
ELECTRON_LOG_VERSION="^5.0.1"

# ===== 构建配置 =====
# 是否在应用补丁后自动运行 npm install
# 在 prepare_vscode.sh 中调用时建议设为 false，由 VSCodium 构建流程处理
AUTO_INSTALL_DEPS=false

# 是否在完成后自动构建
# 在 prepare_vscode.sh 中调用时建议设为 false，由 VSCodium 构建流程处理
AUTO_BUILD=false

# 构建命令（如果启用自动构建）
BUILD_COMMAND="npm run compile"

# ===== 高级配置 =====
# 补丁应用模式选择
# direct: 使用直接文件操作（推荐，避免行尾符问题）
# git: 使用 git apply 命令
# auto: 自动选择（优先直接模式，失败时使用 git 模式）
PATCH_MODE="direct"

# Git 应用补丁的额外参数
# 注意：--ignore-cr-at-eol 在某些 Git 版本中不支持，已移除
GIT_APPLY_ARGS="--ignore-space-change --ignore-whitespace"

# 是否创建备份
CREATE_BACKUP=true

# 备份目录
BACKUP_DIR="./backup"

# =============================================================================
# 注意事项：
# 1. 请根据你的实际情况修改上述配置
# 2. 路径请使用绝对路径或相对于脚本目录的路径
# 3. 修改配置后保存文件即可，无需重启
# =============================================================================