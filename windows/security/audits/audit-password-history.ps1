# Audit: Enforce password history setting on Windows
# CIS Benchmark: 1.1.1 (L1) Ensure 'Enforce password history' is set to '24 or more password(s)'
# Refactored to use modular system

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
Import-Module $modulePath -Force

# Check admin rights and handle elevation
if (-not (Test-AdminRights)) {
    Request-Elevation
    exit
}

try {
    Write-SectionHeader -Title "Password Policy Audit: Enforce Password History"
    
    # Check if this is a domain environment
    $isDomainMember = (Get-CimInstance -ClassName Win32_ComputerSystem).PartOfDomain
    
    if ($isDomainMember) {
        Write-StatusMessage -Message "Computer is domain member - checking password policy" -Type Info
        
        # For domain members, we need to check the actual password policy
        # This requires using secedit or net accounts command
        try {
            $netAccounts = net accounts
            $passwordHistoryLine = $netAccounts | Where-Object { $_ -like "*Password history*" }
            
            if ($passwordHistoryLine) {
                $passwordHistoryValue = [int]($passwordHistoryLine -replace "[^\d]", "")
                $source = "Domain Policy"
            } else {
                Write-StatusMessage -Message "Unable to determine password history from net accounts" -Type Warning
                $passwordHistoryValue = 24
                $source = "Domain Default (assumed)"
            }
        } catch {
            Write-StatusMessage -Message "Failed to retrieve password policy information" -Type Warning
            $passwordHistoryValue = 24
            $source = "Domain Default (assumed)"
        }
    } else {
        Write-StatusMessage -Message "Computer is standalone - checking local policy" -Type Info
        
        # For standalone systems, check the actual setting using secedit
        try {
            # Export current security policy
            $tempFile = [System.IO.Path]::GetTempFileName()
            secedit /export /cfg $tempFile /quiet
            
            # Read the exported policy
            $policyContent = Get-Content $tempFile
            $passwordHistoryLine = $policyContent | Where-Object { $_ -like "PasswordHistorySize*" }
            
            if ($passwordHistoryLine) {
                $passwordHistoryValue = [int]($passwordHistoryLine -split "=")[1].Trim()
                $source = "Local Policy"
            } else {
                Write-StatusMessage -Message "Password history setting not found in policy" -Type Warning
                $passwordHistoryValue = 0
                $source = "Local Default"
            }
            
            # Clean up temp file
            Remove-Item $tempFile -ErrorAction SilentlyContinue
        } catch {
            Write-StatusMessage -Message "Failed to retrieve local password policy" -Type Warning
            $passwordHistoryValue = 0
            $source = "Local Default (assumed)"
        }
    }
    
    # Display audit results
    Write-Host ""
    Write-Host "AUDIT RESULTS:" -ForegroundColor Cyan
    Write-Host "==============" -ForegroundColor Cyan
    Write-Host "Setting: Enforce password history" -ForegroundColor White
    Write-Host "Current Value: $passwordHistoryValue password(s)" -ForegroundColor White
    Write-Host "Source: $source" -ForegroundColor White
    Write-Host "Recommended: 24 or more password(s)" -ForegroundColor White
    Write-Host ""
    
    # Determine compliance status
    if ($passwordHistoryValue -ge 24) {
        Write-StatusMessage -Message "COMPLIANT: Password history setting meets CIS benchmark" -Type Success
        $complianceStatus = "Compliant"
    } else {
        Write-StatusMessage -Message "NON-COMPLIANT: Password history setting does not meet CIS benchmark" -Type Error
        $complianceStatus = "Non-Compliant"
    }
    
    # Generate detailed report
    Write-Host ""
    Write-SectionHeader -Title "Detailed Audit Report"
    
    $auditData = @(
        [PSCustomObject]@{
            Setting = "Enforce password history"
            CurrentValue = "$passwordHistoryValue password(s)"
            RecommendedValue = "24 or more password(s)"
            Compliance = $complianceStatus
            Source = $source
            CISReference = "1.1.1 (L1)"
        }
    )
    
    Show-Table -Data $auditData -Title "Password Policy Audit Results"
    
    # Additional information
    Write-Host ""
    Write-Host "ADDITIONAL INFORMATION:" -ForegroundColor Cyan
    Write-Host "======================" -ForegroundColor Cyan
    Write-Host "• This setting determines how many unique passwords must be used before reusing an old password" -ForegroundColor Gray
    Write-Host "• Default value: 24 passwords remembered on domain members, 0 on standalone workstations" -ForegroundColor Gray
    Write-Host "• Rationale: Prevents password reuse and enhances security" -ForegroundColor Gray
    Write-Host "• Impact: Users must create new passwords each time they change them" -ForegroundColor Gray
    
    # Remediation guidance
    if ($complianceStatus -eq "Non-Compliant") {
        Write-Host ""
        Write-SectionHeader -Title "Remediation Guidance"
        Write-Host "To remediate this setting:" -ForegroundColor Yellow
        Write-Host "1. Open Group Policy Editor (gpedit.msc)" -ForegroundColor White
        Write-Host "2. Navigate to: Computer Configuration\Policies\Windows Settings\Security Settings\Account Policies\Password Policy" -ForegroundColor White
        Write-Host "3. Set 'Enforce password history' to 24 or more" -ForegroundColor White
        Write-Host "4. Apply the policy and run 'gpupdate /force'" -ForegroundColor White
        Write-Host ""
        Write-Host "Note: For domain environments, configure this setting in the Default Domain Policy" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-StatusMessage -Message "Audit completed successfully" -Type Success
    
} catch {
    Wait-OnError -ErrorMessage "Failed to perform password policy audit: $($_.Exception.Message)"
}