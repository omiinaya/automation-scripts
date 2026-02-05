# Audit: 18.5.12
# CIS Benchmark: 18.5.12 (L1)

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
                $currentSetting = "$value retransmissions"
            } else {
                # Value doesn't exist, which means default (5 retransmissions)
                $value = 5
                $currentSetting = "$value retransmissions [Default]"
            }
        } else {
            # Key doesn't exist, which means default behavior
            $value = 5
            $currentSetting = "$value retransmissions [Default - Key Not Found]"
        }
        
        # Determine compliance (must be 3 retransmissions or less)
        $isCompliant = ($value -le 3)
        
        return @{
            CurrentValue = $currentSetting
            Source = "Registry"
            Details = "Registry path: $registryPath, Value: $registryValueName, Raw Value: $value retransmissions"
            IsCompliant = $isCompliant
        }
}
