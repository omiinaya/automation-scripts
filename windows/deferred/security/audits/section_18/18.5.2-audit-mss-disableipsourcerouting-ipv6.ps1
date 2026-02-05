# Audit: 18.5.2
# CIS Benchmark: 18.5.2 (L1)

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
                
                # Map numeric values to their meanings
                # 0 = No additional protection, source routed packets are allowed
                # 1 = Medium, source routed packets ignored when IP forwarding is enabled
                # 2 = Highest protection, source routing is completely disabled
                
                switch ($value) {
                    0 { $currentSetting = "No protection" }
                    1 { $currentSetting = "Medium protection" }
                    2 { $currentSetting = "Highest protection" }
                    default { $currentSetting = "Unknown ($value)" }
                }
            } else {
                # Value doesn't exist, which means default (0 = No protection)
                $currentSetting = "No protection"
                $value = "Not Configured (default: 0)"
            }
        } else {
            # Key doesn't exist, which means default behavior
            $currentSetting = "No protection"
            $value = "Key Not Found (default: 0)"
        }
        
        # Determine compliance (must be Highest protection = 2)
        $isCompliant = ($currentSetting -eq "Highest protection")
        
        return @{
            CurrentValue = $currentSetting
            Source = "Registry"
            Details = "Registry path: $registryPath, Value: $registryValueName, Raw Value: $value"
            IsCompliant = $isCompliant
        }
}
