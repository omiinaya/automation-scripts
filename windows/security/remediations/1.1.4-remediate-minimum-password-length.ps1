# Remediation: Minimum password length setting on Windows
# CIS Benchmark: 1.1.4 (L1) Ensure 'Minimum password length' is set to '14 or more character(s)'
# Refactored to use CISRemediation framework

[CmdletBinding()]
param()

$VerboseOutput = $PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Verbose')

# Import the Windows modules
$modulePath = Join-Path $PSScriptRoot "..\..\modules\ModuleIndex.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

# Check admin rights and handle elevation
if (-not (Test-AdminRights)) {
    Invoke-Elevation
}

try {
    if ($VerboseOutput) {
        Write-SectionHeader -Title "Password Policy Remediation: Minimum Password Length"
    }
    
    # Create security policy template
    $templateContent = @"
[Unicode]
Unicode=yes
[Version]
signature="`$CHICAGO`$"
Revision=1
[System Access]
MinimumPasswordLength=14
"@
    
    # Invoke remediation using CISRemediation framework
    $result = Invoke-CISRemediation -CIS_ID "1.1.4" -RemediationType "SecurityPolicy" -SecurityPolicyTemplate $templateContent -SettingName "MinimumPasswordLength" -VerboseOutput:$VerboseOutput
    
    # Return appropriate result based on verbose mode
    if ($VerboseOutput) {
        $result
    } else {
        $result.IsCompliant
    }
    
} catch {
    if ($VerboseOutput) {
        Wait-OnError -ErrorMessage "Failed to perform password policy remediation: $($_.Exception.Message)"
    } else {
        $false
    }
}