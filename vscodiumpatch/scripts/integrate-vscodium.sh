#!/bin/bash
# =============================================================================
# VSCodium Electron-Updater 集成脚本
# 适用于所有平台 (Linux/macOS/Windows)
# 可在 prepare_vscode.sh 中调用
# =============================================================================

set -e

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 加载配置文件
if [[ -f "$SCRIPT_DIR/config.sh" ]]; then
    source "$SCRIPT_DIR/config.sh"
    echo "✅ 已加载配置文件"
else
    echo "❌ 错误: 配置文件不存在: $SCRIPT_DIR/config.sh"
    echo "请先复制 config.sh.example 为 config.sh 并修改配置"
    exit 1
fi

# 日志函数
log() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" | tee -a "$SCRIPT_DIR/$LOG_FILE"
}

# 检查必要工具
check_requirements() {
    log "检查必要工具..."
    
    if ! command -v git &> /dev/null; then
        log "❌ 错误: Git 未安装"
        exit 1
    fi
    
    if ! command -v npm &> /dev/null; then
        log "❌ 错误: npm 未安装"
        exit 1
    fi
    
    log "✅ 必要工具检查通过"
}

# 检查源码路径
check_source_path() {
    log "检查源码路径: $VSCODE_SOURCE_PATH"
    
    # 如果未设置路径，使用当前目录
    if [[ -z "$VSCODE_SOURCE_PATH" ]] || [[ "$VSCODE_SOURCE_PATH" == "/path/to/vscode" ]]; then
        VSCODE_SOURCE_PATH="$(pwd)"
        log "使用当前目录作为源码路径: $VSCODE_SOURCE_PATH"
    fi
    
    if [[ ! -d "$VSCODE_SOURCE_PATH" ]]; then
        log "❌ 错误: 源码路径不存在: $VSCODE_SOURCE_PATH"
        exit 1
    fi
    
    # 检查是否为 VSCode 源码目录（检查关键文件）
    if [[ ! -f "$VSCODE_SOURCE_PATH/package.json" ]] || [[ ! -f "$VSCODE_SOURCE_PATH/product.json" ]]; then
        log "❌ 错误: 不是有效的 VSCode 源码目录: $VSCODE_SOURCE_PATH"
        log "请确保目录包含 package.json 和 product.json 文件"
        exit 1
    fi
    
    log "✅ 源码路径检查通过"
}

# 创建备份
create_backup() {
    if [[ "$CREATE_BACKUP" == "true" ]]; then
        log "创建备份..."
        local backup_path="$SCRIPT_DIR/$BACKUP_DIR/$(date '+%Y%m%d_%H%M%S')"
        mkdir -p "$backup_path"
        
        cp "$VSCODE_SOURCE_PATH/package.json" "$backup_path/" 2>/dev/null || true
        cp "$VSCODE_SOURCE_PATH/product.json" "$backup_path/" 2>/dev/null || true
        cp "$VSCODE_SOURCE_PATH/src/main.ts" "$backup_path/" 2>/dev/null || true
        
        log "✅ 备份已创建: $backup_path"
    fi
}

# 应用补丁
apply_patches() {
    log "应用补丁..."
    local patches_path="$SCRIPT_DIR/$PATCHES_DIR"
    
    if [[ ! -d "$patches_path" ]]; then
        log "❌ 错误: 补丁目录不存在: $patches_path"
        exit 1
    fi
    
    cd "$VSCODE_SOURCE_PATH"
    
    local patch_files=(
        "electron-updater-dependencies.patch"
        "electron-updater-product-config.patch"
        "electron-updater-main-process.patch"
    )
    
    local success_count=0
    
    for patch_file in "${patch_files[@]}"; do
        local patch_path="$patches_path/$patch_file"
        
        if [[ ! -f "$patch_path" ]]; then
            log "⚠️  警告: 补丁文件不存在: $patch_file"
            continue
        fi
        
        log "应用补丁: $patch_file"
        
        if git apply $GIT_APPLY_ARGS "$patch_path" 2>&1 | tee -a "$SCRIPT_DIR/$LOG_FILE"; then
            log "✅ 补丁应用成功: $patch_file"
            ((success_count++))
        else
            log "❌ 补丁应用失败: $patch_file"
        fi
    done
    
    log "补丁应用完成: $success_count/${#patch_files[@]}"
}

# 配置更新服务器
configure_update_server() {
    if [[ -n "$UPDATE_SERVER_URL" ]] && [[ "$UPDATE_SERVER_URL" != "http://localhost:3000" ]]; then
        log "配置更新服务器地址: $UPDATE_SERVER_URL"
        
        local product_json="$VSCODE_SOURCE_PATH/product.json"
        if [[ -f "$product_json" ]]; then
            if command -v jq &> /dev/null; then
                jq --arg url "$UPDATE_SERVER_URL" '. + {"updateUrl": $url}' "$product_json" > "$product_json.tmp" && mv "$product_json.tmp" "$product_json"
                log "✅ 更新服务器地址配置成功"
            else
                log "⚠️  警告: jq 未安装，请手动配置 product.json 中的 updateUrl"
            fi
        fi
    fi
}

# 安装依赖
install_dependencies() {
    if [[ "$AUTO_INSTALL_DEPS" == "true" ]]; then
        log "安装依赖..."
        cd "$VSCODE_SOURCE_PATH"
        
        if npm install 2>&1 | tee -a "$SCRIPT_DIR/$LOG_FILE"; then
            log "✅ 依赖安装成功"
        else
            log "❌ 依赖安装失败"
            exit 1
        fi
    fi
}

# 构建项目
build_project() {
    if [[ "$AUTO_BUILD" == "true" ]]; then
        log "构建项目..."
        cd "$VSCODE_SOURCE_PATH"
        
        if eval "$BUILD_COMMAND" 2>&1 | tee -a "$SCRIPT_DIR/$LOG_FILE"; then
            log "✅ 项目构建成功"
        else
            log "❌ 项目构建失败"
            exit 1
        fi
    fi
}

# 主函数
main() {
    log "=== VSCodium Electron-Updater 集成开始 ==="
    log "配置信息:"
    log "  源码路径: $VSCODE_SOURCE_PATH"
    log "  更新服务器: $UPDATE_SERVER_URL"
    log "  自动安装依赖: $AUTO_INSTALL_DEPS"
    log "  自动构建: $AUTO_BUILD"
    
    check_requirements
    check_source_path
    create_backup
    apply_patches
    configure_update_server
    install_dependencies
    build_project
    
    log "=== VSCodium Electron-Updater 集成完成 ==="
    log "🎉 集成成功！"
    
    if [[ "$AUTO_BUILD" != "true" ]]; then
        log "下一步: 请运行构建命令编译项目"
    fi
    
    log "然后使用 electron-builder 打包应用"
}

# 显示帮助
if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    cat << EOF
VSCodium Electron-Updater 集成脚本

使用方法:
  $0                    # 使用配置文件中的设置运行
  $0 -h, --help        # 显示此帮助信息

配置:
  请编辑 config.sh 文件修改配置参数
  
主要配置项:
  - VSCODE_SOURCE_PATH: VSCode 源码路径
  - UPDATE_SERVER_URL: 更新服务器地址
  - AUTO_INSTALL_DEPS: 是否自动安装依赖
  - AUTO_BUILD: 是否自动构建
EOF
    exit 0
fi

# 执行主函数
main