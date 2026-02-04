<#
.SYNOPSIS
    Audits CIS control 19.6.6.1.1 - Turn off Help Experience Improvement Program
.DESCRIPTION
    This script audits whether the Help Experience Improvement Program is disabled as recommended by CIS.
.NOTES
    CIS ID: 19.6.6.1.1
    Profile: L2
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
    $registryPath = "Registry::HKEY_USERS\$currentUserSid\Software\Policies\Microsoft\Assistance\Client\1.0"
    $valueName = "NoImplicitFeedback"
    
    # Check if registry key exists
    if (Test-Path $registryPath) {
        $currentValue = Get-ItemProperty -Path $registryPath -Name $valueName -ErrorAction SilentlyContinue
        
        if ($currentValue -and $currentValue.$valueName -eq 1) {
            return @{
                CurrentValue = "Enabled (1)"
                RecommendedValue = "Enabled"
                IsCompliant = $true
                Source = "Registry"
                Details = "Help Experience Improvement Program is disabled"
            }
        } else {
            return @{
                CurrentValue = "Disabled or Not Configured"
                RecommendedValue = "Enabled"
                IsCompliant = $false
                Source = "Registry"
                Details = "Help Experience Improvement Program is enabled"
            }
        }
    } else {
        return @{
            CurrentValue = "Not Configured"
            RecommendedValue = "Enabled"
            IsCompliant = $false
            Source = "Registry"
            Details = "Registry key does not exist"
        }
    }
}
