# Audit: Allow Administrator account lockout setting on Windows
# CIS Benchmark: 1.2.3 (L1) Ensure 'Allow Administrator account lockout' is set to 'Enabled'
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
        Write-SectionHeader -Title "Account Lockout Policy Audit: Allow Administrator Account Lockout"
    }
    
    # Check if this is a domain environment
    $isDomainMember = (Get-CimInstance -ClassName Win32_ComputerSystem).PartOfDomain
    
    if ($VerboseOutput) {
        Write-StatusMessage -Message "Note: This setting applies only to OSes patched as of October 11, 2022 (see MS KB5020282)" -Type Info
    }
    
    # Try to check the setting using various methods
    $adminLockoutEnabled = $false
    $source = "Unknown"
    
    # Method 1: Check via secedit (if available in newer OS versions)
    try {
        # Export current security policy
        $tempFile = [System.IO.Path]::GetTempFileName()
        secedit /export /cfg $tempFile /quiet
        
        # Read the exported policy
        $policyContent = Get-Content $tempFile
        
        # Look for administrator lockout setting (exact name unknown)
        $adminLockoutLine = $policyContent | Where-Object { $_ -like "*AdministratorLockout*" -or $_ -like "*AdminLockout*" }
        
        if ($adminLockoutLine) {
            # Try to parse the value
            if ($adminLockoutLine -match "=1") {
                $adminLockoutEnabled = $true
            } elseif ($adminLockoutLine -match "=0") {
                $adminLockoutEnabled = $false
            }
            $source = if ($isDomainMember) { "Domain Policy" } else { "Local Policy" }
        } else {
            # Setting not found in policy file
            if ($VerboseOutput) {
                Write-StatusMessage -Message "Administrator account lockout setting not found in security policy" -Type Warning
            }
            $adminLockoutEnabled = $false
            $source = if ($isDomainMember) { "Domain Default (assumed)" } else { "Local Default (assumed)" }
        }
        
        # Clean up temp file
        Remove-Item $tempFile -ErrorAction SilentlyContinue
    } catch {
        if ($VerboseOutput) {
            Write-StatusMessage -Message "Failed to retrieve security policy for administrator lockout check" -Type Warning
        }
    }
    
    # Method 2: Check registry (alternative method)
    if ($source -eq "Unknown") {
        try {
            # This registry path might contain the setting
            $registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
            $valueName = "AdministratorLockout"
            
            if (Test-Path $registryPath) {
                $registryValue = Get-ItemProperty -Path $registryPath -Name $valueName -ErrorAction SilentlyContinue
                
                if ($registryValue -ne $null) {
                    $adminLockoutEnabled = ($registryValue.$valueName -eq 1)
                    $source = "Registry Policy"
                } else {
                    $adminLockoutEnabled = $false
                    $source = "Default (Disabled)"
                }
            } else {
                $adminLockoutEnabled = $false
                $source = "Default (Disabled)"
            }
        } catch {
            # Registry check failed
        }
    }
    
    # Display audit results
    if ($VerboseOutput) {
        Write-Host ""
        Write-Host "AUDIT RESULTS:" -ForegroundColor Cyan
        Write-Host "==============" -ForegroundColor Cyan
        Write-Host "Setting: Allow Administrator account lockout" -ForegroundColor White
        Write-Host "Current Value: $(if ($adminLockoutEnabled) { 'Enabled' } else { 'Disabled' })" -ForegroundColor White
        Write-Host "Source: $source" -ForegroundColor White
        Write-Host "Recommended: Enabled" -ForegroundColor White
        Write-Host ""
    }
    
    # Determine compliance status
    if ($adminLockoutEnabled) {
        if ($VerboseOutput) {
            Write-StatusMessage -Message "COMPLIANT: Allow Administrator account lockout setting meets CIS benchmark" -Type Success
        }
        $complianceStatus = "Compliant"
    } else {
        if ($VerboseOutput) {
            Write-StatusMessage -Message "NON-COMPLIANT: Allow Administrator account lockout setting does not meet CIS benchmark" -Type Error
        }
        $complianceStatus = "Non-Compliant"
    }
    $auditPass = $adminLockoutEnabled
    
    # Generate detailed report
    if ($VerboseOutput) {
        Write-Host ""
        Write-SectionHeader -Title "Detailed Audit Report"
        
        $auditData = @(
            [PSCustomObject]@{
                Setting = "Allow Administrator account lockout"
                CurrentValue = if ($adminLockoutEnabled) { "Enabled" } else { "Disabled" }
                RecommendedValue = "Enabled"
                Compliance = $complianceStatus
                Source = $source
                CISReference = "1.2.3 (L1)"
            }
        )
        
        Show-Table -Data $auditData -Title "Account Lockout Policy Audit Results"
    }
    
    # Additional information
    if ($VerboseOutput) {
        Write-Host ""
        Write-Host "ADDITIONAL INFORMATION:" -ForegroundColor Cyan
        Write-Host "======================" -ForegroundColor Cyan
        Write-Host "• This setting determines whether the built-in Administrator account is subject to Account Lockout Policy settings" -ForegroundColor Gray
        Write-Host "• Default value: Disabled (the built-in Administrator account is not subject to the account lockout policy)" -ForegroundColor Gray
        Write-Host "• Rationale: Enabling account lockout policies for the built-in Administrator account reduces likelihood of successful brute force attacks" -ForegroundColor Gray
        Write-Host "• Impact: The built-in Administrator account will be subject to the policies in Section 1.2 Account Lockout Policy" -ForegroundColor Gray
        Write-Host "• Note: This setting applies only to OSes patched as of October 11, 2022 (see MS KB5020282)" -ForegroundColor Yellow
    }
    
    # Remediation guidance
    if ($complianceStatus -eq "Non-Compliant") {
        if ($VerboseOutput) {
            Write-Host ""
            Write-SectionHeader -Title "Remediation Guidance"
            Write-Host "To remediate this setting:" -ForegroundColor Yellow
            Write-Host "1. Open Group Policy Editor (gpedit.msc)" -ForegroundColor White
            Write-Host "2. Navigate to: Computer Configuration\Policies\Windows Settings\Security Settings\Account Policies\Account Lockout Policies" -ForegroundColor White
            Write-Host "3. Set 'Allow Administrator account lockout' to Enabled" -ForegroundColor White
            Write-Host "4. Apply the policy and run 'gpupdate /force'" -ForegroundColor White
            Write-Host ""
            Write-Host "Note: For domain environments, configure this setting in the Default Domain Policy" -ForegroundColor Gray
            Write-Host "Note: This setting requires Windows 10/11 or Server 2022 with October 2022 or later updates" -ForegroundColor Gray
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