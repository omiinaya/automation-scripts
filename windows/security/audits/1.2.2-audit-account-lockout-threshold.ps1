# Audit: Account lockout threshold setting on Windows
# CIS Benchmark: 1.2.2 (L1) Ensure 'Account lockout threshold' is set to '5 or fewer invalid logon attempt(s), but not 0'
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
        Write-SectionHeader -Title "Account Lockout Policy Audit: Account Lockout Threshold"
    }
    
    # Use Invoke-CISAudit with custom script block for account lockout threshold audit
    $auditResult = Invoke-CISAudit -CIS_ID "1.2.2" -AuditType "Custom" -VerboseOutput:$VerboseOutput -Section "1" -CustomScriptBlock {
        # Check if this is a domain environment
        $isDomainMember = (Get-CimInstance -ClassName Win32_ComputerSystem).PartOfDomain
        
        # Check the actual setting using secedit
        try {
            # Export current security policy
            $tempFile = [System.IO.Path]::GetTempFileName()
            secedit /export /cfg $tempFile /quiet
            
            # Read the exported policy
            $policyContent = Get-Content $tempFile
            $lockoutThresholdLine = $policyContent | Where-Object { $_ -like "LockoutBadCount*" }
            
            if ($lockoutThresholdLine) {
                $lockoutThresholdValue = ($lockoutThresholdLine -split "=")[1].Trim()
                $lockoutThreshold = [int]$lockoutThresholdValue
                $source = if ($isDomainMember) { "Domain Policy" } else { "Local Policy" }
            } else {
                $lockoutThreshold = 0
                $source = if ($isDomainMember) { "Domain Default" } else { "Local Default" }
            }
            
            # Clean up temp file
            Remove-Item $tempFile -ErrorAction SilentlyContinue
        } catch {
            $lockoutThreshold = 0
            $source = if ($isDomainMember) { "Domain Default (assumed)" } else { "Local Default (assumed)" }
        }
        
        # Return custom audit result
        return @{
            CurrentValue = $lockoutThreshold
            Source = $source
            Details = "Account lockout threshold setting audit - $(if ($isDomainMember) { 'Domain member' } else { 'Standalone workstation' })"
        }
    }
    
    # Return the compliance status
    $auditResult.IsCompliant
} catch {
    if ($VerboseOutput) {
        Wait-OnError -ErrorMessage "Failed to perform account lockout policy audit: $($_.Exception.Message)"
    } else {
        $false
    }
}