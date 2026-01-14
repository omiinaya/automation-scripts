# Audit: Minimum password length setting on Windows
# CIS Benchmark: 1.1.4 (L1) Ensure 'Minimum password length' is set to '14 or more character(s)'
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
        Write-SectionHeader -Title "Password Policy Audit: Minimum Password Length"
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
            $minLengthLine = $netAccounts | Where-Object { $_ -like "*Minimum password length*" }
            
            if ($minLengthLine) {
                $minimumPasswordLength = [int]($minLengthLine -replace "[^\d]", "")
                $source = "Domain Policy"
            } else {
                if ($VerboseOutput) {
                    Write-StatusMessage -Message "Unable to determine minimum password length from net accounts" -Type Warning
                }
                $minimumPasswordLength = 7
                $source = "Domain Default (assumed)"
            }
        } catch {
            if ($VerboseOutput) {
                Write-StatusMessage -Message "Failed to retrieve password policy information" -Type Warning
            }
            $minimumPasswordLength = 7
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
            $minLengthLine = $policyContent | Where-Object { $_ -like "MinimumPasswordLength*" }
            
            if ($minLengthLine) {
                $minimumPasswordLength = [int]($minLengthLine -split "=")[1].Trim()
                $source = "Local Policy"
            } else {
                if ($VerboseOutput) {
                    Write-StatusMessage -Message "Minimum password length setting not found in policy" -Type Warning
                }
                $minimumPasswordLength = 0
                $source = "Local Default"
            }
            
            # Clean up temp file
            Remove-Item $tempFile -ErrorAction SilentlyContinue
        } catch {
            if ($VerboseOutput) {
                Write-StatusMessage -Message "Failed to retrieve local password policy" -Type Warning
            }
            $minimumPasswordLength = 0
            $source = "Local Default (assumed)"
        }
    }
    
    # Display audit results
    if ($VerboseOutput) {
        Write-Host ""
        Write-Host "AUDIT RESULTS:" -ForegroundColor Cyan
        Write-Host "==============" -ForegroundColor Cyan
        Write-Host "Setting: Minimum password length" -ForegroundColor White
        Write-Host "Current Value: $minimumPasswordLength character(s)" -ForegroundColor White
        Write-Host "Source: $source" -ForegroundColor White
        Write-Host "Recommended: 14 or more character(s)" -ForegroundColor White
        Write-Host ""
    }
    
    # Determine compliance status
    if ($minimumPasswordLength -ge 14) {
        if ($VerboseOutput) {
            Write-StatusMessage -Message "COMPLIANT: Minimum password length setting meets CIS benchmark" -Type Success
        }
        $complianceStatus = "Compliant"
    } else {
        if ($VerboseOutput) {
            Write-StatusMessage -Message "NON-COMPLIANT: Minimum password length setting does not meet CIS benchmark" -Type Error
        }
        $complianceStatus = "Non-Compliant"
    }
    $auditPass = ($minimumPasswordLength -ge 14)
    
    # Generate detailed report
    if ($VerboseOutput) {
        Write-Host ""
        Write-SectionHeader -Title "Detailed Audit Report"
        
        $auditData = @(
            [PSCustomObject]@{
                Setting = "Minimum password length"
                CurrentValue = "$minimumPasswordLength character(s)"
                RecommendedValue = "14 or more character(s)"
                Compliance = $complianceStatus
                Source = $source
                CISReference = "1.1.4 (L1)"
            }
        )
        
        Show-Table -Data $auditData -Title "Password Policy Audit Results"
    }
    
    # Additional information
    if ($VerboseOutput) {
        Write-Host ""
        Write-Host "ADDITIONAL INFORMATION:" -ForegroundColor Cyan
        Write-Host "======================" -ForegroundColor Cyan
        Write-Host "• This setting determines the least number of characters that make up a password" -ForegroundColor Gray
        Write-Host "• Default value: 7 characters on domain members, 0 characters on standalone servers" -ForegroundColor Gray
        Write-Host "• Rationale: Longer passwords are harder to crack through brute force attacks" -ForegroundColor Gray
        Write-Host "• Impact: Users must create passwords with at least the specified length" -ForegroundColor Gray
    }
    
    # Remediation guidance
    if ($complianceStatus -eq "Non-Compliant") {
        if ($VerboseOutput) {
            Write-Host ""
            Write-SectionHeader -Title "Remediation Guidance"
            Write-Host "To remediate this setting:" -ForegroundColor Yellow
            Write-Host "1. Open Group Policy Editor (gpedit.msc)" -ForegroundColor White
            Write-Host "2. Navigate to: Computer Configuration\Policies\Windows Settings\Security Settings\Account Policies\Password Policy" -ForegroundColor White
            Write-Host "3. Set 'Minimum password length' to 14 or more character(s)" -ForegroundColor White
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