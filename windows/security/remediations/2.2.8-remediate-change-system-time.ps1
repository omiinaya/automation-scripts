# Remediation: Change the system time setting on Windows
# CIS Benchmark: 2.2.8 (L1) Ensure 'Change the system time' is set to 'Administrators, LOCAL SERVICE'
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
        Write-SectionHeader -Title "User Rights Assignment Remediation: Change the system time"
    }
    
    # Create security policy template
    $templateContent = @"
[Unicode]
Unicode=yes
[Version]
signature="`$CHICAGO`$"
Revision=1
[Privilege Rights]
SeSystemtimePrivilege = *S-1-5-32-544,*S-1-5-19
"@
    
    # Invoke remediation using CISRemediation framework
    $result = Invoke-CISRemediation -CIS_ID "2.2.8" -RemediationType "SecurityPolicy" -SecurityPolicyTemplate $templateContent -SettingName "SeSystemtimePrivilege" -VerboseOutput:$VerboseOutput
    
    # Return appropriate result based on verbose mode
    if ($VerboseOutput) {
        $result
    } else {
        $result.IsCompliant
    }
    
} catch {
    if ($VerboseOutput) {
        Wait-OnError -ErrorMessage "Failed to perform user rights assignment remediation: $($_.Exception.Message)"
    } else {
        $false
    }
}