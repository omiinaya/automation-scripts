# Audit: 18.5.6
# CIS Benchmark: 18.5.6 (L1)

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
                
                # Convert milliseconds to minutes for readability
                $minutes = [math]::Round($value / 60000, 2)
                $currentSetting = "$value ms ($minutes minutes)"
                
                # Default is 7,200,000 ms (120 minutes)
                # Recommended is 300,000 ms (5 minutes) or less
            } else {
                # Value doesn't exist, which means default (7,200,000 ms = 120 minutes)
                $value = 7200000
                $minutes = 120
                $currentSetting = "$value ms ($minutes minutes) [Default]"
            }
        } else {
            # Key doesn't exist, which means default behavior
            $value = 7200000
            $minutes = 120
            $currentSetting = "$value ms ($minutes minutes) [Default - Key Not Found]"
        }
        
        # Determine compliance (must be 300,000 ms or less, which is 5 minutes or less)
        $isCompliant = ($value -le 300000)
        
        return @{
            CurrentValue = $currentSetting
            Source = "Registry"
            Details = "Registry path: $registryPath, Value: $registryValueName, Raw Value: $value ms"
            IsCompliant = $isCompliant
        }
}
