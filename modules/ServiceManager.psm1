<#
.SYNOPSIS
    Service management module for Windows service toggle operations.
.DESCRIPTION
    Provides centralized functions for service toggle operations with consistent error handling,
    admin privilege checking, and status reporting.
.NOTES
    File Name      : ServiceManager.psm1
    Author         : System Administrator
    Prerequisite   : PowerShell 5.1 or later
    
.EXAMPLE
    Invoke-ServiceToggle -ServiceName "BDESVC" -ServiceDisplayName "BitLocker Drive Encryption"
.EXAMPLE
    Get-ServiceToggleStatus -ServiceName "BDESVC"
.EXAMPLE
    Test-ServiceToggleRequirements -ServiceName "BDESVC"
#>

# Import required modules
$modulePath = Join-Path $PSScriptRoot "ModuleIndex.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

function Invoke-ServiceToggle {
<#
.SYNOPSIS
    Toggles a Windows service startup type between Disabled and Manual/Automatic.
.DESCRIPTION
    Checks service existence, validates requirements, and toggles the service startup type.
    Provides consistent user feedback and error handling.
.PARAMETER ServiceName
    The name of the service to toggle.
.PARAMETER ServiceDisplayName
    The display name of the service for user-friendly output.
.PARAMETER EnableStartupType
    The startup type to use when enabling the service (Manual or Automatic). Default: Manual
.PARAMETER SkipAdminCheck
    Skip the administrator privilege check. Use with caution.
.OUTPUTS
    None. Writes status messages to console.
.EXAMPLE
    Invoke-ServiceToggle -ServiceName "BDESVC" -ServiceDisplayName "BitLocker Drive Encryption"
.EXAMPLE
    Invoke-ServiceToggle -ServiceName "lfsvc" -ServiceDisplayName "Geolocation Service" -EnableStartupType "Automatic"
#>
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$ServiceName,
    
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$ServiceDisplayName,
    
    [ValidateSet("Manual", "Automatic")]
    [string]$EnableStartupType = "Manual",
    
    [switch]$SkipAdminCheck
)

    try {
        # Test requirements before proceeding
        if (-not (Test-ServiceToggleRequirements -ServiceName $ServiceName -SkipAdminCheck:$SkipAdminCheck)) {
            return
        }
        
        # Get current service status
        $service = Get-Service -Name $ServiceName -ErrorAction Stop
        
        Write-StatusMessage -Message "Current $ServiceDisplayName status: $($service.Status)" -Type Info
        Write-StatusMessage -Message "Current startup type: $($service.StartType)" -Type Info
        
        # Determine action based on current startup type
        if ($service.StartType -eq "Disabled") {
            # Enable the service and start it
            Set-Service -Name $ServiceName -StartupType $EnableStartupType -ErrorAction Stop
            Start-Service -Name $ServiceName -ErrorAction Stop
            Write-StatusMessage -Message "$ServiceDisplayName enabled and started" -Type Success
            Write-StatusMessage -Message "$ServiceDisplayName functionality is now available" -Type Warning
        } else {
            # Disable the service and stop it
            Stop-Service -Name $ServiceName -ErrorAction Stop
            Set-Service -Name $ServiceName -StartupType "Disabled" -ErrorAction Stop
            Write-StatusMessage -Message "$ServiceDisplayName stopped and disabled" -Type Success
            Write-StatusMessage -Message "$ServiceDisplayName functionality is now disabled" -Type Warning
        }
        
        # Verify the new startup type
        Start-Sleep -Seconds 2
        $newService = Get-Service -Name $ServiceName
        Write-StatusMessage -Message "New $ServiceDisplayName startup type: $($newService.StartType)" -Type Info
        Write-StatusMessage -Message "Current service status: $($newService.Status)" -Type Info
        
        Write-StatusMessage -Message "Note: Startup type changes require a reboot to take full effect" -Type Warning
        
    } catch {
        Wait-OnError -ErrorMessage "Failed to toggle $ServiceDisplayName startup type: $($_.Exception.Message)"
    }
}

