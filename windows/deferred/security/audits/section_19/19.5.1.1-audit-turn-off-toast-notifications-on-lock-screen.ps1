<#
.SYNOPSIS
    Audits CIS control 19.5.1.1 - Turn off toast notifications on the lock screen
.DESCRIPTION
    This script audits whether toast notifications are disabled on the lock screen as recommended by CIS.
.NOTES
    CIS ID: 19.5.1.1
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
    $registryPath = "Registry::HKEY_USERS\$currentUserSid\Software\Policies\Microsoft\Windows\CurrentVersion\PushNotifications"
    $valueName = "NoToastApplicationNotificationOnLockScreen"
    
    # Check if registry key exists
    if (Test-Path $registryPath) {
        $currentValue = Get-ItemProperty -Path $registryPath -Name $valueName -ErrorAction SilentlyContinue
        
        if ($currentValue -and $currentValue.$valueName -eq 1) {
            return @{
                CurrentValue = "Enabled (1)"
                RecommendedValue = "Enabled"
                IsCompliant = $true
                Source = "Registry"
                Details = "Toast notifications are disabled on lock screen"
            }
        } else {
            return @{
                CurrentValue = "Disabled or Not Configured"
                RecommendedValue = "Enabled"
                IsCompliant = $false
                Source = "Registry"
                Details = "Toast notifications are enabled on lock screen"
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
