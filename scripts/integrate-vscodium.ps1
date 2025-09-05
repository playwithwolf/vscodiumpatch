# =============================================================================
# VSCodium Electron-Updater 集成脚本
# 适用于 Windows PowerShell
# =============================================================================

# 获取脚本目录
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# 加载配置文件
$ConfigFile = Join-Path $ScriptDir "config.ps1"
if (Test-Path $ConfigFile) {
    . $ConfigFile
    Write-Host "✅ 已加载配置文件" -ForegroundColor Green
} else {
    Write-Host "❌ 错误: 配置文件不存在: $ConfigFile" -ForegroundColor Red
    Write-Host "请先复制 config.ps1.example 为 config.ps1 并修改配置" -ForegroundColor Yellow
    exit 1
}

# 日志函数
function Write-Log {
    param([string]$Message)
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "[$Timestamp] $Message"
    Write-Host $LogMessage
    $LogPath = Join-Path $ScriptDir $LOG_FILE
    Add-Content -Path $LogPath -Value $LogMessage
}

# 检查必要工具
function Test-Requirements {
    Write-Log "检查必要工具..."
    
    try {
        git --version | Out-Null
    } catch {
        Write-Log "❌ 错误: Git 未安装"
        exit 1
    }
    
    try {
        npm --version | Out-Null
    } catch {
        Write-Log "❌ 错误: npm 未安装"
        exit 1
    }
    
    Write-Log "✅ 必要工具检查通过"
}

# 检查源码路径
function Test-SourcePath {
    Write-Log "检查源码路径: $VSCODE_SOURCE_PATH"
    
    if ([string]::IsNullOrEmpty($VSCODE_SOURCE_PATH) -or $VSCODE_SOURCE_PATH -eq "C:\path\to\vscode") {
        Write-Log "❌ 错误: 请在 config.ps1 中设置正确的 VSCODE_SOURCE_PATH"
        exit 1
    }
    
    if (-not (Test-Path $VSCODE_SOURCE_PATH)) {
        Write-Log "❌ 错误: 源码路径不存在: $VSCODE_SOURCE_PATH"
        exit 1
    }
    
    $GitPath = Join-Path $VSCODE_SOURCE_PATH ".git"
    if (-not (Test-Path $GitPath)) {
        Write-Log "❌ 错误: 不是 Git 仓库: $VSCODE_SOURCE_PATH"
        exit 1
    }
    
    Write-Log "✅ 源码路径检查通过"
}

# 创建备份
function New-Backup {
    if ($CREATE_BACKUP -eq $true) {
        Write-Log "创建备份..."
        $BackupPath = Join-Path $ScriptDir $BACKUP_DIR (Get-Date -Format "yyyyMMdd_HHmmss")
        New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null
        
        $FilesToBackup = @(
            "package.json",
            "product.json",
            "src\main.ts"
        )
        
        foreach ($File in $FilesToBackup) {
            $SourceFile = Join-Path $VSCODE_SOURCE_PATH $File
            if (Test-Path $SourceFile) {
                Copy-Item $SourceFile $BackupPath -ErrorAction SilentlyContinue
            }
        }
        
        Write-Log "✅ 备份已创建: $BackupPath"
    }
}

# 应用补丁
function Invoke-ApplyPatches {
    Write-Log "应用补丁..."
    $PatchesPath = Join-Path $ScriptDir $PATCHES_DIR
    
    if (-not (Test-Path $PatchesPath)) {
        Write-Log "❌ 错误: 补丁目录不存在: $PatchesPath"
        exit 1
    }
    
    Push-Location $VSCODE_SOURCE_PATH
    
    $PatchFiles = @(
        "electron-updater-dependencies.patch",
        "electron-updater-product-config.patch",
        "electron-updater-main-process.patch"
    )
    
    $SuccessCount = 0
    
    foreach ($PatchFile in $PatchFiles) {
        $PatchPath = Join-Path $PatchesPath $PatchFile
        
        if (-not (Test-Path $PatchPath)) {
            Write-Log "⚠️  警告: 补丁文件不存在: $PatchFile"
            continue
        }
        
        Write-Log "应用补丁: $PatchFile"
        
        $GitArgs = $GIT_APPLY_ARGS.Split(' ') + @($PatchPath)
        $Result = & git apply @GitArgs 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "✅ 补丁应用成功: $PatchFile"
            $SuccessCount++
        } else {
            Write-Log "❌ 补丁应用失败: $PatchFile"
            Write-Log "错误信息: $Result"
        }
    }
    
    Pop-Location
    Write-Log "补丁应用完成: $SuccessCount/$($PatchFiles.Count)"
}

