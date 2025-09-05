# VSCodium 自动更新集成操作指南

## 📋 简介

本指南提供 VSCodium 集成 electron-updater 自动更新功能的完整操作步骤。

## 📁 项目放置位置

**重要说明：** `vscodiumpatch` 项目应该放置在 VSCodium 源码根目录下，与 `build.sh` 脚本同级。

```
vscodium/                    # VSCodium 源码根目录
├── build.sh                # VSCodium 构建脚本
├── prepare_vscode.sh       # VSCodium 源码准备脚本
├── patches/                # VSCodium 官方补丁目录
├── vscodiumpatch/          # 本项目目录（放置在这里）
│   ├── patches/            # electron-updater 补丁文件
│   ├── patches-vscodium/   # VSCodium 特定补丁文件
│   └── scripts/            # 集成脚本
└── ...
```

## 🔄 与构建流程的集成

VSCodium 的 `build.sh` 脚本会调用 `prepare_vscode.sh`，该脚本会自动应用 `patches/` 目录下的所有 `.patch` 文件。我们的集成方案通过以下方式工作：

1. **补丁应用时机**：在 VSCodium 执行 `prepare_vscode.sh` 之前运行我们的集成脚本
2. **补丁放置**：将 electron-updater 补丁复制到 VSCodium 的 `patches/` 目录
3. **自动集成**：VSCodium 构建流程会自动应用这些补丁

## 🚀 完整操作流程

### 第一步：准备 VSCodium 源码和项目

```bash
# 克隆 VSCodium 源码（如果还没有）
git clone https://github.com/VSCodium/vscodium.git
cd vscodium

# 将 vscodiumpatch 项目放置到 VSCodium 根目录下
# 可以通过 git clone、复制文件夹等方式
git clone https://github.com/your-repo/vscodiumpatch.git
# 或者
# cp -r /path/to/vscodiumpatch ./
```

### 第二步：配置集成参数

由于项目已放置在 VSCodium 根目录下，大部分配置会自动检测。你只需要根据操作系统编辑对应的快速集成脚本：

**Windows 用户：**
编辑 `vscodiumpatch/scripts/quick-integrate.ps1` 文件顶部的配置：
```powershell
# 请修改以下配置为你的实际值
$VSCODIUM_SOURCE_PATH = ".."                      # VSCodium 源码路径（相对路径，指向上级目录）
$UPDATE_SERVER_URL = "http://localhost:3000"       # 更新服务器地址
$CUSTOM_VERSION = ""                               # 自定义版本号（留空使用原版本）
```

**Linux/macOS 用户：**
编辑 `vscodiumpatch/scripts/quick-integrate.sh` 文件顶部的配置：
```bash
# 请修改以下配置为你的实际值
VSCODIUM_SOURCE_PATH=".."                         # VSCodium 源码路径（相对路径，指向上级目录）
UPDATE_SERVER_URL="http://localhost:3000"         # 更新服务器地址
CUSTOM_VERSION=""                                 # 自定义版本号（留空使用原版本）
```

### 第三步：执行集成（在构建 VSCodium 之前）

**重要：** 必须在执行 VSCodium 的 `build.sh` 之前运行集成脚本，这样补丁才能被正确应用。

根据你的操作系统选择对应的执行方式：

#### Windows 用户：

**方式一：使用 .bat 文件（推荐）**
```cmd
cd vscodiumpatch\scripts
integrate-vscodium.bat
```

**方式二：直接使用 PowerShell**
```powershell
cd vscodiumpatch/scripts
.\quick-integrate.ps1
```

#### macOS 用户：
```bash
cd vscodiumpatch/scripts
./integrate-vscodium-mac.sh
```

#### Linux 用户：
```bash
cd vscodiumpatch/scripts
./integrate-vscodium-linux.sh
```

#### 通用方式（Linux/macOS）：
```bash
cd vscodiumpatch/scripts
./quick-integrate.sh
```

### 第四步：执行 VSCodium 构建

集成完成后，按照正常流程构建 VSCodium：

```bash
# 回到 VSCodium 根目录
cd ..

# 执行构建（这会自动应用我们添加的补丁）
bash ./build.sh
```

**构建流程说明：**
1. `build.sh` 会调用 `prepare_vscode.sh`
2. `prepare_vscode.sh` 会自动应用 `patches/` 目录下的所有补丁
3. 我们的集成脚本已将 electron-updater 补丁复制到该目录
4. VSCodium 会自动集成自动更新功能

### 第四步：构建 VSCodium

```bash
# 进入 VSCodium 目录
cd vscodium

# 运行构建（补丁会自动应用）
bash ./dev/build.sh
```

### 第五步：打包成安装包

构建完成后，使用 electron-builder 打包：

```bash
# 进入构建产物目录
cd VSCode-linux-x64  # 或 VSCode-win32-x64、VSCode-darwin-x64

# 安装 electron-builder（如果还没有）
npm install -g electron-builder

# 打包成安装包
electron-builder --publish=never
```

## 文件结构和使用位置说明

