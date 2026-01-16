# Audit: Minimum password age setting on Windows
# CIS Benchmark: 1.1.3 (L1) Ensure 'Minimum password age' is set to '1 or more day(s)'
# Refactored to use CIS Framework Module

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
        Write-SectionHeader -Title "Password Policy Audit: Minimum Password Age"
    }
    
    # Use Invoke-CISAudit with custom script block for minimum password age audit
    $auditResult = Invoke-CISAudit -CIS_ID "1.1.3" -AuditType "Custom" -VerboseOutput:$VerboseOutput -Section "1" -CustomScriptBlock {
        # Check if this is a domain environment
        $isDomainMember = (Get-CimInstance -ClassName Win32_ComputerSystem).PartOfDomain
        
        if ($isDomainMember) {
            # For domain members, check password policy using net accounts
            try {
                $netAccounts = net accounts
                $passwordAgeLine = $netAccounts | Where-Object { $_ -like "*Minimum password age*" }
                
                if ($passwordAgeLine) {
                    $passwordAgeValue = [int]($passwordAgeLine -replace "[^\d]", "")
                    $source = "Domain Policy"
                } else {
                    $passwordAgeValue = 1
                    $source = "Domain Default (assumed)"
                }
            } catch {
                $passwordAgeValue = 1
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
                $passwordAgeLine = $policyContent | Where-Object { $_ -like "MinimumPasswordAge*" }
                
                if ($passwordAgeLine) {
                    $passwordAgeValue = [int]($passwordAgeLine -split "=")[1].Trim()
                    $source = "Local Policy"
                } else {
                    $passwordAgeValue = 0
                    $source = "Local Default"
                }
                
                # Clean up temp file
                Remove-Item $tempFile -ErrorAction SilentlyContinue
            } catch {
                $passwordAgeValue = 0
                $source = "Local Default (assumed)"
            }
        }
        
        # Return custom audit result
        return @{
            CurrentValue = $passwordAgeValue
            Source = $source
            Details = "Minimum password age setting audit - $(if ($isDomainMember) { 'Domain member' } else { 'Standalone workstation' })"
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