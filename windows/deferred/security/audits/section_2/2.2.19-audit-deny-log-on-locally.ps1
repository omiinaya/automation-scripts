# Audit: 2.2.19
# CIS Benchmark: 2.2.19 (L1)

[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISAuditScript -ScriptRoot $scriptRoot -AuditBlock {
if ($VerboseOutput) {
        Write-SectionHeader -Title "User Rights Assignment Audit: Deny log on locally"
    }
    
    # Define custom audit script block
    $auditScriptBlock = {
        # Get the current user rights assignment
        $currentRights = Get-UserRightsAssignment -Privilege "SeDenyInteractiveLogonRight"
        
        # Check if Guests are included
        $guestsIncluded = $currentRights -like "*S-1-5-32-546*" -or $currentRights -like "*Guests*"
        
        # Return audit result
        @{
            IsCompliant = $guestsIncluded
            CurrentValue = $currentRights
            ExpectedValue = "Guests"
            Description = "Deny log on locally should include Guests group"
        }
    }
    
    # Invoke audit using CISFramework
    $result = Invoke-CISAudit -CIS_ID "2.2.19" -AuditScriptBlock $auditScriptBlock -VerboseOutput:$VerboseOutput
    
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