### 项目文件结构

```
vscodiumpatch/
├── README.md                           # 项目说明文档
├── docs/
│   └── VSCodium自动更新集成操作指南.md    # 详细操作指南（本文档）
├── examples/                           # 示例文件
│   ├── main.ts.example                # 主进程更新代码示例
│   ├── package.json.example           # package.json 配置示例
│   └── product.json.example           # product.json 配置示例
├── patches-vscodium/                   # VSCodium 专用补丁文件
│   ├── electron-updater-dependencies.patch    # 依赖配置补丁
│   ├── electron-updater-main-process.patch    # 主进程更新逻辑补丁
│   └── electron-updater-product-config.patch  # 产品配置补丁
├── patches/                            # 通用补丁文件（备用）
│   ├── main-process-updater.patch
│   ├── package-json-dependencies.patch
│   └── product-json-config.patch
└── scripts/                            # 集成脚本文件
    ├── config.ps1                     # Windows 配置文件
    ├── config.sh                      # Linux/macOS 配置文件
    ├── integrate-vscodium-linux.sh    # Linux 专用启动器
    ├── integrate-vscodium-mac.sh      # macOS 专用启动器
    ├── integrate-vscodium.bat         # Windows 批处理启动器
    ├── integrate-vscodium.ps1         # Windows 核心集成脚本
    ├── integrate-vscodium.sh          # Linux/macOS 核心集成脚本
    ├── quick-integrate.ps1            # Windows 一键集成脚本
    └── quick-integrate.sh             # Linux/macOS 一键集成脚本
```

### 补丁文件应用位置

**重要：补丁文件会自动应用到 VSCode 源码的以下位置：**

| 补丁文件 | 应用到 VSCode 源码的位置 | 作用 |
|---------|------------------------|------|
| `electron-updater-dependencies.patch` | `package.json` | 添加 electron-updater 和 electron-log 依赖 |
| `electron-updater-main-process.patch` | `src/main.ts` 或 `src/vs/code/electron-main/main.ts` | 集成自动更新逻辑到主进程 |
| `electron-updater-product-config.patch` | `product.json` | 配置更新服务器地址和更新检查设置 |

### 脚本文件使用位置

**所有脚本文件都位于 `vscodiumpatch/scripts/` 目录下，使用时需要：**

1. **进入脚本目录：**
   ```bash
   cd vscodiumpatch/scripts
   ```

2. **根据操作系统选择对应脚本：**
   - Windows: `integrate-vscodium.bat` 或 `quick-integrate.ps1`
   - macOS: `integrate-vscodium-mac.sh` 或 `quick-integrate.sh`
   - Linux: `integrate-vscodium-linux.sh` 或 `quick-integrate.sh`

### 核心脚本文件说明

| 文件名 | 用途 | 适用系统 | 使用方式 |
|--------|------|----------|----------|
| `quick-integrate.ps1` | 一键集成脚本 | Windows | `cd vscodiumpatch/scripts && .\quick-integrate.ps1` |
| `quick-integrate.sh` | 一键集成脚本 | Linux/macOS | `cd vscodiumpatch/scripts && ./quick-integrate.sh` |
| `integrate-vscodium.bat` | Windows 批处理启动器 | Windows | `cd vscodiumpatch/scripts && integrate-vscodium.bat` |
| `integrate-vscodium-mac.sh` | macOS 专用启动器 | macOS | `cd vscodiumpatch/scripts && ./integrate-vscodium-mac.sh` |
| `integrate-vscodium-linux.sh` | Linux 专用启动器 | Linux | `cd vscodiumpatch/scripts && ./integrate-vscodium-linux.sh` |
| `integrate-vscodium.ps1` | 核心集成脚本 | Windows | 由其他脚本自动调用 |
| `integrate-vscodium.sh` | 核心集成脚本 | Linux/macOS | 由其他脚本自动调用 |
| `config.ps1` | Windows 配置文件 | Windows | 由脚本自动生成和读取 |
| `config.sh` | Linux/macOS 配置文件 | Linux/macOS | 由脚本自动生成和读取 |

### 配置文件修改方法

**重要：所有路径配置都已暴露在脚本顶部，方便直接修改！**

#### Windows 用户配置修改

编辑 `scripts/quick-integrate.ps1` 文件的顶部配置：

```powershell
# 快速配置（可在此处直接修改）
# =============================================================================
# 请修改以下配置为你的实际值
$VSCODE_SOURCE_PATH = "C:\\path\\to\\vscode"          # VSCode 源码路径
$UPDATE_SERVER_URL = "http://localhost:3000"       # 更新服务器地址
$CUSTOM_VERSION = ""                               # 自定义版本号（留空使用原版本）
# =============================================================================
```

#### Linux/macOS 用户配置修改

编辑 `scripts/quick-integrate.sh` 文件的顶部配置：

