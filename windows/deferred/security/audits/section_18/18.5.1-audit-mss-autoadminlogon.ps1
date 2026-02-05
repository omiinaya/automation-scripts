# Audit: 18.5.1
# CIS Benchmark: 18.5.1 (L1)

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
                
                # Convert to string for comparison
                if ($value -eq "0") {
                    $currentSetting = "Disabled"
                } elseif ($value -eq "1") {
                    $currentSetting = "Enabled"
                } else {
                    $currentSetting = $value.ToString()
                }
            } else {
                # Value doesn't exist, which means it's not configured (default is Disabled)
                $currentSetting = "Disabled"
                $value = "Not Configured"
            }
        } else {
            # Key doesn't exist, which means default behavior
            $currentSetting = "Disabled"
            $value = "Key Not Found"
        }
        
        # Determine compliance (must be Disabled)
        $isCompliant = ($currentSetting -eq "Disabled")
        
        return @{
            CurrentValue = $currentSetting
            Source = "Registry"
            Details = "Registry path: $registryPath, Value: $registryValueName, Raw Value: $value"
            IsCompliant = $isCompliant
        }
}
