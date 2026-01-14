# Remediation: Enforce maximum password age setting on Windows
# CIS Benchmark: 1.1.2 (L1) Ensure 'Maximum password age' is set to '365 or fewer days, but not 0'
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
    # Initialize result object
    $scriptResult = $null
    
    if ($VerboseOutput) {
        Write-SectionHeader -Title "Password Policy Remediation: Maximum Password Age"
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
            $maxAgeLine = $netAccounts | Where-Object { $_ -like "*Maximum password age*" }
            
            if ($maxAgeLine) {
                $maximumPasswordAge = [int]($maxAgeLine -replace "[^\d]", "")
                $source = "Domain Policy"
            } else {
                if ($VerboseOutput) {
                    Write-StatusMessage -Message "Unable to determine maximum password age from net accounts" -Type Warning
                }
                $maximumPasswordAge = 42
                $source = "Domain Default (assumed)"
            }
        } catch {
            if ($VerboseOutput) {
                Write-StatusMessage -Message "Failed to retrieve password policy information" -Type Warning
            }
            $maximumPasswordAge = 42
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
            $maxAgeLine = $policyContent | Where-Object { $_ -like "MaximumPasswordAge*" }
            
            if ($maxAgeLine) {
                $maximumPasswordAge = [int]($maxAgeLine -split "=")[1].Trim()
                $source = "Local Policy"
            } else {
                if ($VerboseOutput) {
                    Write-StatusMessage -Message "Maximum password age setting not found in policy" -Type Warning
                }
                $maximumPasswordAge = 0
                $source = "Local Default"
            }
            
            # Clean up temp file
            Remove-Item $tempFile -ErrorAction SilentlyContinue
        } catch {
            if ($VerboseOutput) {
                Write-StatusMessage -Message "Failed to retrieve local password policy" -Type Warning
            }
            $maximumPasswordAge = 0
            $source = "Local Default (assumed)"
        }
    }
    
    # Display current status
    if ($VerboseOutput) {
        Write-Host ""
        Write-Host "CURRENT STATUS:" -ForegroundColor Cyan
        Write-Host "==============" -ForegroundColor Cyan
        Write-Host "Setting: Maximum password age" -ForegroundColor White
        Write-Host "Current Value: $maximumPasswordAge day(s)" -ForegroundColor White
        Write-Host "Source: $source" -ForegroundColor White
        Write-Host "Recommended: 365 or fewer days, but not 0" -ForegroundColor White
        Write-Host ""
    }
    
    # Determine compliance status
    if ($maximumPasswordAge -le 365 -and $maximumPasswordAge -ne 0) {
        if ($VerboseOutput) {
            Write-StatusMessage -Message "COMPLIANT: Maximum password age setting already meets CIS benchmark" -Type Success
            Write-Host ""
            Write-StatusMessage -Message "No remediation required" -Type Success
        }
        
        $scriptResult = [PSCustomObject]@{
            Status = "Compliant"
            Message = "Maximum password age setting already meets CIS benchmark"
            PreviousValue = $maximumPasswordAge
            NewValue = $maximumPasswordAge
            IsCompliant = $true
            RequiresManualAction = $false
            Source = $source
        }
        
        if ($VerboseOutput) {
            Display-Pause -Message "Press Enter to exit..."
        }
    } else {
        if ($VerboseOutput) {
            Write-StatusMessage -Message "NON-COMPLIANT: Maximum password age setting does not meet CIS benchmark" -Type Error
            Write-Host ""
            
            # Show remediation warning
            Write-Host "REMEDIATION REQUIRED:" -ForegroundColor Yellow
            Write-Host "====================" -ForegroundColor Yellow
            Write-Host "The maximum password age setting needs to be changed from $maximumPasswordAge to 365 (or fewer days, but not 0)." -ForegroundColor White
            Write-Host ""
        }
        
        # Get user confirmation before proceeding (only in verbose mode)
        if ($VerboseOutput) {
            if (-not (Display-Confirmation -Message "Do you want to proceed with remediation?" -DefaultChoice "No")) {
                Write-StatusMessage -Message "Remediation cancelled by user" -Type Warning
                
                $scriptResult = [PSCustomObject]@{
                    Status = "Cancelled"
                    Message = "User cancelled remediation"
                    PreviousValue = $maximumPasswordAge
                    NewValue = $maximumPasswordAge
                    IsCompliant = $false
                    RequiresManualAction = $false
                    Source = $source
                }
                
                Display-Pause -Message "Press Enter to exit..."
                
                # Return appropriate result based on verbose mode
                if ($VerboseOutput) {
                    $scriptResult
                } else {
                    $scriptResult.IsCompliant
                }
                return
            }
        } else {
            # In non-verbose mode, automatically proceed with remediation
        }
        
        if ($VerboseOutput) {
            Write-Host ""
            Write-SectionHeader -Title "Starting Remediation"
        }
        
        # Perform remediation based on environment
        if ($isDomainMember) {
            if ($VerboseOutput) {
                Write-StatusMessage -Message "Domain environment detected - remediation requires domain policy changes" -Type Warning
                Write-Host ""
                Write-Host "DOMAIN REMEDIATION INSTRUCTIONS:" -ForegroundColor Yellow
                Write-Host "================================" -ForegroundColor Yellow
                Write-Host "1. Open Group Policy Management Console (gpmc.msc)" -ForegroundColor White
                Write-Host "2. Navigate to: Default Domain Policy" -ForegroundColor White
                Write-Host "3. Edit: Computer Configuration\Policies\Windows Settings\Security Settings\Account Policies\Password Policy" -ForegroundColor White
                Write-Host "4. Set 'Maximum password age' to 365 or fewer days (but not 0)" -ForegroundColor White
                Write-Host "5. Apply the policy and run 'gpupdate /force' on all domain computers" -ForegroundColor White
                Write-Host ""
                Write-Host "Note: Domain policy changes require domain administrator privileges" -ForegroundColor Gray
            }
            
            $scriptResult = [PSCustomObject]@{
                Status = "ManualActionRequired"
                Message = "Domain environment requires manual policy changes"
                PreviousValue = $maximumPasswordAge
                NewValue = 365
                IsCompliant = $false
                RequiresManualAction = $true
                Source = $source
            }
        } else {
            if ($VerboseOutput) {
                Write-StatusMessage -Message "Standalone environment - applying local policy remediation" -Type Info
            }
            
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
MaximumPasswordAge=365
"@
                
                # Write the template
                $templateContent | Out-File -FilePath $templateFile -Encoding Unicode
                
                # Apply the security policy
                if ($VerboseOutput) {
                    Write-StatusMessage -Message "Applying security policy template..." -Type Info
                }
                secedit /configure /db secedit.sdb /cfg $templateFile /quiet
                
                if ($LASTEXITCODE -eq 0) {
                    if ($VerboseOutput) {
                        Write-StatusMessage -Message "Security policy applied successfully" -Type Success
                        
                        # Verify the change
                        Write-StatusMessage -Message "Verifying remediation..." -Type Info
                    }
                    Start-Sleep -Seconds 2
                    
                    # Re-check the setting
                    $verifyTempFile = [System.IO.Path]::GetTempFileName()
                    secedit /export /cfg $verifyTempFile /quiet
                    $verifyContent = Get-Content $verifyTempFile
                    $verifyLine = $verifyContent | Where-Object { $_ -like "MaximumPasswordAge*" }
                    
                    if ($verifyLine) {
                        $newValue = [int]($verifyLine -split "=")[1].Trim()
                        if ($newValue -le 365 -and $newValue -ne 0) {
                            if ($VerboseOutput) {
                                Write-StatusMessage -Message "Remediation verified: Maximum password age now set to $newValue" -Type Success
                            }
                            $scriptResult = [PSCustomObject]@{
                                Status = "Remediated"
                                Message = "Maximum password age setting successfully updated to $newValue"
                                PreviousValue = $maximumPasswordAge
                                NewValue = $newValue
                                IsCompliant = $true
                                RequiresManualAction = $false
                                Source = $source
                            }
                        } else {
                            if ($VerboseOutput) {
                                Write-StatusMessage -Message "Warning: Setting may not have applied correctly" -Type Warning
                            }
                            $scriptResult = [PSCustomObject]@{
                                Status = "PartiallyRemediated"
                                Message = "Maximum password age setting may not have been applied correctly (value: $newValue)"
                                PreviousValue = $maximumPasswordAge
                                NewValue = $newValue
                                IsCompliant = $false
                                RequiresManualAction = $false
                                Source = $source
                            }
                        }
                    } else {
                        # No verification line found
                        $scriptResult = [PSCustomObject]@{
                            Status = "PartiallyRemediated"
                            Message = "Unable to verify maximum password age setting after remediation"
                            PreviousValue = $maximumPasswordAge
                            NewValue = 365
                            IsCompliant = $false
                            RequiresManualAction = $false
                            Source = $source
                        }
                    }
                    
                    # Clean up temp files
                    Remove-Item $verifyTempFile -ErrorAction SilentlyContinue
                    Remove-Item $templateFile -ErrorAction SilentlyContinue
                    
                } else {
                    if ($VerboseOutput) {
                        Write-StatusMessage -Message "Failed to apply security policy (exit code: $LASTEXITCODE)" -Type Error
                        Write-Host ""
                        Write-Host "ALTERNATIVE REMEDIATION:" -ForegroundColor Yellow
                        Write-Host "========================" -ForegroundColor Yellow
                        Write-Host "1. Open Local Security Policy (secpol.msc)" -ForegroundColor White
                        Write-Host "2. Navigate to: Account Policies\Password Policy" -ForegroundColor White
                        Write-Host "3. Set 'Maximum password age' to 365 or fewer days (but not 0)" -ForegroundColor White
                        Write-Host "4. Click Apply and OK" -ForegroundColor White
                    }
                    
                    $scriptResult = [PSCustomObject]@{
                        Status = "Failed"
                        Message = "Failed to apply security policy (exit code: $LASTEXITCODE)"
                        PreviousValue = $maximumPasswordAge
                        NewValue = 365
                        IsCompliant = $false
                        RequiresManualAction = $true
                        Source = $source
                    }
                }
                
            } catch {
                if ($VerboseOutput) {
                    Write-StatusMessage -Message "Failed to remediate local policy: $($_.Exception.Message)" -Type Error
                    Write-Host ""
                    Write-Host "MANUAL REMEDIATION REQUIRED:" -ForegroundColor Red
                    Write-Host "===========================" -ForegroundColor Red
                    Write-Host "Please manually set the maximum password age policy:" -ForegroundColor White
                    Write-Host "1. Open Local Security Policy (secpol.msc)" -ForegroundColor White
                    Write-Host "2. Navigate to: Account Policies\Password Policy" -ForegroundColor White
                    Write-Host "3. Set 'Maximum password age' to 365 or fewer days (but not 0)" -ForegroundColor White
                    Write-Host "4. Click Apply and OK" -ForegroundColor White
                }
                
                $scriptResult = [PSCustomObject]@{
                    Status = "Error"
                    Message = "Failed to remediate local policy: $($_.Exception.Message)"
                    PreviousValue = $maximumPasswordAge
                    NewValue = 365
                    IsCompliant = $false
                    RequiresManualAction = $true
                    Source = $source
                }
            }
        }
        
        if ($VerboseOutput) {
            Write-Host ""
            Write-SectionHeader -Title "Remediation Summary"
            
            $remediationData = @(
                [PSCustomObject]@{
                    Setting = "Maximum password age"
                    OriginalValue = "$maximumPasswordAge day(s)"
                    NewValue = "365 day(s)"
                    Status = if ($isDomainMember) { "Manual Domain Action Required" } else { "Applied" }
                    CISReference = "1.1.2 (L1)"
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
                Write-Host "• Users will need to change passwords within the new maximum age" -ForegroundColor White
                Write-Host "• Verify the setting by running the audit script again" -ForegroundColor White
            }
        }
    }
    # Output result
    if ($scriptResult -eq $null) {
        $scriptResult = [PSCustomObject]@{
            Status = "Unknown"
            Message = "Script completed without setting a result"
            PreviousValue = $null
            NewValue = $null
            IsCompliant = $false
            RequiresManualAction = $false
            Source = "Unknown"
        }
    }
    
    # Return appropriate result based on verbose mode
    if ($VerboseOutput) {
        $scriptResult
    } else {
        $scriptResult.IsCompliant
    }
    
    if ($VerboseOutput) {
        Write-Host ""
        Display-Pause -Message "Press Enter to exit..."
    }
    
    
} catch {
    if ($VerboseOutput) {
        Wait-OnError -ErrorMessage "Failed to perform password policy remediation: $($_.Exception.Message)"
    } else {
        $false
    }
}