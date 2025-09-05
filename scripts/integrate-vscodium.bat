@echo off
REM =============================================================================
REM VSCodium Electron-Updater 集成脚本启动器
REM 适用于 Windows
REM 调用 PowerShell 脚本执行实际集成
REM =============================================================================

setlocal enabledelayedexpansion

REM 获取脚本目录
set "SCRIPT_DIR=%~dp0"
set "PS_SCRIPT=%SCRIPT_DIR%integrate-vscodium.ps1"

REM 检查 PowerShell 脚本是否存在
if not exist "%PS_SCRIPT%" (
    echo [错误] PowerShell 脚本不存在: %PS_SCRIPT%
    echo 请确保 integrate-vscodium.ps1 文件存在
    pause
    exit /b 1
)

REM 显示信息
echo ===============================================
echo VSCodium Electron-Updater 集成脚本 (Windows)
echo ===============================================
echo.
echo 正在启动 PowerShell 脚本...
echo 脚本路径: %PS_SCRIPT%
echo.

REM 检查 PowerShell 执行策略
echo 检查 PowerShell 执行策略...
powershell -Command "Get-ExecutionPolicy" >nul 2>&1
if errorlevel 1 (
    echo [警告] 无法检查 PowerShell 执行策略
    echo 如果脚本执行失败，请以管理员身份运行以下命令：
    echo Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
    echo.
)

REM 执行 PowerShell 脚本
echo 执行集成脚本...
echo.
powershell -ExecutionPolicy Bypass -File "%PS_SCRIPT%" %*

REM 检查执行结果
if errorlevel 1 (
    echo.
    echo [错误] 脚本执行失败，错误代码: %errorlevel%
    echo.
    echo 可能的解决方案：
    echo 1. 检查 config.ps1 配置文件是否正确
    echo 2. 确保 Git 和 npm 已安装
    echo 3. 确保 VSCode 源码路径正确
    echo 4. 以管理员身份运行此脚本
    echo.
    pause
    exit /b %errorlevel%
) else (
    echo.
    echo [成功] 集成完成！
    echo.
    echo 下一步：
    echo 1. 进入 VSCode 源码目录
    echo 2. 运行构建命令编译项目
    echo 3. 使用 electron-builder 打包应用
    echo.
)

echo 按任意键退出...
pause >nul