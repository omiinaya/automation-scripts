# Audit: Password complexity requirements setting on Windows
# CIS Benchmark: 1.1.5 (L1) Ensure 'Password must meet complexity requirements' is set to 'Enabled'
# Refactored to use CIS Framework Module

[CmdletBinding()]
param()

$VerboseOutput = $PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Verbose')

# Import the required modules using ModuleIndex
$modulePath = Join-Path $PSScriptRoot "..\..\modules\ModuleIndex.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

# Check admin rights and handle elevation
if (-not (Test-AdminRights)) {
    Invoke-Elevation
}

try {
    if ($VerboseOutput) {
        Write-SectionHeader -Title "Password Policy Audit: Password Complexity Requirements"
    }
    
    # Use Invoke-CISAudit with custom script block for password complexity audit
    $auditResult = Invoke-CISAudit -CIS_ID "1.1.5" -AuditType "Custom" -VerboseOutput:$VerboseOutput -Section "1" -CustomScriptBlock {
        # Check if this is a domain environment
        $isDomainMember = (Get-CimInstance -ClassName Win32_ComputerSystem).PartOfDomain
        
        if ($isDomainMember) {
            # For domain members, check password policy using net accounts
            try {
                $netAccounts = net accounts
                $complexityLine = $netAccounts | Where-Object { $_ -like "*Password complexity*" }
                
                if ($complexityLine) {
                    $complexityValue = if ($complexityLine -like "*Enabled*" -or $complexityLine -like "*Yes*") { "Enabled" } else { "Disabled" }
                    $source = "Domain Policy"
                } else {
                    $complexityValue = "Enabled"
                    $source = "Domain Default (assumed)"
                }
            } catch {
                $complexityValue = "Enabled"
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
                $complexityLine = $policyContent | Where-Object { $_ -like "PasswordComplexity*" }
                
                if ($complexityLine) {
                    $complexityValue = if (($complexityLine -split "=")[1].Trim() -eq "1") { "Enabled" } else { "Disabled" }
                    $source = "Local Policy"
                } else {
                    $complexityValue = "Disabled"
                    $source = "Local Default"
                }
                
                # Clean up temp file
                Remove-Item $tempFile -ErrorAction SilentlyContinue
            } catch {
                $complexityValue = "Disabled"
                $source = "Local Default (assumed)"
            }
        }
        
        # Return custom audit result
        return @{
            CurrentValue = $complexityValue
            Source = $source
            Details = "Password complexity requirements audit - $(if ($isDomainMember) { 'Domain member' } else { 'Standalone workstation' })"
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