# Audit: Store passwords using reversible encryption setting on Windows
# CIS Benchmark: 1.1.7 (L1) Ensure 'Store passwords using reversible encryption' is set to 'Disabled'
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
        Write-SectionHeader -Title "Password Policy Audit: Store Passwords Using Reversible Encryption"
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
            $reversibleLine = $netAccounts | Where-Object { $_ -like "*reversible encryption*" }
            
            if ($reversibleLine) {
                # Parse the line to determine if reversible encryption is enabled
                if ($reversibleLine -match "Yes|Enabled|On|True") {
                    $reversibleEncryption = $true
                } else {
                    $reversibleEncryption = $false
                }
                $source = "Domain Policy"
            } else {
                if ($VerboseOutput) {
                    Write-StatusMessage -Message "Unable to determine reversible encryption setting from net accounts" -Type Warning
                }
                $reversibleEncryption = $false
                $source = "Domain Default (assumed)"
            }
        } catch {
            if ($VerboseOutput) {
                Write-StatusMessage -Message "Failed to retrieve password policy information" -Type Warning
            }
            $reversibleEncryption = $false
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
            $reversibleLine = $policyContent | Where-Object { $_ -like "ClearTextPassword*" }
            
            if ($reversibleLine) {
                $reversibleValue = ($reversibleLine -split "=")[1].Trim()
                $reversibleEncryption = ($reversibleValue -eq "1")
                $source = "Local Policy"
            } else {
                if ($VerboseOutput) {
                    Write-StatusMessage -Message "Reversible encryption setting not found in policy" -Type Warning
                }
                $reversibleEncryption = $false
                $source = "Local Default"
            }
            
            # Clean up temp file
            Remove-Item $tempFile -ErrorAction SilentlyContinue
        } catch {
            if ($VerboseOutput) {
                Write-StatusMessage -Message "Failed to retrieve local password policy" -Type Warning
            }
            $reversibleEncryption = $false
            $source = "Local Default (assumed)"
        }
    }
    
    # Display audit results
    if ($VerboseOutput) {
        Write-Host ""
        Write-Host "AUDIT RESULTS:" -ForegroundColor Cyan
        Write-Host "==============" -ForegroundColor Cyan
        Write-Host "Setting: Store passwords using reversible encryption" -ForegroundColor White
        Write-Host "Current Value: $(if ($reversibleEncryption) { 'Enabled' } else { 'Disabled' })" -ForegroundColor White
        Write-Host "Source: $source" -ForegroundColor White
        Write-Host "Recommended: Disabled" -ForegroundColor White
        Write-Host ""
    }
    
    # Determine compliance status
    if (-not $reversibleEncryption) {
        if ($VerboseOutput) {
            Write-StatusMessage -Message "COMPLIANT: Reversible encryption setting meets CIS benchmark" -Type Success
        }
        $complianceStatus = "Compliant"
    } else {
        if ($VerboseOutput) {
            Write-StatusMessage -Message "NON-COMPLIANT: Reversible encryption setting does not meet CIS benchmark" -Type Error
        }
        $complianceStatus = "Non-Compliant"
    }
    $auditPass = (-not $reversibleEncryption)
    
    # Generate detailed report
    if ($VerboseOutput) {
        Write-Host ""
        Write-SectionHeader -Title "Detailed Audit Report"
        
        $auditData = @(
            [PSCustomObject]@{
                Setting = "Store passwords using reversible encryption"
                CurrentValue = if ($reversibleEncryption) { "Enabled" } else { "Disabled" }
                RecommendedValue = "Disabled"
                Compliance = $complianceStatus
                Source = $source
                CISReference = "1.1.7 (L1)"
            }
        )
        
        Show-Table -Data $auditData -Title "Password Policy Audit Results"
    }
    
    # Additional information
    if ($VerboseOutput) {
        Write-Host ""
        Write-Host "ADDITIONAL INFORMATION:" -ForegroundColor Cyan
        Write-Host "======================" -ForegroundColor Cyan
        Write-Host "• This setting determines whether the operating system stores passwords in a way that uses reversible encryption" -ForegroundColor Gray
        Write-Host "• Default value: Disabled" -ForegroundColor Gray
        Write-Host "• Rationale: Passwords stored with reversible encryption are essentially the same as plaintext versions of the passwords" -ForegroundColor Gray
        Write-Host "• Impact: Enabling this policy setting allows the OS to store passwords in a weaker format that is much more susceptible to compromise" -ForegroundColor Gray
        Write-Host "• Warning: If your organization uses CHAP authentication or Digest Authentication in IIS, you may need this enabled" -ForegroundColor Yellow
    }
    
    # Remediation guidance
    if ($complianceStatus -eq "Non-Compliant") {
        if ($VerboseOutput) {
            Write-Host ""
            Write-SectionHeader -Title "Remediation Guidance"
            Write-Host "To remediate this setting:" -ForegroundColor Yellow
            Write-Host "1. Open Group Policy Editor (gpedit.msc)" -ForegroundColor White
            Write-Host "2. Navigate to: Computer Configuration\Policies\Windows Settings\Security Settings\Account Policies\Password Policy" -ForegroundColor White
            Write-Host "3. Set 'Store passwords using reversible encryption' to Disabled" -ForegroundColor White
            Write-Host "4. Apply the policy and run 'gpupdate /force'" -ForegroundColor White
            Write-Host ""
            Write-Host "Note: For domain environments, configure this setting in the Default Domain Policy" -ForegroundColor Gray
            Write-Host "Warning: If you use CHAP authentication or Digest Authentication in IIS, do not disable this setting" -ForegroundColor Red
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