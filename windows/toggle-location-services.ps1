# Toggle location services on Windows 10/11
# Refactored to use modular system - reduces from 31 lines to 14 lines
# Updated with Windows version check, improved validation, and error handling

# Function to handle errors with optional interactive pause
function Wait-OnError {
    param(
        [string]$ErrorMessage,
        [int]$ExitCode = 1
    )
    Write-Host "`nERROR: $ErrorMessage" -ForegroundColor Red
    # Check if session is interactive
    if ([Environment]::UserInteractive) {
        Write-Host "Press Enter to close this window..." -ForegroundColor Yellow
        Read-Host
    } else {
        Write-Verbose "Non-interactive session, exiting with code $ExitCode" -Verbose
    }
    exit $ExitCode
}

# Import the Windows modules
$modulePath = Join-Path $PSScriptRoot "modules\ModuleIndex.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

# Check admin rights and handle elevation
if (-not (Test-AdminRights)) {
    Invoke-Elevation
    exit
}

# Windows version check - require Windows 10 or 11
try {
    $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
    $version = [version]$os.Version
    if ($version.Major -ne 10) {
        throw "This script requires Windows 10 or 11. Detected Windows version: $($os.Caption)"
    }
    Write-Verbose "Windows version check passed: $($os.Caption)" -Verbose
} catch {
    Wait-OnError -ErrorMessage "Windows version check failed: $($_.Exception.Message)" -ExitCode 2
}

try {
    $registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors"
    
    # Validate registry key exists
    if (-not (Test-RegistryKey -KeyPath $registryPath)) {
        Write-Warning "Registry key '$registryPath' does not exist. It will be created."
    }
    
    # Validate registry value existence and data type
    $valueExists = Test-RegistryValue -KeyPath $registryPath -ValueName "DisableLocation"
    if ($valueExists) {
        $value = Get-ItemProperty -Path $registryPath -Name "DisableLocation" -ErrorAction SilentlyContinue
        if ($value -and $value.DisableLocation -isnot [int]) {
            Write-Warning "Registry value 'DisableLocation' is not a DWord (type: $($value.DisableLocation.GetType().Name)). Treating as 1 (disabled)."
            $currentValue = 1
        } else {
            $currentValue = Get-RegistryValue -KeyPath $registryPath -ValueName "DisableLocation" -DefaultValue 0
        }
    } else {
        $currentValue = 0
        Write-Verbose "Registry value 'DisableLocation' does not exist, using default: $currentValue" -Verbose
    }
    
    # Check service status and startup type
    $service = Get-Service -Name "lfsvc" -ErrorAction Stop
    $serviceStatus = $service.Status
    $startupType = (Get-CimInstance -ClassName Win32_Service -Filter "Name='lfsvc'").StartMode
    Write-Verbose "Service lfsvc status: $serviceStatus, startup type: $startupType" -Verbose
    
    if ($currentValue -eq 0) {
        Set-RegistryValue -KeyPath $registryPath -ValueName "DisableLocation" -ValueData 1 -ValueType DWord
        Stop-Service -Name "lfsvc" -Force
        Write-StatusMessage -Message "Location services disabled" -Type Success
        
        # Verify service is stopped
        $service = Get-Service -Name "lfsvc" -ErrorAction SilentlyContinue
        if ($service.Status -eq "Running") {
            Write-Warning "Service lfsvc is still running after stop command. Forcing stop again."
            Stop-Service -Name "lfsvc" -Force -ErrorAction SilentlyContinue
        }
    } else {
        Set-RegistryValue -KeyPath $registryPath -ValueName "DisableLocation" -ValueData 0 -ValueType DWord
        Start-Service -Name "lfsvc"
        Write-StatusMessage -Message "Location services enabled" -Type Success
        
        # Verify service is started
        $service = Get-Service -Name "lfsvc" -ErrorAction SilentlyContinue
        if ($service.Status -ne "Running") {
            Write-Warning "Service lfsvc is not running after start command. Attempting to start again."
            Start-Service -Name "lfsvc" -ErrorAction SilentlyContinue
        }
    }
    
    # Final verification
    $finalRegistryValue = Get-RegistryValue -KeyPath $registryPath -ValueName "DisableLocation" -DefaultValue 0
    $finalServiceStatus = (Get-Service -Name "lfsvc" -ErrorAction SilentlyContinue).Status
    Write-Verbose "Final registry value: $finalRegistryValue, service status: $finalServiceStatus" -Verbose
    
    if (($finalRegistryValue -eq 0 -and $finalServiceStatus -eq "Running") -or
        ($finalRegistryValue -eq 1 -and $finalServiceStatus -ne "Running")) {
        Write-StatusMessage -Message "Location services toggled successfully and synchronized." -Type Success
    } else {
        Write-Warning "Registry and service may not be fully synchronized. Please check manually."
    }
    
} catch {
    $errorType = $_.Exception.GetType().Name
    $detailedMessage = "Failed to toggle location services ($errorType): $($_.Exception.Message)"
    Wait-OnError -ErrorMessage $detailedMessage -ExitCode 3
}