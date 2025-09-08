# =============================================================================
# VSCodium Electron-Updater Integration Script
# For Windows PowerShell
# =============================================================================

# Get script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Load configuration file
$ConfigFile = Join-Path $ScriptDir "config.ps1"
if (Test-Path $ConfigFile) {
    . $ConfigFile
    Write-Host "✅ Configuration file loaded" -ForegroundColor Green
} else {
    Write-Host "❌ Error: Configuration file not found: $ConfigFile" -ForegroundColor Red
    Write-Host "Please copy config.ps1.example to config.ps1 and modify the configuration" -ForegroundColor Yellow
    exit 1
}

# Log function
function Write-Log {
    param([string]$Message)
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "[$Timestamp] $Message"
    Write-Host $LogMessage
    $LogPath = Join-Path $ScriptDir $LOG_FILE
    Add-Content -Path $LogPath -Value $LogMessage
}

# Check required tools
function Test-Requirements {
    Write-Log "Checking required tools..."
    
    try {
        git --version | Out-Null
    } catch {
        Write-Log "❌ Error: Git not installed"
        exit 1
    }
    
    try {
        npm --version | Out-Null
    } catch {
        Write-Log "❌ Error: npm not installed"
        exit 1
    }
    
    Write-Log "✅ Required tools check passed"
}

# Check source path
function Test-SourcePath {
    Write-Log "Checking source path: $VSCODE_SOURCE_PATH"
    
    if ([string]::IsNullOrEmpty($VSCODE_SOURCE_PATH) -or $VSCODE_SOURCE_PATH -eq "C:\path\to\vscode") {
        Write-Log "❌ Error: Please set correct VSCODE_SOURCE_PATH in config.ps1"
        exit 1
    }
    
    if (-not (Test-Path $VSCODE_SOURCE_PATH)) {
        Write-Log "❌ Error: Source path does not exist: $VSCODE_SOURCE_PATH"
        exit 1
    }
    
    $GitPath = Join-Path $VSCODE_SOURCE_PATH ".git"
    if (-not (Test-Path $GitPath)) {
        Write-Log "❌ Error: Not a Git repository: $VSCODE_SOURCE_PATH"
        exit 1
    }
    
    Write-Log "✅ Source path check passed"
}

# Create backup
function New-Backup {
    if ($CREATE_BACKUP -eq $true) {
        Write-Log "Creating backup..."
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
        
        Write-Log "✅ Backup created: $BackupPath"
    }
}

# Apply patches
function Invoke-ApplyPatches {
    Write-Log "Applying patches..."
    $PatchesPath = Join-Path $ScriptDir $PATCHES_DIR
    
    if (-not (Test-Path $PatchesPath)) {
        Write-Log "❌ Error: Patches directory does not exist: $PatchesPath"
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
            Write-Log "⚠️  Warning: Patch file does not exist: $PatchFile"
            continue
        }
        
        Write-Log "Applying patch: $PatchFile"
        
        $GitArgs = $GIT_APPLY_ARGS.Split(' ') + @($PatchPath)
        $Result = & git apply @GitArgs 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "✅ Patch applied successfully: $PatchFile"
            $SuccessCount++
        } else {
            Write-Log "❌ Patch application failed: $PatchFile"
            Write-Log "Error message: $Result"
        }
    }
    
    Pop-Location
    Write-Log "Patch application completed: $SuccessCount/$($PatchFiles.Count)"
}

# Configure update server
function Set-UpdateServer {
    if (-not [string]::IsNullOrEmpty($UPDATE_SERVER_URL) -and $UPDATE_SERVER_URL -ne "http://localhost:3000") {
        Write-Log "Configuring update server address: $UPDATE_SERVER_URL"
        
        $ProductJson = Join-Path $VSCODE_SOURCE_PATH "product.json"
        if (Test-Path $ProductJson) {
            try {
                $Content = Get-Content $ProductJson -Raw | ConvertFrom-Json
                $Content | Add-Member -MemberType NoteProperty -Name "updateUrl" -Value $UPDATE_SERVER_URL -Force
                $Content | ConvertTo-Json -Depth 100 | Set-Content $ProductJson
                Write-Log "✅ Update server address configured successfully"
            } catch {
                Write-Log "⚠️  Warning: Failed to configure update server address, please manually configure updateUrl in product.json"
            }
        }
    }
}

# Install dependencies
function Install-Dependencies {
    if ($AUTO_INSTALL_DEPS -eq $true) {
        Write-Log "Installing dependencies..."
        Push-Location $VSCODE_SOURCE_PATH
        
        $Result = & npm install 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "✅ Dependencies installed successfully"
        } else {
            Write-Log "❌ Dependencies installation failed"
            Write-Log "Error message: $Result"
            Pop-Location
            exit 1
        }
        
        Pop-Location
    }
}

# Build project
function Build-Project {
    if ($AUTO_BUILD -eq $true) {
        Write-Log "Building project..."
        Push-Location $VSCODE_SOURCE_PATH
        
        $Result = Invoke-Expression $BUILD_COMMAND 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "✅ Project built successfully"
        } else {
            Write-Log "❌ Project build failed"
            Write-Log "Error message: $Result"
            Pop-Location
            exit 1
        }
        
        Pop-Location
    }
}

# Main function
function Main {
    Write-Log "=== VSCodium Electron-Updater Integration Started ==="
    Write-Log "Configuration info:"
    Write-Log "  Source path: $VSCODE_SOURCE_PATH"
    Write-Log "  Update server: $UPDATE_SERVER_URL"
    Write-Log "  Auto install deps: $AUTO_INSTALL_DEPS"
    Write-Log "  Auto build: $AUTO_BUILD"
    
    Test-Requirements
    Test-SourcePath
    New-Backup
    Invoke-ApplyPatches
    Set-UpdateServer
    Install-Dependencies
    Build-Project
    
    Write-Log "=== VSCodium Electron-Updater Integration Completed ==="
    Write-Log "🎉 Integration successful!"
    
    if ($AUTO_BUILD -ne $true) {
        Write-Log "Next step: Please run build command to compile project"
    }
    
    Write-Log "Then use electron-builder to package application"
}

# Show help
if ($args -contains "-h" -or $args -contains "--help") {
    Write-Host @"
VSCodium Electron-Updater Integration Script

Usage:
  .\integrate-vscodium.ps1        # Run with settings from config file
  .\integrate-vscodium.ps1 -h     # Show this help message

Configuration:
  Please edit config.ps1 file to modify configuration parameters
  
Main configuration items:
  - VSCODE_SOURCE_PATH: VSCode source code path
  - UPDATE_SERVER_URL: Update server address
  - AUTO_INSTALL_DEPS: Whether to automatically install dependencies
  - AUTO_BUILD: Whether to automatically build
"@
    exit 0
}

# Execute main function
Main