#!/bin/bash
# =============================================================================
# VSCodium 补丁直接应用脚本 (不使用 git apply)
# 使用直接文件操作方式应用补丁，避免行尾符问题
# =============================================================================

set -e

# 获取脚本目录（绝对路径）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 加载配置文件
if [[ -f "$SCRIPT_DIR/config.sh" ]]; then
    source "$SCRIPT_DIR/config.sh"
    echo "✅ 已加载配置文件"
else
    echo "❌ 错误: 配置文件不存在: $SCRIPT_DIR/config.sh"
    return 1
fi

# 日志函数
log() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" | tee -a "$SCRIPT_DIR/$LOG_FILE"
}

# 检查源码路径
check_source_path() {
    local current_dir="$(pwd)"
    
    # 首先检查配置文件中设置的路径
    if [[ -n "$VSCODE_SOURCE_PATH" ]] && [[ -f "$VSCODE_SOURCE_PATH/package.json" ]] && [[ -f "$VSCODE_SOURCE_PATH/product.json" ]]; then
        log "使用配置的源码路径: $VSCODE_SOURCE_PATH"
    # 检查当前目录是否为 VSCode 源码目录
    elif [[ -f "./package.json" ]] && [[ -f "./product.json" ]]; then
        VSCODE_SOURCE_PATH="."
        log "使用当前目录作为源码路径: $VSCODE_SOURCE_PATH"
    elif [[ -f "./vscode/package.json" ]] && [[ -f "./vscode/product.json" ]]; then
        VSCODE_SOURCE_PATH="./vscode"
        log "使用 vscode 子目录作为源码路径: $VSCODE_SOURCE_PATH"
    else
        log "❌ 错误: 源码路径不是有效的 VSCode 目录"
        log "   配置路径: $VSCODE_SOURCE_PATH"
        log "   当前目录: $current_dir"
        log "   请确保在 VSCode 源码目录或其父目录中运行此脚本"
        log "   需要的文件: package.json, product.json"
        return 1
    fi
    
    log "✅ 源码路径检查通过: $VSCODE_SOURCE_PATH"
}

# 创建备份
create_backup() {
    if [[ "$CREATE_BACKUP" == "true" ]]; then
        log "创建备份..."
        local backup_path="$SCRIPT_DIR/$BACKUP_DIR/$(date '+%Y%m%d_%H%M%S')"
        mkdir -p "$backup_path"
        
        cp "$VSCODE_SOURCE_PATH/package.json" "$backup_path/" 2>/dev/null || true
        cp "$VSCODE_SOURCE_PATH/product.json" "$backup_path/" 2>/dev/null || true
        cp "$VSCODE_SOURCE_PATH/src/vs/code/electron-main/main.ts" "$backup_path/" 2>/dev/null || true
        
        log "✅ 备份已创建: $backup_path"
    fi
}

# 应用 package.json 补丁
apply_package_json_patch() {
    log "应用 package.json 补丁..."
    local package_json="$VSCODE_SOURCE_PATH/package.json"
    local patch_file="$SCRIPT_DIR/../patches-vscodium/electron-updater-dependencies.patch"
    
    if [[ ! -f "$package_json" ]]; then
        log "❌ 错误: package.json 不存在: $package_json"
        return 1
    fi
    
    if [[ ! -f "$patch_file" ]]; then
        log "❌ 错误: 补丁文件不存在: $patch_file"
        return 1
    fi
    
    # 检查是否已经应用过补丁
    if grep -q '"electron-updater"' "$package_json"; then
        log "⚠️  package.json 补丁已存在，跳过"
        return 0
    fi
    
    # 切换到源码目录并应用补丁
    local current_dir=$(pwd)
    cd "$VSCODE_SOURCE_PATH"
    if patch -p1 --binary --ignore-whitespace < "$patch_file"; then
        log "✅ package.json 补丁应用成功"
        cd "$current_dir"
        return 0
    else
        log "❌ package.json 补丁应用失败"
        cd "$current_dir"
        return 1
    fi
}

# 应用 product.json 补丁
apply_product_json_patch() {
    log "应用 product.json 补丁..."
    local product_json="$VSCODE_SOURCE_PATH/product.json"
    local patch_file="$SCRIPT_DIR/../patches-vscodium/electron-updater-product-config.patch"
    
    if [[ ! -f "$product_json" ]]; then
        log "❌ 错误: product.json 不存在: $product_json"
        return 1
    fi
    
    if [[ ! -f "$patch_file" ]]; then
        log "❌ 错误: 补丁文件不存在: $patch_file"
        return 1
    fi
    
    # 检查是否已经应用了我们的updateUrl配置
    if grep -q '"updateUrl": "http://192.168.0.3:3000"' "$product_json"; then
        log "⚠️  product.json 补丁已存在，跳过"
        return 0
    fi
    
    # 切换到源码目录并应用补丁
    local current_dir=$(pwd)
    cd "$VSCODE_SOURCE_PATH"
    if patch -p1 --binary --ignore-whitespace < "$patch_file"; then
        log "✅ product.json 补丁应用成功"
        cd "$current_dir"
        return 0
    else
        log "❌ product.json 补丁应用失败"
        cd "$current_dir"
        return 1
    fi
}

# 应用 main.ts 补丁
apply_main_ts_patch() {
    log "应用 main.ts 补丁..."
    local main_ts="$VSCODE_SOURCE_PATH/src/vs/code/electron-main/main.ts"
    local patch_file="../patches-vscodium/electron-updater-main-process.patch"
    
    if [[ ! -f "$main_ts" ]]; then
        log "❌ 错误: main.ts 不存在: $main_ts"
        return 1
    fi
    
    if [[ ! -f "$patch_file" ]]; then
        log "❌ 错误: 补丁文件不存在: $patch_file"
        return 1
    fi
    
    # 检查是否已经应用过补丁
    if grep -q 'electron-updater' "$main_ts"; then
        log "⚠️  main.ts 补丁已存在，跳过"
        return 0
    fi
    
    # 应用补丁
    local current_dir=$(pwd)
    local absolute_patch_file="$current_dir/$patch_file"
    cd "$VSCODE_SOURCE_PATH"
    if patch -p1 --binary -i "$absolute_patch_file"; then
        log "✅ main.ts 补丁应用成功"
    else
        log "❌ main.ts 补丁应用失败"
        return 1
    fi
}

# 主函数
main() {
    log "=== VSCodium 补丁应用开始 (直接模式) ==="
    log "配置信息:"
    log "  源码路径: $VSCODE_SOURCE_PATH"
    log "  更新服务器: $UPDATE_SERVER_URL"
    
    # 检查源码路径
    check_source_path
    
    # 创建备份
    create_backup
    
    # 应用补丁
    local success_count=0
    
    if apply_package_json_patch; then
        success_count=$((success_count + 1))
    fi
    
    if apply_product_json_patch; then
        success_count=$((success_count + 1))
    fi
    
    if apply_main_ts_patch; then
        success_count=$((success_count + 1))
    fi
    
    log "补丁应用完成: $success_count/3"
    log "=== VSCodium 补丁应用结束 ==="
}

# 运行主函数（如果直接执行脚本）
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

# 注意：此脚本设计为可以被source调用，执行完成后不会退出shell