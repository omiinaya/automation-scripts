# Audit: 18.5.13
# CIS Benchmark: 18.5.13 (L1)

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
                $currentSetting = "$value%"
            } else {
                # Value doesn't exist, which means default (0% - no warning)
                $value = 0
                $currentSetting = "$value% [Default - No Warning]"
            }
        } else {
            # Key doesn't exist, which means default behavior
            $value = 0
            $currentSetting = "$value% [Default - Key Not Found]"
        }
        
        # Determine compliance (must be 90% or less, but not 0%)
        $isCompliant = ($value -le 90 -and $value -gt 0)
        
        return @{
            CurrentValue = $currentSetting
            Source = "Registry"
            Details = "Registry path: $registryPath, Value: $registryValueName, Raw Value: $value%"
            IsCompliant = $isCompliant
        }
}
