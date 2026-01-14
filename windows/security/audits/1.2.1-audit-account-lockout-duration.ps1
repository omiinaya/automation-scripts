# Audit: Account lockout duration setting on Windows
# CIS Benchmark: 1.2.1 (L1) Ensure 'Account lockout duration' is set to '15 or more minute(s)'
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
        Write-SectionHeader -Title "Account Lockout Policy Audit: Account Lockout Duration"
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
        $lockoutDurationLine = $policyContent | Where-Object { $_ -like "LockoutDuration*" }
        
        if ($lockoutDurationLine) {
            $lockoutDurationValue = ($lockoutDurationLine -split "=")[1].Trim()
            $lockoutDuration = [int]$lockoutDurationValue
            $source = if ($isDomainMember) { "Domain Policy" } else { "Local Policy" }
        } else {
            if ($VerboseOutput) {
                Write-StatusMessage -Message "Account lockout duration setting not found in policy" -Type Warning
            }
            $lockoutDuration = 0
            $source = if ($isDomainMember) { "Domain Default" } else { "Local Default" }
        }
        
        # Clean up temp file
        Remove-Item $tempFile -ErrorAction SilentlyContinue
    } catch {
        if ($VerboseOutput) {
            Write-StatusMessage -Message "Failed to retrieve account lockout policy" -Type Warning
        }
        $lockoutDuration = 0
        $source = if ($isDomainMember) { "Domain Default (assumed)" } else { "Local Default (assumed)" }
    }
    
    # Display audit results
    if ($VerboseOutput) {
        Write-Host ""
        Write-Host "AUDIT RESULTS:" -ForegroundColor Cyan
        Write-Host "==============" -ForegroundColor Cyan
        Write-Host "Setting: Account lockout duration" -ForegroundColor White
        Write-Host "Current Value: $lockoutDuration minute(s)" -ForegroundColor White
        Write-Host "Source: $source" -ForegroundColor White
        Write-Host "Recommended: 15 or more minute(s)" -ForegroundColor White
        Write-Host ""
    }
    
    # Determine compliance status
    # Note: If lockout duration is 0, accounts remain locked until manually unlocked (not compliant)
    if ($lockoutDuration -ge 15) {
        if ($VerboseOutput) {
            Write-StatusMessage -Message "COMPLIANT: Account lockout duration setting meets CIS benchmark" -Type Success
        }
        $complianceStatus = "Compliant"
    } else {
        if ($VerboseOutput) {
            Write-StatusMessage -Message "NON-COMPLIANT: Account lockout duration setting does not meet CIS benchmark" -Type Error
        }
        $complianceStatus = "Non-Compliant"
    }
    $auditPass = ($lockoutDuration -ge 15)
    
    # Generate detailed report
    if ($VerboseOutput) {
        Write-Host ""
        Write-SectionHeader -Title "Detailed Audit Report"
        
        $auditData = @(
            [PSCustomObject]@{
                Setting = "Account lockout duration"
                CurrentValue = if ($lockoutDuration -eq 0) { "Never (until manually unlocked)" } else { "$lockoutDuration minute(s)" }
                RecommendedValue = "15 or more minute(s)"
                Compliance = $complianceStatus
                Source = $source
                CISReference = "1.2.1 (L1)"
            }
        )
        
        Show-Table -Data $auditData -Title "Account Lockout Policy Audit Results"
    }
    
    # Additional information
    if ($VerboseOutput) {
        Write-Host ""
        Write-Host "ADDITIONAL INFORMATION:" -ForegroundColor Cyan
        Write-Host "======================" -ForegroundColor Cyan
        Write-Host "• This setting determines the length of time that must pass before a locked account is unlocked" -ForegroundColor Gray
        Write-Host "• Default value: None (only has meaning when an Account lockout threshold is specified)" -ForegroundColor Gray
        Write-Host "• Rationale: Prevents denial of service attacks while allowing legitimate users to regain access" -ForegroundColor Gray
        Write-Host "• Impact: Users must wait for the specified duration before attempting to log on again" -ForegroundColor Gray
        Write-Host "• Note: Setting to 0 means accounts remain locked until an administrator manually unlocks them" -ForegroundColor Yellow
    }
    
    # Remediation guidance
    if ($complianceStatus -eq "Non-Compliant") {
        if ($VerboseOutput) {
            Write-Host ""
            Write-SectionHeader -Title "Remediation Guidance"
            Write-Host "To remediate this setting:" -ForegroundColor Yellow
            Write-Host "1. Open Group Policy Editor (gpedit.msc)" -ForegroundColor White
            Write-Host "2. Navigate to: Computer Configuration\Policies\Windows Settings\Security Settings\Account Policies\Account Lockout Policy" -ForegroundColor White
            Write-Host "3. Set 'Account lockout duration' to 15 or more minute(s)" -ForegroundColor White
            Write-Host "4. Apply the policy and run 'gpupdate /force'" -ForegroundColor White
            Write-Host ""
            Write-Host "Note: For domain environments, configure this setting in the Default Domain Policy" -ForegroundColor Gray
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