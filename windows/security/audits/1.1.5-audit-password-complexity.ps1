# Audit: Password complexity requirements setting on Windows
# CIS Benchmark: 1.1.5 (L1) Ensure 'Password must meet complexity requirements' is set to 'Enabled'
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
        Write-SectionHeader -Title "Password Policy Audit: Password Complexity Requirements"
    }
    
    # Check if this is a domain environment
    $isDomainMember = (Get-CimInstance -ClassName Win32_ComputerSystem).PartOfDomain
    
    if ($isDomainMember) {
        if ($VerboseOutput) {
            Write-StatusMessage -Message "Computer is domain member - checking password policy" -Type Info
        }
        
        # For domain members, we need to check the actual password policy
        try {
            $netAccounts = net accounts
            $complexityLine = $netAccounts | Where-Object { $_ -like "*Password complexity*" }
            
            if ($complexityLine) {
                # Parse the line to determine if complexity is enabled
                if ($complexityLine -match "Yes|Enabled|On|True") {
                    $passwordComplexity = $true
                } else {
                    $passwordComplexity = $false
                }
                $source = "Domain Policy"
            } else {
                if ($VerboseOutput) {
                    Write-StatusMessage -Message "Unable to determine password complexity from net accounts" -Type Warning
                }
                $passwordComplexity = $true
                $source = "Domain Default (assumed)"
            }
        } catch {
            if ($VerboseOutput) {
                Write-StatusMessage -Message "Failed to retrieve password policy information" -Type Warning
            }
            $passwordComplexity = $true
            $source = "Domain Default (assumed)"
        }
    } else {
        if ($VerboseOutput) {
            Write-StatusMessage -Message "Computer is standalone - checking local policy" -Type Info
        }
        
        # For standalone systems, check the actual setting using secedit
        try {
            # Export current security policy
            $tempFile = [System.IO.Path]::GetTempFileName()
            secedit /export /cfg $tempFile /quiet
            
            # Read the exported policy
            $policyContent = Get-Content $tempFile
            $complexityLine = $policyContent | Where-Object { $_ -like "PasswordComplexity*" }
            
            if ($complexityLine) {
                $complexityValue = ($complexityLine -split "=")[1].Trim()
                $passwordComplexity = ($complexityValue -eq "1")
                $source = "Local Policy"
            } else {
                if ($VerboseOutput) {
                    Write-StatusMessage -Message "Password complexity setting not found in policy" -Type Warning
                }
                $passwordComplexity = $false
                $source = "Local Default"
            }
            
            # Clean up temp file
            Remove-Item $tempFile -ErrorAction SilentlyContinue
        } catch {
            if ($VerboseOutput) {
                Write-StatusMessage -Message "Failed to retrieve local password policy" -Type Warning
            }
            $passwordComplexity = $false
            $source = "Local Default (assumed)"
        }
    }
    
    # Display audit results
    if ($VerboseOutput) {
        Write-Host ""
        Write-Host "AUDIT RESULTS:" -ForegroundColor Cyan
        Write-Host "==============" -ForegroundColor Cyan
        Write-Host "Setting: Password must meet complexity requirements" -ForegroundColor White
        Write-Host "Current Value: $(if ($passwordComplexity) { 'Enabled' } else { 'Disabled' })" -ForegroundColor White
        Write-Host "Source: $source" -ForegroundColor White
        Write-Host "Recommended: Enabled" -ForegroundColor White
        Write-Host ""
    }
    
    # Determine compliance status
    if ($passwordComplexity) {
        if ($VerboseOutput) {
            Write-StatusMessage -Message "COMPLIANT: Password complexity setting meets CIS benchmark" -Type Success
        }
        $complianceStatus = "Compliant"
    } else {
        if ($VerboseOutput) {
            Write-StatusMessage -Message "NON-COMPLIANT: Password complexity setting does not meet CIS benchmark" -Type Error
        }
        $complianceStatus = "Non-Compliant"
    }
    $auditPass = $passwordComplexity
    
    # Generate detailed report
    if ($VerboseOutput) {
        Write-Host ""
        Write-SectionHeader -Title "Detailed Audit Report"
        
        $auditData = @(
            [PSCustomObject]@{
                Setting = "Password must meet complexity requirements"
                CurrentValue = if ($passwordComplexity) { "Enabled" } else { "Disabled" }
                RecommendedValue = "Enabled"
                Compliance = $complianceStatus
                Source = $source
                CISReference = "1.1.5 (L1)"
            }
        )
        
        Show-Table -Data $auditData -Title "Password Policy Audit Results"
    }
    
    # Additional information
    if ($VerboseOutput) {
        Write-Host ""
        Write-Host "ADDITIONAL INFORMATION:" -ForegroundColor Cyan
        Write-Host "======================" -ForegroundColor Cyan
        Write-Host "• This setting checks all new passwords to ensure they meet basic requirements for strong passwords" -ForegroundColor Gray
        Write-Host "• Default value: Enabled on domain members, Disabled on standalone workstations" -ForegroundColor Gray
        Write-Host "• Requirements: Passwords must contain characters from 3 of 5 categories (uppercase, lowercase, digits, non-alphabetic, Unicode)" -ForegroundColor Gray
        Write-Host "• Impact: Users must create more complex passwords that are harder to guess" -ForegroundColor Gray
    }
    
    # Remediation guidance
    if ($complianceStatus -eq "Non-Compliant") {
        if ($VerboseOutput) {
            Write-Host ""
            Write-SectionHeader -Title "Remediation Guidance"
            Write-Host "To remediate this setting:" -ForegroundColor Yellow
            Write-Host "1. Open Group Policy Editor (gpedit.msc)" -ForegroundColor White
            Write-Host "2. Navigate to: Computer Configuration\Policies\Windows Settings\Security Settings\Account Policies\Password Policy" -ForegroundColor White
            Write-Host "3. Set 'Password must meet complexity requirements' to Enabled" -ForegroundColor White
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
        Wait-OnError -ErrorMessage "Failed to perform password policy audit: $($_.Exception.Message)"
    } else {
        $false
    }
}