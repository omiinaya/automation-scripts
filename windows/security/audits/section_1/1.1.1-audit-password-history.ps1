# Audit: Enforce password history setting on Windows
# CIS Benchmark: 1.1.1 (L1) Ensure 'Enforce password history' is set to '24 or more password(s)'
# Refactored to use CIS Framework Module

[CmdletBinding()]
param()

$VerboseOutput = $PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Verbose')

# Import the required modules using ModuleIndex
$modulePath = Join-Path $PSScriptRoot "..\..\..\..\modules\ModuleIndex.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

# Check admin rights and handle elevation
if (-not (Test-AdminRights)) {
    Invoke-Elevation
}

try {
    if ($VerboseOutput) {
        Write-SectionHeader -Title "Password Policy Audit: Enforce Password History"
    }
    
    # Use Invoke-CISAudit with custom script block for password history audit
    $auditResult = Invoke-CISAudit -CIS_ID "1.1.1" -AuditType "Custom" -VerboseOutput:$VerboseOutput -Section "1" -CustomScriptBlock {
        # Check if this is a domain environment
        $isDomainMember = (Get-CimInstance -ClassName Win32_ComputerSystem).PartOfDomain
        
        if ($isDomainMember) {
            # For domain members, check password policy using net accounts
            try {
                $netAccounts = net accounts
                $passwordHistoryLine = $netAccounts | Where-Object { $_ -like "*Password history*" }
                
                if ($passwordHistoryLine) {
                    $passwordHistoryValue = [int]($passwordHistoryLine -replace "[^\d]", "")
                    $source = "Domain Policy"
                } else {
                    $passwordHistoryValue = 24
                    $source = "Domain Default (assumed)"
                }
            } catch {
                $passwordHistoryValue = 24
                $source = "Domain Default (assumed)"
            }
        } else {
            # For standalone systems, check local policy using secedit
            try {
                # Export current security policy
                $tempFile = [System.IO.Path]::GetTempFileName()
                secedit /export /cfg $tempFile /quiet
                
                # Read the exported policy
                $policyContent = Get-Content $tempFile
                $passwordHistoryLine = $policyContent | Where-Object { $_ -like "PasswordHistorySize*" }
                
                if ($passwordHistoryLine) {
                    $passwordHistoryValue = [int]($passwordHistoryLine -split "=")[1].Trim()
                    $source = "Local Policy"
                } else {
                    $passwordHistoryValue = 0
                    $source = "Local Default"
                }
                
                # Clean up temp file
                Remove-Item $tempFile -ErrorAction SilentlyContinue
            } catch {
                $passwordHistoryValue = 0
                $source = "Local Default (assumed)"
            }
        }
        
        # Return custom audit result
        return @{
            CurrentValue = $passwordHistoryValue
            Source = $source
            Details = "Password history setting audit - $(if ($isDomainMember) { 'Domain member' } else { 'Standalone workstation' })"
        }
    }
    
    # Return the compliance status
    $auditResult.IsCompliant
} catch {
    if ($VerboseOutput) {
        Wait-OnError -ErrorMessage "Failed to perform password policy audit: $($_.Exception.Message)"
    } else {
        $false
    }
}
