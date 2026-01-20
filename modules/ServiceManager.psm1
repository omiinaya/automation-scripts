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

# Import only the specific modules needed to avoid circular dependencies
Import-Module "$PSScriptRoot\WindowsUtils.psm1" -Force -WarningAction SilentlyContinue
Import-Module "$PSScriptRoot\WindowsUI.psm1" -Force -WarningAction SilentlyContinue

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
    Note: Admin privilege checking is now handled by Invoke-CISScript with AutoElevate parameter.
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
    
    # Admin privilege checking is now handled by Invoke-CISScript with AutoElevate parameter
    # This function only validates service existence when SkipAdminCheck is used
    
    return $true
}

# Function to set service compliance state with unified service management
function Set-ServiceCompliance {
    <#
    .SYNOPSIS
        Unified service compliance management function.
    .DESCRIPTION
        Eliminates duplicate service toggle logic by providing a single function
        for service compliance management across all scripts.
    .PARAMETER ServiceName
        The name of the service to manage.
    .PARAMETER ServiceDisplayName
        The display name of the service for user-friendly output.
    .PARAMETER ComplianceState
        The desired compliance state (Compliant, NonCompliant).
    .PARAMETER CIS_ID
        CIS benchmark ID for audit tracking.
    .PARAMETER ExpectedStartupType
        Expected startup type for compliant state (Manual, Automatic, Disabled).
    .PARAMETER ExpectedServiceState
        Expected service state for compliant state (Running, Stopped).
    .PARAMETER VerboseOutput
        Enable verbose output.
    .EXAMPLE
        Set-ServiceCompliance -ServiceName "BDESVC" -ServiceDisplayName "BitLocker Drive Encryption" -ComplianceState "Compliant" -CIS_ID "2.3.1.1"
    .EXAMPLE
        Set-ServiceCompliance -ServiceName "lfsvc" -ServiceDisplayName "Geolocation Service" -ComplianceState "NonCompliant" -ExpectedStartupType "Disabled"
    .OUTPUTS
        PSCustomObject containing service compliance result.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$ServiceName,
        
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$ServiceDisplayName,
        
        [Parameter(Mandatory=$true)]
        [ValidateSet("Compliant", "NonCompliant")]
        [string]$ComplianceState,
        
        [string]$CIS_ID,
        
        [ValidateSet("Manual", "Automatic", "Disabled")]
        [string]$ExpectedStartupType,
        
        [ValidateSet("Running", "Stopped")]
        [string]$ExpectedServiceState,
        
        [switch]$VerboseOutput
    )
    
    try {
        # Check service requirements
        if (-not (Test-ServiceToggleRequirements -ServiceName $ServiceName -ServiceDisplayName $ServiceDisplayName)) {
            return [PSCustomObject]@{
                ServiceName = $ServiceName
                ServiceDisplayName = $ServiceDisplayName
                ComplianceState = "Error"
                Status = "Service requirements not met"
                IsCompliant = $false
                RequiresManualAction = $true
                ErrorMessage = "Service requirements validation failed"
            }
        }
        
        # Get current service status
        $service = Get-Service -Name $ServiceName -ErrorAction Stop
        
        if ($VerboseOutput) {
            Write-StatusMessage -Message "Current $ServiceDisplayName status: $($service.Status)" -Type Info
            Write-StatusMessage -Message "Current startup type: $($service.StartType)" -Type Info
        }
        
        # Determine target state based on compliance state
        switch ($ComplianceState) {
            "Compliant" {
                # Set service to compliant state
                if ($service.StartType -eq "Disabled") {
                    # Enable the service
                    $targetStartupType = if ($ExpectedStartupType) { $ExpectedStartupType } else { "Manual" }
                    Set-Service -Name $ServiceName -StartupType $targetStartupType -ErrorAction Stop
                    
                    # Start the service if expected state is Running
                    if ($ExpectedServiceState -eq "Running" -or (-not $ExpectedServiceState)) {
                        Start-Service -Name $ServiceName -ErrorAction Stop
                    }
                    
                    $statusMessage = "$ServiceDisplayName enabled and set to $targetStartupType"
                    $isCompliant = $true
                } else {
                    # Service is already enabled, verify state
                    if ($ExpectedServiceState -and $service.Status -ne $ExpectedServiceState) {
                        if ($ExpectedServiceState -eq "Running") {
                            Start-Service -Name $ServiceName -ErrorAction Stop
                        } else {
                            Stop-Service -Name $ServiceName -ErrorAction Stop
                        }
                        $statusMessage = "$ServiceDisplayName state adjusted to $ExpectedServiceState"
                    } else {
                        $statusMessage = "$ServiceDisplayName already compliant"
                    }
                    $isCompliant = $true
                }
            }
            "NonCompliant" {
                # Set service to non-compliant state (disabled)
                if ($service.StartType -ne "Disabled") {
                    Stop-Service -Name $ServiceName -ErrorAction Stop
                    Set-Service -Name $ServiceName -StartupType "Disabled" -ErrorAction Stop
                    $statusMessage = "$ServiceDisplayName stopped and disabled"
                } else {
                    $statusMessage = "$ServiceDisplayName already non-compliant"
                }
                $isCompliant = $false
            }
        }
        
        # Verify the new state
        Start-Sleep -Seconds 2
        $newService = Get-Service -Name $ServiceName
        
        if ($VerboseOutput) {
            Write-StatusMessage -Message "New $ServiceDisplayName startup type: $($newService.StartType)" -Type Info
            Write-StatusMessage -Message "Current service status: $($newService.Status)" -Type Info
            Write-StatusMessage -Message "Service compliance operation completed" -Type Success
        }
        
        return [PSCustomObject]@{
            ServiceName = $ServiceName
            ServiceDisplayName = $ServiceDisplayName
            ComplianceState = $ComplianceState
            Status = $statusMessage
            IsCompliant = $isCompliant
            RequiresManualAction = $false
            PreviousStartupType = $service.StartType
            NewStartupType = $newService.StartType
            PreviousServiceState = $service.Status
            NewServiceState = $newService.Status
            CIS_ID = $CIS_ID
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            ComputerName = $env:COMPUTERNAME
        }
        
    } catch {
        $errorInfo = Handle-CISError -ErrorRecord $_ -ScriptType "ServiceToggle" -ServiceName $ServiceName -CIS_ID $CIS_ID
        
        return [PSCustomObject]@{
            ServiceName = $ServiceName
            ServiceDisplayName = $ServiceDisplayName
            ComplianceState = "Error"
            Status = "Service compliance operation failed"
            IsCompliant = $false
            RequiresManualAction = $true
            ErrorMessage = $errorInfo.ErrorMessage
            Recommendation = $errorInfo.Recommendation
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
    }
}

# Export the module members
Export-ModuleMember -Function Invoke-ServiceToggle, Get-ServiceToggleStatus, Test-ServiceToggleRequirements, Set-ServiceCompliance -Verbose:$false