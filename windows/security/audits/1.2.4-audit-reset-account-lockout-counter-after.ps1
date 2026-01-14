# Audit: Reset account lockout counter after setting on Windows
# CIS Benchmark: 1.2.4 (L1) Ensure 'Reset account lockout counter after' is set to '15 or more minute(s)'
# Refactored to use modular system

[CmdletBinding()]
param()

$VerboseOutput = $PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Verbose')

# Function to pause on error
function Wait-OnError {
    param(
        [string]$ErrorMessage
    )
    Write-Host "`nERROR: $ErrorMessage" -ForegroundColor Red
    Write-Host "Press Enter to close this window..." -ForegroundColor Yellow
    Read-Host
}

# Import the Windows modules
$modulePath = Join-Path $PSScriptRoot "..\..\modules\ModuleIndex.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

# Check admin rights and handle elevation
if (-not (Test-AdminRights)) {
    Invoke-Elevation
}

try {
    if ($VerboseOutput) {
        Write-SectionHeader -Title "Account Lockout Policy Audit: Reset Account Lockout Counter After"
    }
    
    # Check if this is a domain environment
    $isDomainMember = (Get-CimInstance -ClassName Win32_ComputerSystem).PartOfDomain
    
    if ($VerboseOutput) {
        Write-StatusMessage -Message "Note: Account lockout policy settings must be applied via Default Domain Policy for domain user accounts" -Type Info
    }
    
    # For both domain and standalone, check the actual setting using secedit
    try {
        # Export current security policy
        $tempFile = [System.IO.Path]::GetTempFileName()
        secedit /export /cfg $tempFile /quiet
        
        # Read the exported policy
        $policyContent = Get-Content $tempFile
        $resetCounterLine = $policyContent | Where-Object { $_ -like "ResetLockoutCount*" }
        
        if ($resetCounterLine) {
            $resetCounterValue = ($resetCounterLine -split "=")[1].Trim()
            $resetCounter = [int]$resetCounterValue
            $source = if ($isDomainMember) { "Domain Policy" } else { "Local Policy" }
        } else {
            if ($VerboseOutput) {
                Write-StatusMessage -Message "Reset account lockout counter setting not found in policy" -Type Warning
            }
            $resetCounter = 0
            $source = if ($isDomainMember) { "Domain Default" } else { "Local Default" }
        }
        
        # Clean up temp file
        Remove-Item $tempFile -ErrorAction SilentlyContinue
    } catch {
        if ($VerboseOutput) {
            Write-StatusMessage -Message "Failed to retrieve account lockout policy" -Type Warning
        }
        $resetCounter = 0
        $source = if ($isDomainMember) { "Domain Default (assumed)" } else { "Local Default (assumed)" }
    }
    
    # Display audit results
    if ($VerboseOutput) {
        Write-Host ""
        Write-Host "AUDIT RESULTS:" -ForegroundColor Cyan
        Write-Host "==============" -ForegroundColor Cyan
        Write-Host "Setting: Reset account lockout counter after" -ForegroundColor White
        Write-Host "Current Value: $resetCounter minute(s)" -ForegroundColor White
        Write-Host "Source: $source" -ForegroundColor White
        Write-Host "Recommended: 15 or more minute(s)" -ForegroundColor White
        Write-Host ""
    }
    
    # Determine compliance status
    # Note: This setting only has meaning when an Account lockout threshold is specified
    if ($resetCounter -ge 15) {
        if ($VerboseOutput) {
            Write-StatusMessage -Message "COMPLIANT: Reset account lockout counter setting meets CIS benchmark" -Type Success
        }
        $complianceStatus = "Compliant"
    } else {
        if ($VerboseOutput) {
            Write-StatusMessage -Message "NON-COMPLIANT: Reset account lockout counter setting does not meet CIS benchmark" -Type Error
        }
        $complianceStatus = "Non-Compliant"
    }
    $auditPass = ($resetCounter -ge 15)
    
    # Generate detailed report
    if ($VerboseOutput) {
        Write-Host ""
        Write-SectionHeader -Title "Detailed Audit Report"
        
        $auditData = @(
            [PSCustomObject]@{
                Setting = "Reset account lockout counter after"
                CurrentValue = if ($resetCounter -eq 0) { "0 (not configured)" } else { "$resetCounter minute(s)" }
                RecommendedValue = "15 or more minute(s)"
                Compliance = $complianceStatus
                Source = $source
                CISReference = "1.2.4 (L1)"
            }
        )
        
        Display-Table -Data $auditData -Title "Account Lockout Policy Audit Results"
    }
    
    # Additional information
    if ($VerboseOutput) {
        Write-Host ""
        Write-Host "ADDITIONAL INFORMATION:" -ForegroundColor Cyan
        Write-Host "======================" -ForegroundColor Cyan
        Write-Host "• This setting determines the length of time before the Account lockout threshold resets to zero" -ForegroundColor Gray
        Write-Host "• Default value: None (only has meaning when an Account lockout threshold is specified)" -ForegroundColor Gray
        Write-Host "• Rationale: Allows users who accidentally lock themselves out to regain access after the timer expires" -ForegroundColor Gray
        Write-Host "• Impact: Failed logon attempt counter resets after the specified time, allowing users to try again" -ForegroundColor Gray
        Write-Host "• Note: This value must be less than or equal to the Account lockout duration setting" -ForegroundColor Yellow
    }
    
    # Remediation guidance
    if ($complianceStatus -eq "Non-Compliant") {
        if ($VerboseOutput) {
            Write-Host ""
            Write-SectionHeader -Title "Remediation Guidance"
            Write-Host "To remediate this setting:" -ForegroundColor Yellow
            Write-Host "1. Open Group Policy Editor (gpedit.msc)" -ForegroundColor White
            Write-Host "2. Navigate to: Computer Configuration\Policies\Windows Settings\Security Settings\Account Policies\Account Lockout Policy" -ForegroundColor White
            Write-Host "3. Set 'Reset account lockout counter after' to 15 or more minute(s)" -ForegroundColor White
            Write-Host "4. Apply the policy and run 'gpupdate /force'" -ForegroundColor White
            Write-Host ""
            Write-Host "Note: For domain environments, configure this setting in the Default Domain Policy" -ForegroundColor Gray
            Write-Host "Note: This setting must be less than or equal to the Account lockout duration setting" -ForegroundColor Gray
        }
    }
    
    if ($VerboseOutput) {
        Write-Host ""
        Write-StatusMessage -Message "Audit completed successfully" -Type Success
    }
    
    $auditPass
} catch {
    if ($VerboseOutput) {
        Wait-OnError -ErrorMessage "Failed to perform account lockout policy audit: $($_.Exception.Message)"
    } else {
        $false
    }
}