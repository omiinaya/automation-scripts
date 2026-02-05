# Audit: 18.5.4
# CIS Benchmark: 18.5.4 (L1)

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
                # 0 = Disabled (Saving of dial-up and VPN passwords is allowed)
                # 1 = Enabled (Prevent dial-up password from being saved)
                
                switch ($value) {
                    0 { $currentSetting = "Disabled" }
                    1 { $currentSetting = "Enabled" }
                    default { $currentSetting = "Unknown ($value)" }
                }
            } else {
                # Value doesn't exist, which means default (0 = Disabled)
                $currentSetting = "Disabled"
                $value = "Not Configured (default: 0)"
            }
        } else {
            # Key doesn't exist, which means default behavior
            $currentSetting = "Disabled"
            $value = "Key Not Found (default: 0)"
        }
        
        # Determine compliance (must be Enabled = 1)
        $isCompliant = ($currentSetting -eq "Enabled")
        
        return @{
            CurrentValue = $currentSetting
            Source = "Registry"
            Details = "Registry path: $registryPath, Value: $registryValueName, Raw Value: $value"
            IsCompliant = $isCompliant
        }
}
