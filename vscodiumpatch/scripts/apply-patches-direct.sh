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

# 检查并安装依赖
install_dependencies() {
    log "强制安装 electron-updater 和 electron-log 依赖..."
    local package_json="$VSCODE_SOURCE_PATH/package.json"
    
    if [[ ! -f "$package_json" ]]; then
        log "❌ 错误: package.json 不存在: $package_json"
        return 1
    fi
    
    # 检查依赖是否已添加到package.json
    local has_electron_updater=$(grep -c '"electron-updater"' "$package_json" || echo "0")
    local has_electron_log=$(grep -c '"electron-log"' "$package_json" || echo "0")
    
    if [[ "$has_electron_updater" -eq 0 ]] || [[ "$has_electron_log" -eq 0 ]]; then
        log "❌ 错误: package.json 中缺少必要的依赖项"
        log "   electron-updater: $([[ "$has_electron_updater" -gt 0 ]] && echo "✅" || echo "❌")"
        log "   electron-log: $([[ "$has_electron_log" -gt 0 ]] && echo "✅" || echo "❌")"
        return 1
    fi
    
    log "✅ package.json 依赖检查通过，开始强制安装指定版本的依赖..."
    
    # 切换到源码目录
    local current_dir=$(pwd)
    cd "$VSCODE_SOURCE_PATH"
    
    # 强制安装指定版本的依赖
    log "正在安装 electron-updater@^6.1.7 和 electron-log@^5.0.1..."
    if npm install electron-updater@^6.1.7 electron-log@^5.0.1; then
        log "✅ 依赖安装成功"
        # 验证安装结果
        if [[ -d "node_modules/electron-updater" ]] && [[ -d "node_modules/electron-log" ]]; then
            log "✅ 验证通过: electron-updater和electron-log已成功安装"
        else
            log "⚠️  警告: 依赖安装可能不完整"
        fi
    else
        log "❌ 依赖安装失败，请检查网络连接或手动运行: npm install electron-updater@^6.1.7 electron-log@^5.0.1"
        return 1
    fi
    
    cd "$current_dir"
    log "✅ 依赖安装完成"
    return 0
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
    
    # 检查是否已经添加了electron-updater导入
    if grep -q "import { autoUpdater } from 'electron-updater';" "$main_ts"; then
        log "⚠️  main.ts 已包含 electron-updater 代码，跳过main.ts修改"
    else
        log "开始修改 main.ts 文件..."
        # main.ts修改逻辑保持不变
    fi
    
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
    
    # 如果main.ts已经修改过，直接返回成功
    if grep -q "import { autoUpdater } from 'electron-updater';" "$main_ts"; then
        log "✅ 所有修改完成"
        return 0
    fi
    
    # 创建临时文件
    local temp_file="$main_ts.tmp"
    
    # 添加导入语句
    sed '/import { localize } from/a\
import { autoUpdater } from '"'"'electron-updater'"'"';\
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
    
    if apply_package_json_code; then
        success_count=$((success_count + 1))
    fi
    
    # 更新 package.json 版本号
    update_package_version
    
    if apply_product_json_code; then
        success_count=$((success_count + 1))
    fi
    
    if apply_main_ts_patch; then
        success_count=$((success_count + 1))
    fi
    
    log "补丁应用完成: $success_count/3"
    
    # 检查依赖安装情况
    install_dependencies
    
    log "=== VSCodium 补丁应用结束 ==="
}

# 运行主函数（如果直接执行脚本）
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

# 注意：此脚本设计为可以被source调用，执行完成后不会退出shell