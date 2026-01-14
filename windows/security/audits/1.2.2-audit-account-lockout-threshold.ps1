# Audit: Account lockout threshold setting on Windows
# CIS Benchmark: 1.2.2 (L1) Ensure 'Account lockout threshold' is set to '5 or fewer invalid logon attempt(s), but not 0'
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
        Write-SectionHeader -Title "Account Lockout Policy Audit: Account Lockout Threshold"
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
        $lockoutThresholdLine = $policyContent | Where-Object { $_ -like "LockoutBadCount*" }
        
        if ($lockoutThresholdLine) {
            $lockoutThresholdValue = ($lockoutThresholdLine -split "=")[1].Trim()
            $lockoutThreshold = [int]$lockoutThresholdValue
            $source = if ($isDomainMember) { "Domain Policy" } else { "Local Policy" }
        } else {
            if ($VerboseOutput) {
                Write-StatusMessage -Message "Account lockout threshold setting not found in policy" -Type Warning
            }
            $lockoutThreshold = 0
            $source = if ($isDomainMember) { "Domain Default" } else { "Local Default" }
        }
        
        # Clean up temp file
        Remove-Item $tempFile -ErrorAction SilentlyContinue
    } catch {
        if ($VerboseOutput) {
            Write-StatusMessage -Message "Failed to retrieve account lockout policy" -Type Warning
        }
        $lockoutThreshold = 0
        $source = if ($isDomainMember) { "Domain Default (assumed)" } else { "Local Default (assumed)" }
    }
    
    # Display audit results
    if ($VerboseOutput) {
        Write-Host ""
        Write-Host "AUDIT RESULTS:" -ForegroundColor Cyan
        Write-Host "==============" -ForegroundColor Cyan
        Write-Host "Setting: Account lockout threshold" -ForegroundColor White
        Write-Host "Current Value: $lockoutThreshold invalid logon attempt(s)" -ForegroundColor White
        Write-Host "Source: $source" -ForegroundColor White
        Write-Host "Recommended: 5 or fewer invalid logon attempt(s), but not 0" -ForegroundColor White
        Write-Host ""
    }
    
    # Determine compliance status
    # Must be between 1 and 5 inclusive (5 or fewer, but not 0)
    if ($lockoutThreshold -ge 1 -and $lockoutThreshold -le 5) {
        if ($VerboseOutput) {
            Write-StatusMessage -Message "COMPLIANT: Account lockout threshold setting meets CIS benchmark" -Type Success
        }
        $complianceStatus = "Compliant"
    } else {
        if ($VerboseOutput) {
            Write-StatusMessage -Message "NON-COMPLIANT: Account lockout threshold setting does not meet CIS benchmark" -Type Error
        }
        $complianceStatus = "Non-Compliant"
    }
    $auditPass = ($lockoutThreshold -ge 1 -and $lockoutThreshold -le 5)
    
    # Generate detailed report
    if ($VerboseOutput) {
        Write-Host ""
        Write-SectionHeader -Title "Detailed Audit Report"
        
        $auditData = @(
            [PSCustomObject]@{
                Setting = "Account lockout threshold"
                CurrentValue = if ($lockoutThreshold -eq 0) { "0 (disabled)" } else { "$lockoutThreshold invalid logon attempt(s)" }
                RecommendedValue = "5 or fewer invalid logon attempt(s), but not 0"
                Compliance = $complianceStatus
                Source = $source
                CISReference = "1.2.2 (L1)"
            }
        )
        
        Display-Table -Data $auditData -Title "Account Lockout Policy Audit Results"
    }
    
    # Additional information
    if ($VerboseOutput) {
        Write-Host ""
        Write-Host "ADDITIONAL INFORMATION:" -ForegroundColor Cyan
        Write-Host "======================" -ForegroundColor Cyan
        Write-Host "• This setting determines the number of failed logon attempts before the account is locked" -ForegroundColor Gray
        Write-Host "• Default value: 0 failed logon attempts (disabled)" -ForegroundColor Gray
        Write-Host "• Rationale: Reduces the likelihood that an online password brute force attack will be successful" -ForegroundColor Gray
        Write-Host "• Impact: Users will be locked out after the specified number of failed attempts" -ForegroundColor Gray
        Write-Host "• Warning: Setting too low increases risk of accidental lockouts; setting to 0 disables lockout" -ForegroundColor Yellow
    }
    
    # Remediation guidance
    if ($complianceStatus -eq "Non-Compliant") {
        if ($VerboseOutput) {
            Write-Host ""
            Write-SectionHeader -Title "Remediation Guidance"
            Write-Host "To remediate this setting:" -ForegroundColor Yellow
            Write-Host "1. Open Group Policy Editor (gpedit.msc)" -ForegroundColor White
            Write-Host "2. Navigate to: Computer Configuration\Policies\Windows Settings\Security Settings\Account Policies\Account Lockout Policy" -ForegroundColor White
            Write-Host "3. Set 'Account lockout threshold' to 5 or fewer invalid logon attempt(s) (but not 0)" -ForegroundColor White
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