# Audit: Account lockout duration setting on Windows
# CIS Benchmark: 1.2.1 (L1) Ensure 'Account lockout duration' is set to '15 or more minute(s)'
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
        Write-SectionHeader -Title "Account Lockout Policy Audit: Account Lockout Duration"
    }
    
    # Use Invoke-CISAudit with custom script block for account lockout duration audit
    $auditResult = Invoke-CISAudit -CIS_ID "1.2.1" -AuditType "Custom" -VerboseOutput:$VerboseOutput -Section "1" -CustomScriptBlock {
        # Check if this is a domain environment
        $isDomainMember = (Get-CimInstance -ClassName Win32_ComputerSystem).PartOfDomain
        
        # Check the actual setting using secedit
        try {
            # Export current security policy
            $tempFile = [System.IO.Path]::GetTempFileName()
            secedit /export /cfg $tempFile /quiet
            
            # Read the exported policy
            $policyContent = Get-Content $tempFile
            $lockoutDurationLine = $policyContent | Where-Object { $_ -like "LockoutDuration*" }
            
            if ($lockoutDurationLine) {
                $lockoutDurationValue = ($lockoutDurationLine -split "=")[1].Trim()
                $lockoutDuration = [int]$lockoutDurationValue
                $source = if ($isDomainMember) { "Domain Policy" } else { "Local Policy" }
            } else {
                $lockoutDuration = 0
                $source = if ($isDomainMember) { "Domain Default" } else { "Local Default" }
            }
            
            # Clean up temp file
            Remove-Item $tempFile -ErrorAction SilentlyContinue
        } catch {
            $lockoutDuration = 0
            $source = if ($isDomainMember) { "Domain Default (assumed)" } else { "Local Default (assumed)" }
        }
        
        # Return custom audit result
        return @{
            CurrentValue = $lockoutDuration
            Source = $source
            Details = "Account lockout duration setting audit - $(if ($isDomainMember) { 'Domain member' } else { 'Standalone workstation' })"
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