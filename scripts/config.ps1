# =============================================================================
# VSCodium Electron-Updater 集成脚本配置文件
# 适用于 Windows PowerShell
# =============================================================================

# ===== 路径配置 =====
# VSCode/VSCodium 源码路径（必须修改为你的实际路径）
$VSCODE_SOURCE_PATH = "C:\path\to\vscode"

# 补丁文件目录（相对于脚本目录，通常不需要修改）
$PATCHES_DIR = "..\patches-vscodium"

# 日志文件路径（相对于脚本目录，通常不需要修改）
$LOG_FILE = ".\integration.log"

# ===== 更新服务器配置 =====
# 更新服务器地址（修改为你的实际服务器地址）
$UPDATE_SERVER_URL = "http://localhost:3000"

# ===== 版本配置 =====
# 自定义版本号（留空则使用原版本号）
$CUSTOM_VERSION = ""

# ===== 依赖版本配置 =====
# electron-updater 版本
$ELECTRON_UPDATER_VERSION = "^6.1.7"

# electron-log 版本
$ELECTRON_LOG_VERSION = "^5.0.1"

# ===== 构建配置 =====
# 是否在应用补丁后自动运行 npm install
$AUTO_INSTALL_DEPS = $true

# 是否在完成后自动构建
$AUTO_BUILD = $false

# 构建命令（如果启用自动构建）
$BUILD_COMMAND = "npm run compile"

# ===== 高级配置 =====
# Git 应用补丁的额外参数
$GIT_APPLY_ARGS = "--ignore-space-change --ignore-whitespace"

# 是否创建备份
$CREATE_BACKUP = $true

# 备份目录
$BACKUP_DIR = ".\backup"

# =============================================================================
# 注意事项：
# 1. 请根据你的实际情况修改上述配置
# 2. 路径请使用绝对路径或相对于脚本目录的路径
# 3. 修改配置后保存文件即可，无需重启
# 4. Windows 路径请使用双反斜杠 \\ 或正斜杠 /
# =============================================================================