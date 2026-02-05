<#
.SYNOPSIS
Audit script template for CIS benchmark compliance checks.
.DESCRIPTION
This template provides the standardized structure used by all audit scripts.
.NOTES
Template Version: 2.0
Author: System Administrator
Prerequisite: PowerShell 5.1 or later
#>

[CmdletBinding()]
param()

$VerboseOutput = $PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Verbose')

# Import the required modules using ModuleIndex
$modulePath = Join-Path $PSScriptRoot "..\..\..\modules\ModuleIndex.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

# Check admin rights and handle elevation
if (-not (Test-AdminRights)) {
    Invoke-Elevation
}

try {
    if ($VerboseOutput) {
        Write-SectionHeader -Title "Audit Title"
    }

    # Use Invoke-CISAudit with appropriate audit type
    $auditResult = Invoke-CISAudit -CIS_ID "X.X.X" -AuditType "Registry" -VerboseOutput:$VerboseOutput -Section "X"

    # Return the structured audit result
    return $auditResult
} catch {
    if ($VerboseOutput) {
        Wait-OnError -ErrorMessage "Failed to perform audit: $($_.Exception.Message)"
    } else {
        $false
    }
}
