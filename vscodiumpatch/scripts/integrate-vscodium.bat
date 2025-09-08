@echo off
REM =============================================================================
REM VSCodium Electron-Updater Integration Script Launcher
REM For Windows
REM Calls PowerShell script to perform actual integration
REM =============================================================================

setlocal enabledelayedexpansion

REM Get script directory
set "SCRIPT_DIR=%~dp0"
set "PS_SCRIPT=%SCRIPT_DIR%integrate-vscodium.ps1"

REM Check if PowerShell script exists
if not exist "%PS_SCRIPT%" (
    echo [ERROR] PowerShell script does not exist: %PS_SCRIPT%
    echo Please ensure integrate-vscodium.ps1 file exists
    pause
    exit /b 1
)

REM Display information
echo ===============================================
echo VSCodium Electron-Updater Integration Script (Windows)
echo ===============================================
echo.
echo Starting PowerShell script...
echo Script path: %PS_SCRIPT%
echo.

REM Check PowerShell execution policy
echo Checking PowerShell execution policy...
powershell -Command "Get-ExecutionPolicy" >nul 2>&1
if %errorlevel% neq 0 (
    echo [WARNING] Cannot check PowerShell execution policy
    echo If script execution fails, run the following command as administrator:
    echo Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
    echo.
)

REM Execute PowerShell script
echo Executing integration script...
echo.
powershell -ExecutionPolicy Bypass -File "%PS_SCRIPT%" %*

REM Check execution result
if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Script execution failed, error code: %errorlevel%
    echo.
    echo Possible solutions:
    echo 1. Check if config.ps1 configuration file is correct
    echo 2. Ensure Git and npm are installed
    echo 3. Ensure VSCode source code path is correct
    echo 4. Run this script as administrator
    echo.
    pause
    exit /b %errorlevel%
) else (
    echo.
    echo [SUCCESS] Integration completed!
    echo.
    echo Next steps:
    echo 1. Enter VSCode source code directory
    echo 2. Run build command to compile project
    echo 3. Use electron-builder to package application
    echo.
)

echo Press any key to exit...
pause >nul