# 配置更新服务器
function Set-UpdateServer {
    if (-not [string]::IsNullOrEmpty($UPDATE_SERVER_URL) -and $UPDATE_SERVER_URL -ne "http://localhost:3000") {
        Write-Log "配置更新服务器地址: $UPDATE_SERVER_URL"
        
        $ProductJson = Join-Path $VSCODE_SOURCE_PATH "product.json"
        if (Test-Path $ProductJson) {
            try {
                $Content = Get-Content $ProductJson -Raw | ConvertFrom-Json
                $Content | Add-Member -MemberType NoteProperty -Name "updateUrl" -Value $UPDATE_SERVER_URL -Force
                $Content | ConvertTo-Json -Depth 100 | Set-Content $ProductJson
                Write-Log "✅ 更新服务器地址配置成功"
            } catch {
                Write-Log "⚠️  警告: 配置更新服务器地址失败，请手动配置 product.json 中的 updateUrl"
            }
        }
    }
}

# 安装依赖
function Install-Dependencies {
    if ($AUTO_INSTALL_DEPS -eq $true) {
        Write-Log "安装依赖..."
        Push-Location $VSCODE_SOURCE_PATH
        
        $Result = & npm install 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "✅ 依赖安装成功"
        } else {
            Write-Log "❌ 依赖安装失败"
            Write-Log "错误信息: $Result"
            Pop-Location
            exit 1
        }
        
        Pop-Location
    }
}

# 构建项目
function Build-Project {
    if ($AUTO_BUILD -eq $true) {
        Write-Log "构建项目..."
        Push-Location $VSCODE_SOURCE_PATH
        
        $Result = Invoke-Expression $BUILD_COMMAND 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "✅ 项目构建成功"
        } else {
            Write-Log "❌ 项目构建失败"
            Write-Log "错误信息: $Result"
            Pop-Location
            exit 1
        }
        
        Pop-Location
    }
}

# 主函数
function Main {
    Write-Log "=== VSCodium Electron-Updater 集成开始 ==="
    Write-Log "配置信息:"
    Write-Log "  源码路径: $VSCODE_SOURCE_PATH"
    Write-Log "  更新服务器: $UPDATE_SERVER_URL"
    Write-Log "  自动安装依赖: $AUTO_INSTALL_DEPS"
    Write-Log "  自动构建: $AUTO_BUILD"
    
    Test-Requirements
    Test-SourcePath
    New-Backup
    Invoke-ApplyPatches
    Set-UpdateServer
    Install-Dependencies
    Build-Project
    
    Write-Log "=== VSCodium Electron-Updater 集成完成 ==="
    Write-Log "🎉 集成成功！"
    
    if ($AUTO_BUILD -ne $true) {
        Write-Log "下一步: 请运行构建命令编译项目"
    }
    
    Write-Log "然后使用 electron-builder 打包应用"
}

# 显示帮助
if ($args -contains "-h" -or $args -contains "--help") {
    Write-Host @"
VSCodium Electron-Updater 集成脚本

使用方法:
  .\integrate-vscodium.ps1        # 使用配置文件中的设置运行
  .\integrate-vscodium.ps1 -h     # 显示此帮助信息

配置:
  请编辑 config.ps1 文件修改配置参数
  
主要配置项:
  - VSCODE_SOURCE_PATH: VSCode 源码路径
  - UPDATE_SERVER_URL: 更新服务器地址
  - AUTO_INSTALL_DEPS: 是否自动安装依赖
  - AUTO_BUILD: 是否自动构建
"@
    exit 0
}

# 执行主函数
Main