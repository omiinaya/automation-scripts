# Audit: Deny log on as a service setting on Windows
# CIS Benchmark: 2.2.18 (L1) Ensure 'Deny log on as a service' to include 'Guests'
# Refactored to use CISFramework

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
        Write-SectionHeader -Title "User Rights Assignment Audit: Deny log on as a service"
    }
    
    # Define custom audit script block
    $auditScriptBlock = {
        # Get the current user rights assignment
        $currentRights = Get-UserRightsAssignment -Privilege "SeDenyServiceLogonRight"
        
        # Check if Guests are included
        $guestsIncluded = $currentRights -like "*S-1-5-32-546*" -or $currentRights -like "*Guests*"
        
        # Return audit result
        @{
            IsCompliant = $guestsIncluded
            CurrentValue = $currentRights
            ExpectedValue = "Guests"
            Description = "Deny log on as a service should include Guests group"
        }
    }
    
    # Invoke audit using CISFramework
    $result = Invoke-CISAudit -CIS_ID "2.2.18" -AuditScriptBlock $auditScriptBlock -VerboseOutput:$VerboseOutput
    
    # Return appropriate result based on verbose mode
    if ($VerboseOutput) {
        $result
    } else {
        $result.IsCompliant
    }
    
} catch {
    if ($VerboseOutput) {
        Wait-OnError -ErrorMessage "Failed to perform user rights assignment audit: $($_.Exception.Message)"
    } else {
        $false
    }
}