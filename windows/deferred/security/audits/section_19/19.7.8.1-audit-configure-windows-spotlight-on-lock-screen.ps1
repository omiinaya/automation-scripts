<#
.SYNOPSIS
    Audits CIS control 19.7.8.1 - Configure Windows spotlight on lock screen
.DESCRIPTION
    This script audits whether Windows Spotlight on lock screen is disabled as recommended by CIS.
.NOTES
    CIS ID: 19.7.8.1
    Profile: L1
#>

[CmdletBinding()]
param()

# Import ScriptTemplates module and invoke audit with boilerplate handling
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISAuditScript -ScriptRoot $scriptRoot -AuditBlock {
    # Get current user SID
    $currentUserSid = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value
    
    # Construct registry path
    $registryPath = "Registry::HKEY_USERS\$currentUserSid\Software\Policies\Microsoft\Windows\CloudContent"
    $valueName = "ConfigureWindowsSpotlight"
    
    # Check if registry key exists
    if (Test-Path $registryPath) {
        $currentValue = Get-ItemProperty -Path $registryPath -Name $valueName -ErrorAction SilentlyContinue
        
        if ($currentValue -and $currentValue.$valueName -eq 2) {
            return @{
                CurrentValue = "Disabled (2)"
                RecommendedValue = "Disabled"
                IsCompliant = $true
                Source = "Registry"
                Details = "Windows Spotlight on lock screen is disabled"
            }
        } else {
            return @{
                CurrentValue = "Enabled or Not Configured"
                RecommendedValue = "Disabled"
                IsCompliant = $false
                Source = "Registry"
                Details = "Windows Spotlight on lock screen is enabled"
            }
        }
    } else {
        return @{
            CurrentValue = "Not Configured"
            RecommendedValue = "Disabled"
            IsCompliant = $false
            Source = "Registry"
            Details = "Registry key does not exist"
        }
    }
}
