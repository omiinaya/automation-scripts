# Audit: 18.6.7.4
# CIS Benchmark: 18.6.7.4 (L1)

[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISAuditScript -ScriptRoot $scriptRoot -AuditBlock {
# Check if registry key exists
        if (Test-Path $registryPath) {
            # Get the current value
            $currentValue = Get-ItemProperty -Path $registryPath -Name $registryValueName -ErrorAction SilentlyContinue
            
            if ($currentValue) {
                $value = $currentValue.$registryValueName
                $currentSetting = if ($value -eq 1) { "Enabled" } else { "Disabled" }
            } else {
                # Value doesn't exist, which means default (Enabled)
                $value = 1
                $currentSetting = "Enabled [Default]"
            }
        } else {
            # Key doesn't exist, which means default behavior
            $value = 1
            $currentSetting = "Enabled [Default - Key Not Found]"
        }
        
        # Determine compliance (must be Enabled - value 1)
        $isCompliant = ($value -eq 1)
        
        return @{
            CurrentValue = $currentSetting
            Source = "Registry"
            Details = "Registry path: $registryPath, Value: $registryValueName, Raw Value: $value"
            IsCompliant = $isCompliant
        }
}
