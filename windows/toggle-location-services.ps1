# Toggle location services on Windows 10/11
# Refactored to use modular system - reduces from 31 lines to 14 lines
# Updated with Windows version check, improved validation, and error handling
# Updated registry path to user-level ConsentStore to avoid "managed by your organization" message
# Updated to set both HKCU and HKLM registry paths and broadcast change notification

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

# Function to broadcast WM_SETTINGCHANGE to notify Windows of registry changes
function Broadcast-SettingChange {
    param(
        [string]$ChangeType = "Policy"
    )
    try {
        $signature = @'
        [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
        public static extern IntPtr SendMessageTimeout(
            IntPtr hWnd,
            uint Msg,
            UIntPtr wParam,
            string lParam,
            uint fuFlags,
            uint uTimeout,
            out UIntPtr lpdwResult);
'@
        Add-Type -MemberDefinition $signature -Name NativeMethods -Namespace Win32
        $HWND_BROADCAST = [IntPtr]0xFFFF
        $WM_SETTINGCHANGE = 0x001A
        $SMTO_ABORTIFHUNG = 0x0002
        $result = [UIntPtr]::Zero
        [Win32.NativeMethods]::SendMessageTimeout($HWND_BROADCAST, $WM_SETTINGCHANGE, [UIntPtr]::Zero, $ChangeType, $SMTO_ABORTIFHUNG, 5000, [ref]$result) | Out-Null
        Write-Verbose "Broadcast sent for setting change: $ChangeType" -Verbose
    } catch {
        Write-Warning "Failed to broadcast setting change: $_"
    }
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
    # User-level registry path for location consent (avoids "managed by your organization" message)
    $registryPathHKCU = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location"
    # Machine-level registry path for location consent (policy)
    $registryPathHKLM = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location"
    
    # Validate registry keys exist
    if (-not (Test-RegistryKey -KeyPath $registryPathHKCU)) {
        Write-Warning "Registry key '$registryPathHKCU' does not exist. It will be created."
    }
    if (-not (Test-RegistryKey -KeyPath $registryPathHKLM)) {
        Write-Warning "Registry key '$registryPathHKLM' does not exist. It will be created."
    }
    
    # Validate registry value existence and data type (use HKCU as primary for decision)
    $valueExists = Test-RegistryValue -KeyPath $registryPathHKCU -ValueName "Value"
    if ($valueExists) {
        $value = Get-ItemProperty -Path $registryPathHKCU -Name "Value" -ErrorAction SilentlyContinue
        if ($value -and $value.Value -isnot [string]) {
            Write-Warning "Registry value 'Value' is not a string (type: $($value.Value.GetType().Name)). Treating as 'Deny' (disabled)."
            $currentValue = "Deny"
        } else {
            $currentValue = Get-RegistryValue -KeyPath $registryPathHKCU -ValueName "Value" -DefaultValue "Allow"
        }
    } else {
        $currentValue = "Allow"
        Write-Verbose "Registry value 'Value' does not exist, using default: $currentValue" -Verbose
    }
    
    # Check service status and startup type
    $service = Get-Service -Name "lfsvc" -ErrorAction Stop
    $serviceStatus = $service.Status
    $startupType = (Get-CimInstance -ClassName Win32_Service -Filter "Name='lfsvc'").StartMode
    Write-Verbose "Service lfsvc status: $serviceStatus, startup type: $startupType" -Verbose
    
    # Determine if location is currently enabled based on registry and service
    $locationEnabled = ($currentValue -eq "Allow") -and ($serviceStatus -eq "Running")
    
    if ($locationEnabled) {
        # Disable location services
        Set-RegistryValue -KeyPath $registryPathHKCU -ValueName "Value" -ValueData "Deny" -ValueType String
        Set-RegistryValue -KeyPath $registryPathHKLM -ValueName "Value" -ValueData "Deny" -ValueType String
        Stop-Service -Name "lfsvc" -Force
        Write-StatusMessage -Message "Location services disabled" -Type Success
        
        # Verify service is stopped
        $service = Get-Service -Name "lfsvc" -ErrorAction SilentlyContinue
        if ($service.Status -eq "Running") {
            Write-Warning "Service lfsvc is still running after stop command. Forcing stop again."
            Stop-Service -Name "lfsvc" -Force -ErrorAction SilentlyContinue
        }
    } else {
        # Enable location services
        Set-RegistryValue -KeyPath $registryPathHKCU -ValueName "Value" -ValueData "Allow" -ValueType String
        Set-RegistryValue -KeyPath $registryPathHKLM -ValueName "Value" -ValueData "Allow" -ValueType String
        Start-Service -Name "lfsvc"
        Write-StatusMessage -Message "Location services enabled" -Type Success
        
        # Verify service is started
        $service = Get-Service -Name "lfsvc" -ErrorAction SilentlyContinue
        if ($service.Status -ne "Running") {
            Write-Warning "Service lfsvc is not running after start command. Attempting to start again."
            Start-Service -Name "lfsvc" -ErrorAction SilentlyContinue
        }
    }
    
    # Broadcast setting change to notify Windows and applications
    Broadcast-SettingChange -ChangeType "Policy"
    
    # Final verification
    $finalRegistryValueHKCU = Get-RegistryValue -KeyPath $registryPathHKCU -ValueName "Value" -DefaultValue "Allow"
    $finalRegistryValueHKLM = Get-RegistryValue -KeyPath $registryPathHKLM -ValueName "Value" -DefaultValue "Allow"
    $finalServiceStatus = (Get-Service -Name "lfsvc" -ErrorAction SilentlyContinue).Status
    Write-Verbose "Final registry values - HKCU: $finalRegistryValueHKCU, HKLM: $finalRegistryValueHKLM, service status: $finalServiceStatus" -Verbose
    
    if (($finalRegistryValueHKCU -eq "Allow" -and $finalRegistryValueHKLM -eq "Allow" -and $finalServiceStatus -eq "Running") -or
        ($finalRegistryValueHKCU -eq "Deny" -and $finalRegistryValueHKLM -eq "Deny" -and $finalServiceStatus -ne "Running")) {
        Write-StatusMessage -Message "Location services toggled successfully and synchronized." -Type Success
    } else {
        Write-Warning "Registry and service may not be fully synchronized. Please check manually."
    }
    
} catch {
    $errorType = $_.Exception.GetType().Name
    $detailedMessage = "Failed to toggle location services ($errorType): $($_.Exception.Message)"
    Wait-OnError -ErrorMessage $detailedMessage -ExitCode 3
}