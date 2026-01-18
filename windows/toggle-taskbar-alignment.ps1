# Toggle taskbar alignment between left and center on Windows 11
# Enhanced version with Windows version check, validation, error handling, and user confirmation

# Function to pause on error with troubleshooting steps
function Wait-OnError {
    param(
        [string]$ErrorMessage,
        [string]$Troubleshooting = ""
    )
    Write-Host "`nERROR: $ErrorMessage" -ForegroundColor Red
    if ($Troubleshooting) {
        Write-Host "`nTroubleshooting steps:" -ForegroundColor Yellow
        Write-Host $Troubleshooting -ForegroundColor Yellow
    }
    Write-Host "`nPress Enter to close this window..." -ForegroundColor Yellow
    Read-Host
}

# Function to check Windows version (requires Windows 11)
function Test-Windows11 {
    try {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
        $version = [version]$os.Version
        # Windows 11 version is 10.0.22000 or higher
        if ($version.Major -eq 10 -and $version.Minor -eq 0 -and $version.Build -ge 22000) {
            return $true
        }
        return $false
    } catch {
        return $false
    }
}

# Import the Windows modules
$modulePath = Join-Path $PSScriptRoot "..\modules\ModuleIndex.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

# Check Windows version
if (-not (Test-Windows11)) {
    Wait-OnError -ErrorMessage "This script requires Windows 11 (build 22000 or higher)." -Troubleshooting "Please run this script on a Windows 11 machine."
    exit 1
}

try {
    $registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    
    # Get current taskbar alignment
    $taskbarAlValue = Get-RegistryValue -KeyPath $registryPath -ValueName "TaskbarAl" -DefaultValue 0
    
    # Validate TaskbarAl value (should be 0 or 1)
    if ($taskbarAlValue -notin 0, 1) {
        Write-StatusMessage -Message "Invalid TaskbarAl value ($taskbarAlValue). Resetting to 0 (left)." -Type Warning
        $taskbarAlValue = 0
    }
    
    # Toggle between 0 (left) and 1 (center)
    $newAlignmentValue = if ($taskbarAlValue -eq 0) { 1 } else { 0 }
    
    # Get current TaskbarSi value to preserve it
    $taskbarSiValue = Get-RegistryValue -KeyPath $registryPath -ValueName "TaskbarSi" -DefaultValue 0
    if ($taskbarSiValue -notin 0, 1) {
        # If invalid, default to 0 (small)
        $taskbarSiValue = 0
    }
    
    # Apply changes
    Set-RegistryValue -KeyPath $registryPath -ValueName "TaskbarAl" -ValueData $newAlignmentValue -ValueType DWord
    Set-RegistryValue -KeyPath $registryPath -ValueName "TaskbarSi" -ValueData $taskbarSiValue -ValueType DWord
    
    # Ask user for Explorer restart confirmation
    Write-Host ""
    $restartExplorer = $false
    $choice = Read-Host "Restart Windows Explorer to apply changes? (Y/N) [default: Y]"
    if ($choice -eq '' -or $choice -eq 'Y' -or $choice -eq 'y') {
        $restartExplorer = $true
    }
    
    if ($restartExplorer) {
        # Check elevation for Explorer restart (optional)
        $isAdmin = Test-AdminRights
        if (-not $isAdmin) {
            Write-StatusMessage -Message "Running without administrator privileges. Explorer restart may fail." -Type Warning
        }
        
        try {
            Stop-Process -Name "explorer" -Force -ErrorAction Stop
            Write-StatusMessage -Message "Windows Explorer restarted to apply changes" -Type Info
        } catch {
            Write-StatusMessage -Message "Could not restart Windows Explorer automatically. Please restart Explorer manually or log off/on to apply changes." -Type Warning
            Write-StatusMessage -Message "Error details: $($_.Exception.Message)" -Type Warning
        }
    } else {
        Write-StatusMessage -Message "Explorer not restarted. Changes will take effect after next logon or Explorer restart." -Type Info
    }
    
    if ($newAlignmentValue -eq 1) {
        Write-StatusMessage -Message "Taskbar alignment set to CENTER" -Type Success
    } else {
        Write-StatusMessage -Message "Taskbar alignment set to LEFT" -Type Success
    }
    
} catch [System.Management.Automation.ItemNotFoundException] {
    Wait-OnError -ErrorMessage "Registry path not found. This may indicate a corrupted Windows installation or unsupported Windows version." -Troubleshooting "1. Ensure you are running Windows 11.`n2. Check if the registry key '$registryPath' exists.`n3. Run System File Checker (sfc /scannow)."
} catch [System.Management.Automation.PSArgumentException] {
    # Create registry values if they don't exist
    Set-RegistryValue -KeyPath $registryPath -ValueName "TaskbarAl" -ValueData 1 -ValueType DWord
    Set-RegistryValue -KeyPath $registryPath -ValueName "TaskbarSi" -ValueData 0 -ValueType DWord
    Stop-Process -Name "explorer" -Force
    Write-StatusMessage -Message "Taskbar alignment set to CENTER (registry values created)" -Type Success
} catch [System.Security.SecurityException] {
    Wait-OnError -ErrorMessage "Access denied to registry. Please run script as Administrator." -Troubleshooting "1. Right-click PowerShell and select 'Run as Administrator'.`n2. Ensure you have necessary permissions."
} catch {
    Wait-OnError -ErrorMessage "Failed to toggle taskbar alignment: $($_.Exception.Message)" -Troubleshooting "1. Check if registry key is accessible.`n2. Ensure no other process is locking the registry.`n3. Try running as Administrator."
}