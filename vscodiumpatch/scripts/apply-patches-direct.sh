#!/bin/bash
# =============================================================================
# VSCodium 补丁直接应用脚本 (不使用 git apply)
# 使用直接文件操作方式应用补丁，避免行尾符问题
# =============================================================================
#
# 重要说明 - 新的依赖处理机制:
# 1. 此脚本会将 electron-updater 和 electron-log 依赖添加到 VSCode 源码的 package.json dependencies 中
# 2. 这确保了在 VSCode 构建过程中，这些依赖会被正确打包到 resources/app/node_modules
# 3. 解决了 "Named export 'autoUpdater' not found" 错误
# 4. 不需要手动运行 npm install，构建过程会自动处理依赖安装
# 5. integrate-vscodium.sh 中的 install_dependencies 函数是独立的，用于其他目的

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

# # 应用 package.json 补丁
# apply_package_json_patch() {
#     log "应用 package.json 补丁..."
#     local package_json="$VSCODE_SOURCE_PATH/package.json"
#     local patch_file="$SCRIPT_DIR/../patches-vscodium/electron-updater-dependencies.patch"
    
#     if [[ ! -f "$package_json" ]]; then
#         log "❌ 错误: package.json 不存在: $package_json"
#         return 1
#     fi
    
#     if [[ ! -f "$patch_file" ]]; then
#         log "❌ 错误: 补丁文件不存在: $patch_file"
#         return 1
#     fi
    
#     # 检查是否已经应用过补丁
#     if grep -q '"electron-updater"' "$package_json"; then
#         log "⚠️  package.json 补丁已存在，跳过"
#         return 0
#     fi
    
#     # 切换到源码目录并应用补丁
#     local current_dir=$(pwd)
#     cd "$VSCODE_SOURCE_PATH"
#     if patch -p1 --binary --ignore-whitespace < "$patch_file"; then
#         log "✅ package.json 补丁应用成功"
#         cd "$current_dir"
#         return 0
#     else
#         log "❌ package.json 补丁应用失败"
#         cd "$current_dir"
#         return 1
#     fi
# }

# 更新 package.json 中的 version 字段
update_package_version() {
    log "更新 package.json 版本号..."
    local package_json="$VSCODE_SOURCE_PATH/package.json"
    local custom_version="$CUSTOM_VERSION"
    
    # 如果没有设置自定义版本，跳过版本更新
    if [[ -z "$custom_version" ]]; then
        log "未设置 CUSTOM_VERSION，跳过版本更新"
        return 0
    fi
    
    if [[ ! -f "$package_json" ]]; then
        log "❌ 错误: package.json 不存在: $package_json"
        return 1
    fi
    
    # 检查是否已经是目标版本
    if grep -q "\"version\": \"$custom_version\"" "$package_json"; then
        log "⚠️  package.json 版本已是 $custom_version，跳过"
        return 0
    fi
    
    # 使用 sed 替换 version 字段
    if sed -i.tmp "s/\"version\": \"[^\"]*\"/\"version\": \"$custom_version\"/g" "$package_json"; then
        rm -f "$package_json.tmp" 2>/dev/null || true
        log "✅ package.json 版本更新成功: $custom_version"
        return 0
    else
        log "❌ package.json 版本更新失败"
        return 1
    fi
}

# 硬编码方式添加 package.json 依赖
apply_package_json_code() {
    log "硬编码方式添加 package.json 依赖..."
    local package_json="$VSCODE_SOURCE_PATH/package.json"
    
    if [[ ! -f "$package_json" ]]; then
        log "❌ 错误: package.json 不存在: $package_json"
        return 1
    fi
    
    # 检查是否已经添加了electron-updater依赖
    if grep -q '"electron-updater"' "$package_json"; then
        log "⚠️  package.json 已包含 electron-updater 依赖，跳过"
        return 0
    fi
    
    # 在@types/debug行后添加electron-updater和electron-log依赖
    if sed -i '/"@types\/debug": "\^4.1.5",/a\    "electron-updater": "^6.1.7",\n    "electron-log": "^5.0.1",' "$package_json"; then
        log "✅ package.json 依赖添加成功"
        return 0
    else
        log "❌ package.json 依赖添加失败"
        return 1
    fi
}

