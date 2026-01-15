# Remediation: Adjust memory quotas for a process setting on Windows
# CIS Benchmark: 2.2.4 (L1) Ensure 'Adjust memory quotas for a process' is set to 'Administrators, LOCAL SERVICE, NETWORK SERVICE'
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
        Write-SectionHeader -Title "User Rights Assignment Remediation: Adjust memory quotas for a process"
    }
    
    # Create security policy template
    $templateContent = @"
[Unicode]
Unicode=yes
[Version]
signature="`$CHICAGO`$"
Revision=1
[Privilege Rights]
SeIncreaseQuotaPrivilege = *S-1-5-32-544,*S-1-5-19,*S-1-5-20
"@
    
    # Invoke remediation using CISRemediation framework
    $result = Invoke-CISRemediation -CIS_ID "2.2.4" -RemediationType "SecurityPolicy" -SecurityPolicyTemplate $templateContent -SettingName "SeIncreaseQuotaPrivilege" -VerboseOutput:$VerboseOutput
    
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