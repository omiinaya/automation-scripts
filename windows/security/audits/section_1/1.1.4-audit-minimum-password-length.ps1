# Audit: Minimum password length setting on Windows
# CIS Benchmark: 1.1.4 (L1) Ensure 'Minimum password length' is set to '14 or more character(s)'
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
        Write-SectionHeader -Title "Password Policy Audit: Minimum Password Length"
    }
    
    # Use Invoke-CISAudit with custom script block for minimum password length audit
    $auditResult = Invoke-CISAudit -CIS_ID "1.1.4" -AuditType "Custom" -VerboseOutput:$VerboseOutput -Section "1" -CustomScriptBlock {
        # Check if this is a domain environment
        $isDomainMember = (Get-CimInstance -ClassName Win32_ComputerSystem).PartOfDomain
        
        if ($isDomainMember) {
            # For domain members, check password policy using net accounts
            try {
                $netAccounts = net accounts
                $passwordLengthLine = $netAccounts | Where-Object { $_ -like "*Minimum password length*" }
                
                if ($passwordLengthLine) {
                    $passwordLengthValue = [int]($passwordLengthLine -replace "[^\d]", "")
                    $source = "Domain Policy"
                } else {
                    $passwordLengthValue = 7
                    $source = "Domain Default (assumed)"
                }
            } catch {
                $passwordLengthValue = 7
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
                $passwordLengthLine = $policyContent | Where-Object { $_ -like "MinimumPasswordLength*" }
                
                if ($passwordLengthLine) {
                    $passwordLengthValue = [int]($passwordLengthLine -split "=")[1].Trim()
                    $source = "Local Policy"
                } else {
                    $passwordLengthValue = 0
                    $source = "Local Default"
                }
                
                # Clean up temp file
                Remove-Item $tempFile -ErrorAction SilentlyContinue
            } catch {
                $passwordLengthValue = 0
                $source = "Local Default (assumed)"
            }
        }
        
        # Return custom audit result
        return @{
            CurrentValue = $passwordLengthValue
            Source = $source
            Details = "Minimum password length setting audit - $(if ($isDomainMember) { 'Domain member' } else { 'Standalone workstation' })"
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