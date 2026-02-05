# Audit: 18.5.8
# CIS Benchmark: 18.5.8 (L1)

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
                # 0 = Disabled (IRDP disabled)
                # 1 = Enabled (IRDP enabled)
                # 2 = Enable only if DHCP sends the Perform Router Discovery option
                
                switch ($value) {
                    0 { $currentSetting = "Disabled" }
                    1 { $currentSetting = "Enabled" }
                    2 { $currentSetting = "Enabled only if DHCP sends option" }
                    default { $currentSetting = "Unknown ($value)" }
                }
            } else {
                # Value doesn't exist, which means default (2 = Enable only if DHCP sends option)
                $currentSetting = "Enabled only if DHCP sends option"
                $value = "Not Configured (default: 2)"
            }
        } else {
            # Key doesn't exist, which means default behavior
            $currentSetting = "Enabled only if DHCP sends option"
            $value = "Key Not Found (default: 2)"
        }
        
        # Determine compliance (must be Disabled = 0)
        $isCompliant = ($currentSetting -eq "Disabled")
        
        return @{
            CurrentValue = $currentSetting
            Source = "Registry"
            Details = "Registry path: $registryPath, Value: $registryValueName, Raw Value: $value"
            IsCompliant = $isCompliant
        }
}
