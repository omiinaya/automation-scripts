# Audit: 18.5.10
# CIS Benchmark: 18.5.10 (L1)

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
                $currentSetting = "$value seconds"
            } else {
                # Value doesn't exist, which means default (5 seconds)
                $value = 5
                $currentSetting = "$value seconds [Default]"
            }
        } else {
            # Key doesn't exist, which means default behavior
            $value = 5
            $currentSetting = "$value seconds [Default - Key Not Found]"
        }
        
        # Determine compliance (must be 5 seconds or less)
        $isCompliant = ($value -le 5)
        
        return @{
            CurrentValue = $currentSetting
            Source = "Registry"
            Details = "Registry path: $registryPath, Value: $registryValueName, Raw Value: $value seconds"
            IsCompliant = $isCompliant
        }
}
