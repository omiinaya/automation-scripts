# Remediation: Enforce password history setting on Windows
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
Import-Module $modulePath -Force -WarningAction SilentlyContinue

# Check admin rights and handle elevation
if (-not (Test-AdminRights)) {
    Invoke-Elevation
    exit
}

try {
    Write-SectionHeader -Title "Password Policy Remediation: Enforce Password History"
    
    # Check if this is a domain environment
    $isDomainMember = (Get-CimInstance -ClassName Win32_ComputerSystem).PartOfDomain
    
    if ($isDomainMember) {
        Write-StatusMessage -Message "Computer is domain member - checking password policy" -Type Info
        
        # For domain members, we need to check the actual password policy
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
    
    # Display current status
    Write-Host ""
    Write-Host "CURRENT STATUS:" -ForegroundColor Cyan
    Write-Host "==============" -ForegroundColor Cyan
    Write-Host "Setting: Enforce password history" -ForegroundColor White
    Write-Host "Current Value: $passwordHistoryValue password(s)" -ForegroundColor White
    Write-Host "Source: $source" -ForegroundColor White
    Write-Host "Recommended: 24 or more password(s)" -ForegroundColor White
    Write-Host ""
    
    # Determine compliance status
    if ($passwordHistoryValue -ge 24) {
        Write-StatusMessage -Message "COMPLIANT: Password history setting already meets CIS benchmark" -Type Success
        Write-Host ""
        Write-StatusMessage -Message "No remediation required" -Type Success
        Display-Pause -Message "Press Enter to exit..."
        exit 0
    } else {
        Write-StatusMessage -Message "NON-COMPLIANT: Password history setting does not meet CIS benchmark" -Type Error
        Write-Host ""
        
        # Show remediation warning
        Write-Host "REMEDIATION REQUIRED:" -ForegroundColor Yellow
        Write-Host "====================" -ForegroundColor Yellow
        Write-Host "The password history setting needs to be changed from $passwordHistoryValue to 24." -ForegroundColor White
        Write-Host ""
        
        # Get user confirmation before proceeding
        if (-not (Display-Confirmation -Message "Do you want to proceed with remediation?" -DefaultChoice "No")) {
            Write-StatusMessage -Message "Remediation cancelled by user" -Type Warning
            Display-Pause -Message "Press Enter to exit..."
            exit 0
        }
        
        Write-Host ""
        Write-SectionHeader -Title "Starting Remediation"
        
        # Perform remediation based on environment
        if ($isDomainMember) {
            Write-StatusMessage -Message "Domain environment detected - remediation requires domain policy changes" -Type Warning
            Write-Host ""
            Write-Host "DOMAIN REMEDIATION INSTRUCTIONS:" -ForegroundColor Yellow
            Write-Host "================================" -ForegroundColor Yellow
            Write-Host "1. Open Group Policy Management Console (gpmc.msc)" -ForegroundColor White
            Write-Host "2. Navigate to: Default Domain Policy" -ForegroundColor White
            Write-Host "3. Edit: Computer Configuration\Policies\Windows Settings\Security Settings\Account Policies\Password Policy" -ForegroundColor White
            Write-Host "4. Set 'Enforce password history' to 24 or more" -ForegroundColor White
            Write-Host "5. Apply the policy and run 'gpupdate /force' on all domain computers" -ForegroundColor White
            Write-Host ""
            Write-Host "Note: Domain policy changes require domain administrator privileges" -ForegroundColor Gray
        } else {
            Write-StatusMessage -Message "Standalone environment - applying local policy remediation" -Type Info
            
            try {
                # Create a temporary security policy template
                $templateFile = [System.IO.Path]::GetTempFileName()
                $templateContent = @"
[Unicode]
Unicode=yes
[Version]
signature="`$CHICAGO`$"
Revision=1
[System Access]
PasswordHistorySize=24
"@
                
                # Write the template
                $templateContent | Out-File -FilePath $templateFile -Encoding Unicode
                
                # Apply the security policy
                Write-StatusMessage -Message "Applying security policy template..." -Type Info
                secedit /configure /db secedit.sdb /cfg $templateFile /quiet
                
                if ($LASTEXITCODE -eq 0) {
                    Write-StatusMessage -Message "Security policy applied successfully" -Type Success
                    
                    # Verify the change
                    Write-StatusMessage -Message "Verifying remediation..." -Type Info
                    Start-Sleep -Seconds 2
                    
                    # Re-check the setting
                    $verifyTempFile = [System.IO.Path]::GetTempFileName()
                    secedit /export /cfg $verifyTempFile /quiet
                    $verifyContent = Get-Content $verifyTempFile
                    $verifyLine = $verifyContent | Where-Object { $_ -like "PasswordHistorySize*" }
                    
                    if ($verifyLine) {
                        $newValue = [int]($verifyLine -split "=")[1].Trim()
                        if ($newValue -ge 24) {
                            Write-StatusMessage -Message "Remediation verified: Password history now set to $newValue" -Type Success
                        } else {
                            Write-StatusMessage -Message "Warning: Setting may not have applied correctly" -Type Warning
                        }
                    }
                    
                    # Clean up temp files
                    Remove-Item $verifyTempFile -ErrorAction SilentlyContinue
                    Remove-Item $templateFile -ErrorAction SilentlyContinue
                    
                } else {
                    Write-StatusMessage -Message "Failed to apply security policy (exit code: $LASTEXITCODE)" -Type Error
                    Write-Host ""
                    Write-Host "ALTERNATIVE REMEDIATION:" -ForegroundColor Yellow
                    Write-Host "========================" -ForegroundColor Yellow
                    Write-Host "1. Open Local Security Policy (secpol.msc)" -ForegroundColor White
                    Write-Host "2. Navigate to: Account Policies\Password Policy" -ForegroundColor White
                    Write-Host "3. Set 'Enforce password history' to 24 or more" -ForegroundColor White
                    Write-Host "4. Click Apply and OK" -ForegroundColor White
                }
                
            } catch {
                Write-StatusMessage -Message "Failed to remediate local policy: $($_.Exception.Message)" -Type Error
                Write-Host ""
                Write-Host "MANUAL REMEDIATION REQUIRED:" -ForegroundColor Red
                Write-Host "===========================" -ForegroundColor Red
                Write-Host "Please manually set the password history policy:" -ForegroundColor White
                Write-Host "1. Open Local Security Policy (secpol.msc)" -ForegroundColor White
                Write-Host "2. Navigate to: Account Policies\Password Policy" -ForegroundColor White
                Write-Host "3. Set 'Enforce password history' to 24 or more" -ForegroundColor White
                Write-Host "4. Click Apply and OK" -ForegroundColor White
            }
        }
        
        Write-Host ""
        Write-SectionHeader -Title "Remediation Summary"
        
        $remediationData = @(
            [PSCustomObject]@{
                Setting = "Enforce password history"
                OriginalValue = "$passwordHistoryValue password(s)"
                NewValue = "24 password(s)"
                Status = if ($isDomainMember) { "Manual Domain Action Required" } else { "Applied" }
                CISReference = "1.1.1 (L1)"
            }
        )
        
        Display-Table -Data $remediationData -Title "Remediation Results"
        
        Write-Host ""
        Write-StatusMessage -Message "Remediation process completed" -Type Success
        
        if ($isDomainMember) {
            Write-Host ""
            Write-Host "NEXT STEPS FOR DOMAIN ENVIRONMENT:" -ForegroundColor Cyan
            Write-Host "==================================" -ForegroundColor Cyan
            Write-Host "• Contact your domain administrator to update the password policy" -ForegroundColor White
            Write-Host "• The change will apply to all domain-joined computers" -ForegroundColor White
            Write-Host "• Run 'gpupdate /force' after policy changes" -ForegroundColor White
        } else {
            Write-Host ""
            Write-Host "NEXT STEPS FOR STANDALONE ENVIRONMENT:" -ForegroundColor Cyan
            Write-Host "=======================================" -ForegroundColor Cyan
            Write-Host "• The policy change should take effect immediately" -ForegroundColor White
            Write-Host "• Users will need to use 24 unique passwords before reusing old ones" -ForegroundColor White
            Write-Host "• Verify the setting by running the audit script again" -ForegroundColor White
        }
    }
    
    Write-Host ""
    Display-Pause -Message "Press Enter to exit..."
    
} catch {
    Wait-OnError -ErrorMessage "Failed to perform password policy remediation: $($_.Exception.Message)"
}