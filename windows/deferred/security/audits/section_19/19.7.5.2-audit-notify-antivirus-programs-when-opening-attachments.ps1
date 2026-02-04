<#
.SYNOPSIS
    Audits CIS control 19.7.5.2 - Notify antivirus programs when opening attachments
.DESCRIPTION
    This script audits whether antivirus programs are notified when opening attachments as recommended by CIS.
.NOTES
    CIS ID: 19.7.5.2
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
    $registryPath = "Registry::HKEY_USERS\$currentUserSid\Software\Microsoft\Windows\CurrentVersion\Policies\Attachments"
    $valueName = "ScanWithAntiVirus"
    
    # Check if registry key exists
    if (Test-Path $registryPath) {
        $currentValue = Get-ItemProperty -Path $registryPath -Name $valueName -ErrorAction SilentlyContinue
        
        if ($currentValue -and $currentValue.$valueName -eq 3) {
            return @{
                CurrentValue = "Enabled (3)"
                RecommendedValue = "Enabled"
                IsCompliant = $true
                Source = "Registry"
                Details = "Antivirus programs are notified when opening attachments"
            }
        } else {
            return @{
                CurrentValue = "Disabled or Not Configured"
                RecommendedValue = "Enabled"
                IsCompliant = $false
                Source = "Registry"
                Details = "Antivirus programs are not notified when opening attachments"
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
