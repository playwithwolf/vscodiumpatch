# VSCodium electron-updater 补丁包

## 🎯 功能说明

为 VSCodium 集成 electron-updater 自动更新功能的完整解决方案。

## 📁 项目放置位置

**重要说明：** 本项目应该放置在 VSCodium 源码根目录下，与 `build.sh` 脚本同级。

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

## 🔄 与 VSCodium 构建流程的集成

VSCodium 的构建流程会自动应用我们的补丁：

1. **集成时机**：在执行 `bash ./build.sh` 之前运行我们的集成脚本
2. **补丁应用**：集成脚本将补丁复制到 VSCodium 的 `patches/` 目录
3. **自动构建**：VSCodium 的 `prepare_vscode.sh` 会自动应用所有补丁
4. **无缝集成**：构建出的 VSCodium 自动包含 electron-updater 功能

## 📁 项目结构

```
vscodiumpatch/
├── README.md                           # 项目说明文档
├── docs/
│   └── VSCodium自动更新集成操作指南.md    # 详细操作指南
├── examples/                           # 示例文件
│   ├── main.ts.example                # 主进程更新代码示例
│   ├── package.json.example           # package.json 配置示例
│   └── product.json.example           # product.json 配置示例
├── patches-vscodium/                   # VSCodium 专用补丁文件
│   ├── electron-updater-dependencies.patch    # 依赖配置补丁 → package.json
│   ├── electron-updater-main-process.patch    # 主进程更新逻辑 → src/main.ts
│   └── electron-updater-product-config.patch  # 产品配置补丁 → product.json
├── patches/                            # 通用补丁文件（备用）
│   ├── main-process-updater.patch
│   ├── package-json-dependencies.patch
│   └── product-json-config.patch
└── scripts/                            # 集成脚本文件（使用时需 cd 到此目录）
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

### 🎯 补丁文件应用位置

| 补丁文件 | 应用到 VSCode 源码位置 | 作用说明 |
|---------|---------------------|----------|
| `electron-updater-dependencies.patch` | `package.json` | 自动添加 electron-updater 和 electron-log 依赖 |
| `electron-updater-main-process.patch` | `src/main.ts` 或 `src/vs/code/electron-main/main.ts` | 集成自动更新逻辑到主进程 |
| `electron-updater-product-config.patch` | `product.json` | 配置更新服务器地址和更新检查设置 |

### 🔧 脚本使用位置

**重要：所有脚本都在 `vscodiumpatch/scripts/` 目录下，使用前需要先进入该目录：**

```bash
cd vscodiumpatch/scripts
```

然后根据你的操作系统选择对应脚本：
- **Windows**: `integrate-vscodium.bat` 或 `quick-integrate.ps1`
- **macOS**: `integrate-vscodium-mac.sh` 或 `quick-integrate.sh`
- **Linux**: `integrate-vscodium-linux.sh` 或 `quick-integrate.sh`

## 🚀 四步集成指南

### 1. 准备 VSCodium 源码和项目
```bash
# 克隆 VSCodium 源码
git clone https://github.com/VSCodium/vscodium.git
cd vscodium

# 将 vscodiumpatch 项目放置到 VSCodium 根目录下
git clone https://github.com/your-repo/vscodiumpatch.git
# 或者复制项目文件夹到此处
```

### 2. 配置集成参数

由于项目已放置在 VSCodium 根目录下，只需要配置更新服务器地址：

- **Windows**: 编辑 `vscodiumpatch/scripts/quick-integrate.ps1` 顶部的 `$UPDATE_SERVER_URL`
- **Linux/macOS**: 编辑 `vscodiumpatch/scripts/quick-integrate.sh` 顶部的 `UPDATE_SERVER_URL`

### 3. 执行集成（在构建 VSCodium 之前）

**重要：** 必须在执行 `bash ./build.sh` 之前运行集成脚本。

```bash
# Windows - 使用批处理文件（推荐）
vscodiumpatch\scripts\integrate-vscodium.bat

# Windows - 直接使用 PowerShell
.\vscodiumpatch\scripts\quick-integrate.ps1

# macOS
./vscodiumpatch/scripts/integrate-vscodium-mac.sh

# Linux
./vscodiumpatch/scripts/integrate-vscodium-linux.sh