function Get-ServiceToggleStatus {
<#
.SYNOPSIS
    Gets detailed status information for a service toggle operation.
.DESCRIPTION
    Provides comprehensive status information including service existence, current state,
    startup type, and toggle recommendations.
.PARAMETER ServiceName
    The name of the service to check.
.PARAMETER ServiceDisplayName
    The display name of the service for user-friendly output.
.OUTPUTS
    PSCustomObject containing service status information.
.EXAMPLE
    $status = Get-ServiceToggleStatus -ServiceName "BDESVC" -ServiceDisplayName "BitLocker Drive Encryption"
.EXAMPLE
    Get-ServiceToggleStatus -ServiceName "lfsvc" -ServiceDisplayName "Geolocation Service" | Format-Table
#>
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$ServiceName,
    
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$ServiceDisplayName
)

    try {
        $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
        
        if (-not $service) {
            return [PSCustomObject]@{
                ServiceName = $ServiceName
                ServiceDisplayName = $ServiceDisplayName
                Exists = $false
                Status = "Not Found"
                StartType = "N/A"
                RecommendedAction = "Service not available on this system"
                IsToggleable = $false
            }
        }
        
        $isToggleable = $true
        $recommendedAction = ""
        
        if ($service.StartType -eq "Disabled") {
            $recommendedAction = "Enable service (currently disabled)"
        } else {
            $recommendedAction = "Disable service (currently enabled)"
        }
        
        return [PSCustomObject]@{
            ServiceName = $ServiceName
            ServiceDisplayName = $ServiceDisplayName
            Exists = $true
            Status = $service.Status
            StartType = $service.StartType
            RecommendedAction = $recommendedAction
            IsToggleable = $isToggleable
        }
        
    } catch {
        $errorMsg = $_.Exception.Message
        Write-Warning ("Failed to get service status for " + $ServiceDisplayName + ": " + $errorMsg)
        return $null
    }
}

function Test-ServiceToggleRequirements {
<#
.SYNOPSIS
    Tests all requirements for a service toggle operation.
.DESCRIPTION
    Validates service existence, admin privileges, and system readiness for service toggle operations.
.PARAMETER ServiceName
    The name of the service to validate.
.PARAMETER ServiceDisplayName
    The display name of the service for user-friendly output.
.PARAMETER SkipAdminCheck
    Skip the administrator privilege check. Use with caution.
.OUTPUTS
    Boolean indicating whether all requirements are met.
.EXAMPLE
    if (Test-ServiceToggleRequirements -ServiceName "BDESVC" -ServiceDisplayName "BitLocker Drive Encryption") {
        Invoke-ServiceToggle -ServiceName "BDESVC" -ServiceDisplayName "BitLocker Drive Encryption"
    }
.EXAMPLE
    Test-ServiceToggleRequirements -ServiceName "lfsvc" -ServiceDisplayName "Geolocation Service" -SkipAdminCheck
#>
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$ServiceName,
    
    [string]$ServiceDisplayName = $ServiceName,
    
    [switch]$SkipAdminCheck
)

    # Check if service exists
    if (-not (Test-ServiceExists -ServiceName $ServiceName)) {
        Write-StatusMessage -Message "$ServiceDisplayName not found on this system" -Type Warning
        Write-StatusMessage -Message "This service may not be available on your Windows version" -Type Info
        Write-StatusMessage -Message "No action taken" -Type Info
        return $false
    }
    
    # Check admin privileges if not skipped
    if (-not $SkipAdminCheck) {
        $isAdmin = Test-AdminRights
        
        if (-not $isAdmin) {
            Write-StatusMessage -Message "WARNING: This operation may require administrator privileges" -Type Warning
            Write-StatusMessage -Message "Some service operations may fail without elevated permissions" -Type Warning
            
            $continue = Show-Confirmation -Message "Continue without administrator privileges?" -DefaultChoice "No"
            if (-not $continue) {
                Write-StatusMessage -Message "Operation cancelled" -Type Info
                return $false
            }
        }
    }
    
    return $true
}

# Export the module members
Export-ModuleMember -Function Invoke-ServiceToggle, Get-ServiceToggleStatus, Test-ServiceToggleRequirements -Verbose:$false