# 确保依赖强制添加到package.json的dependencies中
ensure_dependencies_in_package_json() {
    log "强制确保 electron-updater 和 electron-log 依赖添加到 package.json 的 dependencies..."
    local package_json="$VSCODE_SOURCE_PATH/package.json"
    
    if [[ ! -f "$package_json" ]]; then
        log "❌ 错误: package.json 不存在: $package_json"
        return 1
    fi
    
    # 检查dependencies部分是否存在这两个依赖
    local has_electron_updater
    has_electron_updater=$(grep -A 50 '"dependencies"' "$package_json" | grep -c '"electron-updater"' 2>/dev/null || echo "0")
    has_electron_updater=$(echo "$has_electron_updater" | tr -d '\n\r ')
    local has_electron_log
    has_electron_log=$(grep -A 50 '"dependencies"' "$package_json" | grep -c '"electron-log"' 2>/dev/null || echo "0")
    has_electron_log=$(echo "$has_electron_log" | tr -d '\n\r ')
    
    local needs_update=false
    
    log "注意: 如果依赖同时存在于 dependencies 中，这是允许的，不会移除"
    
    # 强制添加electron-updater到dependencies（无论是否已存在）
    log "强制添加/更新 electron-updater 到 dependencies..."
    local temp_file="${package_json}.tmp"
    
    # 先移除dependencies中可能存在的electron-updater（只在dependencies部分移除）
     awk '
         in_deps && /"electron-updater":/ { next }
         /"dependencies": {/ { in_deps=1; print; next }
         /^  },?$/ && in_deps { in_deps=0 }
         { print }
     ' "$package_json" > "${temp_file}.1"
    
    # 然后添加新的electron-updater到dependencies
    awk '
        /"dependencies": {/ {
            print $0
            print "    \"electron-updater\": \"^6.1.7\","
            next
        }
        { print }
    ' "${temp_file}.1" > "$temp_file" && mv "$temp_file" "$package_json"
    rm -f "${temp_file}.1"
    needs_update=true
    
    # 强制添加electron-log到dependencies（无论是否已存在）
    log "强制添加/更新 electron-log 到 dependencies..."
    
    # 先移除dependencies中可能存在的electron-log（只在dependencies部分移除）
     awk '
         in_deps && /"electron-log":/ { next }
         /"dependencies": {/ { in_deps=1; print; next }
         /^  },?$/ && in_deps { in_deps=0 }
         { print }
     ' "$package_json" > "${temp_file}.1"
    
    # 然后添加新的electron-log到dependencies
    awk '
        /"dependencies": {/ {
            print $0
            print "    \"electron-log\": \"^5.0.1\","
            next
        }
        { print }
    ' "${temp_file}.1" > "$temp_file" && mv "$temp_file" "$package_json"
     rm -f "${temp_file}.1"
    
    if [[ "$needs_update" == "true" ]]; then
        log "✅ 依赖已添加到 package.json 的 dependencies 部分"
        # 验证添加结果
        local final_updater=$(grep -A 50 '"dependencies"' "$package_json" | grep -c '"electron-updater"' || echo "0")
        local final_log=$(grep -A 50 '"dependencies"' "$package_json" | grep -c '"electron-log"' || echo "0")
        
        if [[ "$final_updater" -gt 0 ]] && [[ "$final_log" -gt 0 ]]; then
            log "✅ 验证通过: 依赖已正确添加到 dependencies 部分"
        else
            log "❌ 验证失败: 依赖添加可能不成功"
            return 1
        fi
    else
        log "✅ 依赖已存在于 package.json 的 dependencies 部分"
    fi
    
    return 0
}

# 检查并安装依赖（用于开发测试）
install_dependencies_for_testing() {
    log "为测试目的安装 electron-updater 和 electron-log 依赖..."
    local package_json="$VSCODE_SOURCE_PATH/package.json"
    
    if [[ ! -f "$package_json" ]]; then
        log "❌ 错误: package.json 不存在: $package_json"
        return 1
    fi
    
    # 切换到源码目录
    local current_dir=$(pwd)
    cd "$VSCODE_SOURCE_PATH"
    
    # 安装指定版本的依赖（仅用于测试验证）
    log "正在安装 electron-updater@^6.1.7 和 electron-log@^5.0.1 用于测试..."
    if npm install electron-updater@^6.1.7 electron-log@^5.0.1 --save; then
        log "✅ 测试依赖安装成功"
        # 验证安装结果
        if [[ -d "node_modules/electron-updater" ]] && [[ -d "node_modules/electron-log" ]]; then
            log "✅ 验证通过: electron-updater和electron-log已成功安装到node_modules"
        else
            log "⚠️  警告: 依赖安装可能不完整"
        fi
    else
        log "❌ 测试依赖安装失败，请检查网络连接"
        cd "$current_dir"
        return 1
    fi
    
    cd "$current_dir"
    log "✅ 测试依赖安装完成"
    return 0
}

# 应用 product.json 补丁
# apply_product_json_patch() {
#     log "应用 product.json 补丁..."
#     local product_json="$VSCODE_SOURCE_PATH/product.json"
#     local patch_file="$SCRIPT_DIR/../patches-vscodium/electron-updater-product-config.patch"
    
#     if [[ ! -f "$product_json" ]]; then
#         log "❌ 错误: product.json 不存在: $product_json"
#         return 1
#     fi
    
#     if [[ ! -f "$patch_file" ]]; then
#         log "❌ 错误: 补丁文件不存在: $patch_file"
#         return 1
#     fi
    
#     # 检查是否已经应用了我们的updateUrl配置
#     if grep -q '"updateUrl": "http://192.168.0.3:3000"' "$product_json"; then
#         log "⚠️  product.json 补丁已存在，跳过"
#         return 0
#     fi
    
#     # 切换到源码目录并应用补丁
#     local current_dir=$(pwd)
#     cd "$VSCODE_SOURCE_PATH"
#     if patch -p1 --binary --ignore-whitespace < "$patch_file"; then
#         log "✅ product.json 补丁应用成功"
#         cd "$current_dir"
#         return 0
#     else
#         log "❌ product.json 补丁应用失败"
#         cd "$current_dir"
#         return 1
#     fi
# }

# 硬编码方式应用 main.ts 和 product.json 修改
apply_product_json_code() {
    log "硬编码方式修改 main.ts 和 product.json 文件..."
    local main_ts="$VSCODE_SOURCE_PATH/src/vs/code/electron-main/main.ts"
    local product_json="$VSCODE_SOURCE_PATH/product.json"
    
    if [[ ! -f "$main_ts" ]]; then
        log "❌ 错误: main.ts 不存在: $main_ts"
        return 1
    fi
    
    if [[ ! -f "$product_json" ]]; then
        log "❌ 错误: product.json 不存在: $product_json"
        return 1
    fi
    
    # # 检查是否已经添加了electron-updater导入
    # if grep -q "import { autoUpdater } from 'electron-updater';" "$main_ts"; then
    #     log "⚠️  main.ts 已包含 electron-updater 代码，跳过main.ts修改"
    # else
    #     log "开始修改 main.ts 文件..."
    #     # main.ts修改逻辑保持不变
    # fi
    
    # 检查并更新product.json中的updateUrl
    if grep -q '"updateUrl": "http://192.168.0.3:3000"' "$product_json"; then
        log "⚠️  product.json updateUrl 已更新，跳过product.json修改"
    else
        log "开始修改 product.json 文件..."
        # 使用sed替换updateUrl
        sed -i 's|"updateUrl": "https://raw.githubusercontent.com/VSCodium/versions/refs/heads/master"|"updateUrl": "http://192.168.0.3:3000"|g' "$product_json"
        if grep -q '"updateUrl": "http://192.168.0.3:3000"' "$product_json"; then
            log "✅ product.json updateUrl 更新成功"
        else
            log "❌ product.json updateUrl 更新失败"
            return 1
        fi
    fi
    
    # # 如果main.ts已经修改过，直接返回成功
    # if grep -q "import { autoUpdater } from 'electron-updater';" "$main_ts"; then
    #     log "✅ 所有修改完成"
    #     return 0
    # fi
    
    # 创建临时文件
    local temp_file="$main_ts.tmp"
    
    # 添加导入语句
    sed '/import { localize } from/a\
import electronUpdater from '"'"'electron-updater'"'"';\
import { autoUpdater } = electronUpdater;\
import * as log from '"'"'electron-log'"'"';\
import type { UpdateInfo, ProgressInfo } from '"'"'electron-updater'"'"';' "$main_ts" > "$temp_file"
    
    # 在main()方法中添加setupAutoUpdater调用
    sed -i '/this\.startup();/a\			// Initialize auto updater\
			this.setupAutoUpdater();' "$temp_file"
    
    # 在类的末尾添加setupAutoUpdater方法
    sed -i '/\/\/#endregion/i\
	private setupAutoUpdater(): void {\
		// Configure electron-log for auto-updater\
		log.transports.file.level = '"'"'info'"'"';\
		autoUpdater.logger = log;\
		\
		// Set update server URL\
		autoUpdater.setFeedURL({\
			provider: '"'"'generic'"'"',\
			url: '"'"'http://192.168.0.3:3000'"'"'\
		});\
		\
		autoUpdater.on('"'"'checking-for-update'"'"', () => {\
			log.info('"'"'Checking for updates...'"'"');\
		});\
		\
		autoUpdater.on('"'"'update-available'"'"', (info: UpdateInfo) => {\
			log.info('"'"'Update available:'"'"', info.version);\
		});\
		\
		autoUpdater.on('"'"'update-not-available'"'"', (info: UpdateInfo) => {\
			log.info('"'"'Update not available, current version:'"'"', info.version);\
		});\
		\
		autoUpdater.on('"'"'error'"'"', (err: Error) => {\
			log.error('"'"'Auto updater error:'"'"', err);\
		});\
		\
		autoUpdater.on('"'"'download-progress'"'"', (progressObj: ProgressInfo) => {\
			let logMessage = `Download speed: ${progressObj.bytesPerSecond}`;\
			logMessage += ` - Downloaded ${progressObj.percent}%`;\
			logMessage += ` (${progressObj.transferred}/${progressObj.total})`;\
			log.info(logMessage);\
		});\
		\
		autoUpdater.on('"'"'update-downloaded'"'"', (info: UpdateInfo) => {\
			log.info('"'"'Update downloaded, ready to install:'"'"', info.version);\
			// You can show notification or dialog here\
			// autoUpdater.quitAndInstall();\
		});\
		\
		// Check for updates on startup (delayed to ensure app is fully loaded)\
		setTimeout(() => {\
			// Only check for updates in production builds\
			if (process.env.NODE_ENV !== '"'"'development'"'"') {\
				autoUpdater.checkForUpdatesAndNotify().catch((err: Error) => {\
					log.error('"'"'Failed to check for updates:'"'"', err);\
				});\
			}\
		}, 5000); // Delay 5 seconds to ensure app is fully started\
	}\
' "$temp_file"
    
    # 替换原文件
    if mv "$temp_file" "$main_ts"; then
        log "✅ main.ts 硬编码修改成功"
        return 0
    else
        log "❌ main.ts 硬编码修改失败"
        rm -f "$temp_file"
        return 1
    fi
}

# 应用 main.ts 补丁
# apply_main_ts_patch() {
#     log "应用 main.ts 补丁..."
#     local main_ts="$VSCODE_SOURCE_PATH/src/vs/code/electron-main/main.ts"
#     local patch_file="../patches-vscodium/electron-updater-main-process.patch"
    
#     if [[ ! -f "$main_ts" ]]; then
#         log "❌ 错误: main.ts 不存在: $main_ts"
#         return 1
#     fi
    
#     if [[ ! -f "$patch_file" ]]; then
#         log "❌ 错误: 补丁文件不存在: $patch_file"
#         return 1
#     fi
    
#     # 检查是否已经应用过补丁
#     if grep -q 'electron-updater' "$main_ts"; then
#         log "⚠️  main.ts 补丁已存在，跳过"
#         return 0
#     fi
    
#     # 应用补丁
#     local current_dir=$(pwd)
#     local absolute_patch_file="$current_dir/$patch_file"
#     cd "$VSCODE_SOURCE_PATH"
#     if patch -p1 --binary -i "$absolute_patch_file"; then
#         log "✅ main.ts 补丁应用成功"
#     else
#         log "❌ main.ts 补丁应用失败"
#         return 1
#     fi
# }

# 测试依赖添加功能（仅用于验证）
test_dependency_addition() {
    log "=== 测试依赖添加功能 ==="
    
    if [[ -z "$VSCODE_SOURCE_PATH" ]]; then
        log "❌ 错误: VSCODE_SOURCE_PATH 未设置"
        return 1
    fi
    
    local package_json="$VSCODE_SOURCE_PATH/package.json"
    if [[ ! -f "$package_json" ]]; then
        log "❌ 错误: package.json 不存在: $package_json"
        return 1
    fi
    
    # 备份原始文件
    cp "$package_json" "${package_json}.backup"
    log "✅ 已备份原始 package.json"
    
    # 测试依赖添加
    if ensure_dependencies_in_package_json; then
        log "✅ 依赖添加测试成功"
        
        # 显示添加的依赖
        log "当前 dependencies 中的相关依赖:"
        grep -A 50 '"dependencies"' "$package_json" | grep -E '"electron-(updater|log)"' || log "未找到相关依赖"
        
        # 询问是否恢复备份
        echo "是否恢复原始 package.json? (y/n)"
        read -r restore_backup
        if [[ "$restore_backup" == "y" ]] || [[ "$restore_backup" == "Y" ]]; then
            mv "${package_json}.backup" "$package_json"
            log "✅ 已恢复原始 package.json"
        else
            rm "${package_json}.backup"
            log "✅ 保留修改后的 package.json，已删除备份"
        fi
    else
        log "❌ 依赖添加测试失败"
        # 恢复备份
        mv "${package_json}.backup" "$package_json"
        log "✅ 已恢复原始 package.json"
        return 1
    fi
    
    log "=== 测试完成 ==="
    return 0
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
    
    if apply_package_json_code; then
        success_count=$((success_count + 1))
    fi
    
    # 更新 package.json 版本号
    update_package_version
    
    if apply_product_json_code; then
        success_count=$((success_count + 1))
    fi
    
    # if apply_main_ts_patch; then
    #     success_count=$((success_count + 1))
    # fi
    
    log "补丁应用完成: $success_count/2"
    
    # 确保依赖正确添加到package.json
    if ! ensure_dependencies_in_package_json; then
        log "❌ 依赖添加到package.json失败"
        return 1
    fi
    
    # 安装依赖以确保编译成功（可选，失败不影响补丁应用）
    if ! install_dependencies_for_testing; then
        log "⚠️  依赖安装失败，但补丁已成功应用。可以稍后手动安装依赖或在构建时自动安装。"
    fi
    
    log "=== VSCodium 补丁应用结束 ==="
}

# 运行主函数（如果直接执行脚本）
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # 命令行参数处理
    if [[ "$1" == "--test-deps" ]] || [[ "$1" == "-t" ]]; then
        log "运行依赖添加测试模式..."
        test_dependency_addition
    else
        # 执行主函数
        main "$@"
    fi
fi

# 使用说明:
# 1. 正常模式: ./apply-patches-direct.sh
#    - 应用所有补丁并添加依赖到 package.json
#    - 适用于在 prepare_vscode.sh 中调用
#
# 2. 测试模式: ./apply-patches-direct.sh --test-deps
#    - 仅测试依赖添加功能
#    - 会备份并恢复 package.json
#    - 用于验证脚本功能是否正常

# 注意：此脚本设计为可以被source调用，执行完成后不会退出shell