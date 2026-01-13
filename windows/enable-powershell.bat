@echo off
REM enable-powershell.bat - Toggles PowerShell script execution policy permanently between Restricted and RemoteSigned.
REM Requires administrator privileges.
REM Usage: Run this batch file as administrator.

echo ========================================
echo   PowerShell Execution Policy Toggle
echo ========================================
echo.

REM Check for administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] This operation requires administrator privileges.
    echo Please right-click the batch file and select "Run as administrator".
    pause
    exit /b 1
)
echo [INFO] Running with administrator privileges.
echo.

REM Get current execution policy at LocalMachine scope
for /f "delims=" %%A in ('powershell -Command "Get-ExecutionPolicy -Scope LocalMachine 2>&1"') do set "currentPolicy=%%A"
echo Current execution policy (LocalMachine): %currentPolicy%

REM Determine new policy (treat Undefined as Restricted)
if /i "%currentPolicy%"=="Restricted" (
    set "newPolicy=RemoteSigned"
    set "action=Enabled"
) else if /i "%currentPolicy%"=="Undefined" (
    set "newPolicy=RemoteSigned"
    set "action=Enabled"
) else (
    set "newPolicy=Restricted"
    set "action=Disabled"
)

echo Switching policy to %newPolicy% (%action%)...
powershell -Command "Set-ExecutionPolicy -ExecutionPolicy %newPolicy% -Scope LocalMachine -Force"
if %errorLevel% neq 0 (
    echo [ERROR] Failed to set execution policy.
    pause
    exit /b 1
)

REM Verify change
for /f "delims=" %%A in ('powershell -Command "Get-ExecutionPolicy -Scope LocalMachine 2>&1"') do set "updatedPolicy=%%A"
echo Updated execution policy (LocalMachine): %updatedPolicy%

echo.
echo [SUCCESS] PowerShell script execution has been %action%.
echo.
echo Press any key to close this window...
pause >nul