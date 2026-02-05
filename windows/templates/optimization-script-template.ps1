<#
.SYNOPSIS
Optimization script template for Windows settings.
.DESCRIPTION
This template provides the standardized structure used by all optimization scripts.
.NOTES
Template Version: 2.0
Author: System Administrator
Prerequisite: PowerShell 5.1 or later
#>

[CmdletBinding()]
param()

# Import the ModuleIndex module which includes all modules
$modulePath = Join-Path $PSScriptRoot "..\..\..\modules\ModuleIndex.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

# Toggle the setting using the CISFramework with automatic elevation
Invoke-CISScript -ScriptType "Optimization" -AutoElevate -ScriptBlock {
    try {
        $registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        $valueName = "YourValueName"

        # Ensure the registry path exists
        if (-not (Test-Path $registryPath)) {
            Write-StatusMessage -Message "Creating registry path: $registryPath" -Type Info
            New-Item -Path $registryPath -Force | Out-Null
        }

        # Get current value
        $currentValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue 1

        # Toggle the setting
        $newValue = if ($currentValue -eq 1) { 0 } else { 1 }
        $newState = if ($newValue -eq 1) { "enabled" } else { "disabled" }

        # Apply the new setting
        Set-ItemProperty -Path $registryPath -Name $valueName -Value $newValue -Type DWord

        # Refresh Explorer if needed
        Invoke-ExplorerRefresh

        Write-StatusMessage -Message "Setting: $newState" -Type Success
        Write-StatusMessage -Message "Changes applied immediately - no restart required" -Type Info
    } catch {
        Wait-OnError -ErrorMessage "Failed to toggle setting: $($_.Exception.Message)"
    }
}