```bash
# 快速配置（可在此处直接修改）
# =============================================================================
# 请修改以下配置为你的实际值
VSCODE_SOURCE_PATH="/path/to/vscode"              # VSCode 源码路径
UPDATE_SERVER_URL="http://localhost:3000"         # 更新服务器地址
CUSTOM_VERSION=""                                 # 自定义版本号（留空使用原版本）
# =============================================================================
```

## 自动化处理说明

### 依赖安装自动化

**脚本会自动处理以下依赖安装：**

1. **检查必要工具：**
   - Git（必需，用于应用补丁）
   - Node.js 和 npm（必需，用于安装依赖和构建）
   - Python（构建时可能需要）

2. **自动安装 electron-updater 相关依赖：**
   ```json
   {
     "electron-updater": "^6.1.7",
     "electron-log": "^5.0.1"
   }
   ```

3. **自动执行的步骤：**
   - 创建源码备份（可选，通过配置控制）
   - 应用补丁文件到对应位置
   - 自动运行 `npm install` 安装新增依赖
   - 可选择自动运行 `npm run compile` 进行编译

### 环境检查自动化

**不同平台的脚本会自动检查：**

**Windows (`integrate-vscodium.bat`)：**
- PowerShell 执行策略
- Git 可用性
- Node.js 版本

**macOS (`integrate-vscodium-mac.sh`)：**
- Xcode Command Line Tools
- Homebrew（推荐）
- Node.js 版本和路径
- Python 环境

**Linux (`integrate-vscodium-linux.sh`)：**
- 发行版检测（Ubuntu、CentOS、Arch 等）
- 基本构建工具（build-essential、gcc、make 等）
- Node.js 版本
- 系统资源（内存、磁盘空间）

### 错误处理自动化

**脚本包含完整的错误处理机制：**

1. **补丁应用失败时：**
   - 自动尝试手动应用补丁
   - 提供详细的错误信息和解决建议
   - 自动回滚已应用的更改（如果启用备份）

2. **依赖安装失败时：**
   - 提供清晰的错误提示
   - 建议手动安装命令
   - 检查网络连接和 npm 配置

3. **环境检查失败时：**
   - 提供具体的安装指导
   - 显示缺失工具的安装命令
   - 给出官方下载链接

## 详细配置说明

### 版本号修改

如果需要自定义版本号，直接在快速集成脚本顶部修改 `CUSTOM_VERSION` 变量：

```bash
# 示例：设置自定义版本号
CUSTOM_VERSION="1.85.2-custom"
```

## 🔧 版本号配置

### 修改应用版本号

**编辑 `vscodium/patches/electron-updater-dependencies.patch` 文件：**

找到 package.json 的版本配置部分，修改版本号：

```diff
--- a/package.json
+++ b/package.json
@@ -XX,X +XX,X @@
 {
   "name": "code-oss-dev",
-  "version": "1.85.0",
+  "version": "1.85.1",
   "distro": "...",
```

### 版本号规则

- 使用语义化版本：`主版本.次版本.修订版本`
- 例如：`1.85.0` → `1.85.1`（修复版本）
- 例如：`1.85.0` → `1.86.0`（功能版本）

## 🌐 更新服务器配置示例

### 示例 1：本地测试服务器

```diff
+	"updateUrl": "http://localhost:3000",
```

### 示例 2：GitHub Releases

```diff
+	"updateUrl": "https://api.github.com/repos/your-username/your-vscodium/releases",
```

### 示例 3：自定义服务器

```diff
+	"updateUrl": "https://updates.yourcompany.com/vscodium",
```

## ✅ 验证集成是否成功

构建完成后，检查以下内容：

### 1. 检查依赖是否安装

```bash
cd vscodium/vscode
npm list electron-updater
npm list electron-log
```

### 2. 检查代码是否修改

```bash
# 检查主进程是否包含更新代码
grep -n "autoUpdater" vscode/src/vs/code/electron-main/main.ts

# 检查产品配置是否包含更新地址
grep -n "updateUrl" vscode/product.json
```

### 3. 启动应用测试

启动构建的 VSCodium，检查控制台是否有更新相关日志：

```
正在检查更新...
当前已是最新版本: 1.85.1
```

## 🔄 更新流程

当你需要发布新版本时：

1. **修改版本号**（参考上面的版本号配置）
2. **重新构建**：`bash ./dev/build.sh`
3. **打包发布**：`electron-builder --publish=always`
4. **上传到更新服务器**

## ❓ 常见问题

### Q: 构建失败，提示补丁无法应用？
A: 检查 VSCodium 版本是否与补丁兼容，或重新克隆最新的 VSCodium 源码。

### Q: 应用启动后没有检查更新？
A: 检查更新服务器地址是否正确，网络是否可达。

### Q: 如何禁用自动更新？
A: 删除 `vscodium/patches/` 目录下的 electron-updater 相关补丁文件，重新构建。

## 📞 技术支持

如果遇到问题，请检查：
1. VSCodium 源码是否是最新版本
2. 补丁文件是否完整
3. 更新服务器是否正常运行
4. 网络连接是否正常

---

**完成！现在你的 VSCodium 已经集成了自动更新功能。** 🎉