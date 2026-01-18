# Remediation: Access Credential Manager as a trusted caller setting on Windows
# CIS Benchmark: 2.2.1 (L1) Ensure 'Access Credential Manager as a trusted caller' is set to 'No One'
# Refactored to use CISRemediation framework

[CmdletBinding()]
param()

$VerboseOutput = $PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Verbose')

# Import the Windows modules
$modulePath = Join-Path $PSScriptRoot "..\..\..\..\modules\ModuleIndex.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

# Check admin rights and handle elevation
if (-not (Test-AdminRights)) {
    Invoke-Elevation
}

try {
    if ($VerboseOutput) {
        Write-SectionHeader -Title "User Rights Assignment Remediation: Access Credential Manager as a trusted caller"
    }
    
    # Create security policy template
    $templateContent = @"
[Unicode]
Unicode=yes
[Version]
signature="`$CHICAGO`$"
Revision=1
[Privilege Rights]
SeTrustedCredManAccessPrivilege =
"@
    
    # Invoke remediation using CISRemediation framework
    $result = Invoke-CISRemediation -CIS_ID "2.2.1" -RemediationType "SecurityPolicy" -SecurityPolicyTemplate $templateContent -SettingName "SeTrustedCredManAccessPrivilege" -VerboseOutput:$VerboseOutput
    
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