# 通用方式（Linux/macOS）
./vscodiumpatch/scripts/quick-integrate.sh
```

### 4. 执行 VSCodium 构建

集成完成后，按照正常流程构建 VSCodium：

```bash
# VSCodium 会自动应用我们添加的补丁
bash ./build.sh
```

**构建流程说明：**
- `build.sh` 调用 `prepare_vscode.sh`
- `prepare_vscode.sh` 自动应用 `patches/` 目录下的所有补丁
- 我们的集成脚本已将 electron-updater 补丁复制到该目录
- 构建出的 VSCodium 自动包含自动更新功能

## 🤖 自动化处理

### ✅ 依赖管理自动化
- **自动检查**：Git、Node.js、npm、Python 等必要工具
- **自动安装**：electron-updater (^6.1.7) 和 electron-log (^5.0.1) 依赖
- **自动执行**：`npm install` 安装新增依赖
- **可选自动**：`npm run compile` 编译构建（可配置）

### 🔍 环境检查自动化
- **Windows**：PowerShell 执行策略、Git 可用性、Node.js 版本
- **macOS**：Xcode Command Line Tools、Homebrew、Node.js、Python 环境
- **Linux**：发行版检测、构建工具、Node.js 版本、系统资源

### 🛠️ 错误处理自动化
- **补丁失败**：自动尝试手动应用，提供详细错误信息和解决建议
- **依赖失败**：清晰错误提示，建议手动安装命令
- **环境缺失**：具体安装指导，显示缺失工具的安装命令

## 📋 前置要求

- **Git** - 用于应用补丁
- **Node.js 18+** - 用于构建 VSCode
- **Microsoft VSCode 源码** - 从 https://github.com/Microsoft/vscode 克隆

## 🔧 补丁说明

### 1. main-process-updater.patch
- **作用**: 在主进程中集成 electron-updater
- **修改文件**: `src/vs/code/electron-main/main.ts`
- **功能**: 
  - 添加自动更新检查逻辑
  - 配置更新事件监听
  - 设置更新服务器地址

### 2. package-json-dependencies.patch
- **作用**: 添加必需的依赖包
- **修改文件**: `package.json`
- **添加依赖**:
  - `electron-updater`: 自动更新核心库
  - `electron-log`: 日志记录库

### 3. product-json-config.patch
- **作用**: 配置产品更新服务器
- **修改文件**: `product.json`
- **添加配置**: `updateUrl` 字段

## 🛠️ 脚本说明

### apply-patches.ps1 / apply-patches.sh
主要的补丁应用脚本，支持以下功能：
- 自动检测 Git 环境
- 应用所有补丁文件
- 错误处理和回滚
- 详细的日志输出

**参数**:
- `--path` / `-VscodePath`: VSCode 源码路径
- `--url` / `-UpdateUrl`: 更新服务器地址（可选，默认 http://localhost:3000）
- `--backup` / `-CreateBackup`: 是否创建备份（可选，默认 true）

### quick-apply.ps1
Windows 专用的简化脚本，提供更友好的交互体验。

## 📖 详细教程

完整的操作步骤、版本号配置、更新服务器设置等详细说明，请参考：

**[VSCodium 自动更新集成操作指南](docs/VSCodium自动更新集成操作指南.md)**

## 🔍 常见问题

**Q: 构建失败，提示补丁无法应用？**
A: 检查 VSCodium 版本是否与补丁兼容，或重新克隆最新的 VSCodium 源码。

**Q: 应用启动后没有检查更新？**
A: 检查更新服务器地址是否正确，网络是否可达。

**Q: 如何修改版本号？**
A: 参考操作指南中的"版本号配置"部分。

**Q: 如何配置更新服务器地址？**
A: 参考操作指南中的"更新服务器配置示例"部分。

## 📝 版本兼容性

- ✅ VSCodium 1.85.x
- ✅ VSCodium 1.84.x  
- ⚠️ 更早版本可能需要调整补丁

## 📄 许可证

本项目采用 MIT 许可证。

## 🙏 致谢

- [VSCodium](https://github.com/VSCodium/vscodium) - 开源的 VSCode 发行版
- [electron-updater](https://github.com/electron-userland/electron-builder/tree/master/packages/electron-updater) - Electron 自动更新库

---

**注意**: 这个补丁包是为了简化 VSCodium 自动更新集成而创建的。使用前请确保理解修改的内容，并在测试环境中验证功能。