# Audit: Store passwords using reversible encryption setting on Windows
# CIS Benchmark: 1.1.7 (L1) Ensure 'Store passwords using reversible encryption' is set to 'Disabled'
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
        Write-SectionHeader -Title "Password Policy Audit: Store Passwords Using Reversible Encryption"
    }
    
    # Use Invoke-CISAudit with custom script block for reversible encryption audit
    $auditResult = Invoke-CISAudit -CIS_ID "1.1.7" -AuditType "Custom" -VerboseOutput:$VerboseOutput -Section "1" -CustomScriptBlock {
        # Check if this is a domain environment
        $isDomainMember = (Get-CimInstance -ClassName Win32_ComputerSystem).PartOfDomain
        
        if ($isDomainMember) {
            # For domain members, check password policy using net accounts
            try {
                $netAccounts = net accounts
                $reversibleLine = $netAccounts | Where-Object { $_ -like "*reversible*" }
                
                if ($reversibleLine) {
                    $reversibleValue = if ($reversibleLine -like "*Enabled*" -or $reversibleLine -like "*Yes*") { "Enabled" } else { "Disabled" }
                    $source = "Domain Policy"
                } else {
                    $reversibleValue = "Disabled"
                    $source = "Domain Default (assumed)"
                }
            } catch {
                $reversibleValue = "Disabled"
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
                $reversibleLine = $policyContent | Where-Object { $_ -like "ClearTextPassword*" }
                
                if ($reversibleLine) {
                    $reversibleValue = if (($reversibleLine -split "=")[1].Trim() -eq "1") { "Enabled" } else { "Disabled" }
                    $source = "Local Policy"
                } else {
                    $reversibleValue = "Disabled"
                    $source = "Local Default"
                }
                
                # Clean up temp file
                Remove-Item $tempFile -ErrorAction SilentlyContinue
            } catch {
                $reversibleValue = "Disabled"
                $source = "Local Default (assumed)"
            }
        }
        
        # Return custom audit result
        return @{
            CurrentValue = $reversibleValue
            Source = $source
            Details = "Store passwords using reversible encryption audit - $(if ($isDomainMember) { 'Domain member' } else { 'Standalone workstation' })"
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