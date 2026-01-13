@echo off
REM enable-powershell.bat - Temporarily enables PowerShell script execution for the current session
REM Usage: Run this batch file as administrator (recommended) or as a normal user.

echo ========================================
echo   PowerShell Execution Policy Bypass
echo ========================================
echo.

REM Check if running as administrator (optional)
net session >nul 2>&1
if %errorLevel% equ 0 (
    echo [INFO] Running with administrator privileges.
) else (
    echo [WARNING] Not running as administrator. Some changes may require elevation.
)

echo.
echo Setting execution policy to Bypass for the current process...
powershell -Command "Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force"
if %errorLevel% equ 0 (
    echo [SUCCESS] PowerShell scripts are now enabled for this session.
) else (
    echo [ERROR] Failed to set execution policy. Please run as administrator.
    pause
    exit /b 1
)

echo.
echo You can now run PowerShell scripts in this window.
echo To make the change permanent, run PowerShell as Administrator and use:
echo   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine
echo.
echo Press any key to close this window...
pause >nul