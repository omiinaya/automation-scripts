<#
.SYNOPSIS
    CIS Remediation Script for 2.3.2.1 - Ensure 'Audit: Force audit policy subcategory settings (Windows Vista or later) to override audit policy category settings' is set to 'Enabled'
.DESCRIPTION
    This script remediates the Security Options setting that forces audit policy subcategory settings to override audit policy category settings.
    This allows administrators to enable the more precise auditing capabilities present in Windows Vista and later versions.
.NOTES
    File Name      : 2.3.2.1-remediate-force-audit-policy-subcategory-override.ps1
    CIS ID         : 2.3.2.1
    CIS Title      : Ensure 'Audit: Force audit policy subcategory settings (Windows Vista or later) to override audit policy category settings' is set to 'Enabled'
    CIS Profile     : L1
    Author         : System Administrator
    Prerequisite   : PowerShell 5.1 or later
#>

# Import required modules
Import-Module "$PSScriptRoot\..\..\..\modules\CISRemediation.psm1" -Force -WarningAction SilentlyContinue
Import-Module "$PSScriptRoot\..\..\..\modules\RegistryUtils.psm1" -Force -WarningAction SilentlyContinue

# Function to remediate audit policy subcategory override setting
function Remediate-ForceAuditPolicySubcategoryOverride {
    <#
    .SYNOPSIS
        Remediates the audit policy subcategory override setting
    .DESCRIPTION
        Configures the Security Options setting to force audit policy subcategory settings 
        to override audit policy category settings
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        Write-Host ""
        Write-Host "=== CIS Remediation: 2.3.2.1 - Force Audit Policy Subcategory Override ===" -ForegroundColor Cyan
        Write-Host "Configuring Security Options setting..." -ForegroundColor White
        
        # Registry path for Security Options setting
        $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
        $valueName = "SCENoApplyLegacyAuditPolicy"
        $recommendedValue = 1  # Enabled
        
        # Check current value first
        if (Test-RegistryKey -KeyPath $registryPath) {
            $currentValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            Write-Host "Current value: $currentValue" -ForegroundColor White
        } else {
            Write-Host "Registry key does not exist, creating..." -ForegroundColor Yellow
            # Create registry key if it doesn't exist
            New-Item -Path $registryPath -Force | Out-Null
            $currentValue = "Not Set"
        }
        
        Write-Host "Setting value to: $recommendedValue" -ForegroundColor White
        
        # Set registry value
        Set-RegistryValue -KeyPath $registryPath -ValueName $valueName -ValueData $recommendedValue -ValueType "DWord"
        
        # Verify the change
        Start-Sleep -Seconds 1
        $newValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
        
        if ($newValue -eq $recommendedValue) {
            Write-Host "Setting successfully configured" -ForegroundColor Green
            
            # Create remediation result
            $result = New-CISRemediationResult -CIS_ID "2.3.2.1" -Title "Ensure 'Audit: Force audit policy subcategory settings (Windows Vista or later) to override audit policy category settings' is set to 'Enabled'" -PreviousValue $currentValue -NewValue $recommendedValue -Status "Remediated" -Message "Security Options setting successfully configured to force audit policy subcategory override" -IsCompliant $true -RequiresManualAction $false -Source "Registry"
            
            return $result
        } else {
            Write-Host "Failed to verify setting configuration" -ForegroundColor Red
            
            $result = New-CISRemediationResult -CIS_ID "2.3.2.1" -Title "Ensure 'Audit: Force audit policy subcategory settings (Windows Vista or later) to override audit policy category settings' is set to 'Enabled'" -PreviousValue $currentValue -NewValue $newValue -Status "PartiallyRemediated" -Message "Setting may not have been applied correctly" -IsCompliant $false -RequiresManualAction $false -Source "Registry"
            
            return $result
        }
    }
    catch {
        Write-Error "Failed to remediate audit policy subcategory override setting: $_"
        
        # Return error result
        return New-CISRemediationResult -CIS_ID "2.3.2.1" -Title "Ensure 'Audit: Force audit policy subcategory settings (Windows Vista or later) to override audit policy category settings' is set to 'Enabled'" -PreviousValue "Unknown" -NewValue "Unknown" -Status "Error" -Message "Remediation failed: $_" -IsCompliant $false -RequiresManualAction $true -ErrorMessage $_
    }
}

# Function to apply Group Policy setting
function Apply-AuditPolicySubcategoryGroupPolicy {
    <#
    .SYNOPSIS
        Applies Group Policy setting for audit policy subcategory override
    .DESCRIPTION
        Configures Group Policy to force audit policy subcategory settings to override audit policy category settings
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        # Group Policy registry path
        $registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Audit"
        $valueName = "SCENoApplyLegacyAuditPolicy"
        $recommendedValue = 1  # Enabled
        
        Write-Host "Configuring Group Policy setting..." -ForegroundColor White
        
        # Check if Group Policy registry path exists
        if (-not (Test-RegistryKey -KeyPath $registryPath)) {
            Write-Host "Creating Group Policy registry path..." -ForegroundColor Yellow
            New-Item -Path $registryPath -Force | Out-Null
        }
        
        # Set Group Policy value
        Set-RegistryValue -KeyPath $registryPath -ValueName $valueName -ValueData $recommendedValue -ValueType "DWord"
        
        Write-Host "Group Policy setting configured" -ForegroundColor Green
        
        return [PSCustomObject]@{
            Status = "Success"
            Message = "Group Policy setting applied successfully"
        }
    }
    catch {
        Write-Warning "Failed to apply Group Policy setting: $_"
        return [PSCustomObject]@{
            Status = "Failed"
            Message = "Failed to apply Group Policy setting: $_"
        }
    }
}

# Main remediation execution
function Invoke-AuditPolicySubcategoryRemediation {
    <#
    .SYNOPSIS
        Main function to execute audit policy subcategory override remediation
    .DESCRIPTION
        Performs comprehensive remediation of the Security Options setting
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        Write-Host ""
        Write-Host "=== CIS Remediation 2.3.2.1 - Force Audit Policy Subcategory Override ===" -ForegroundColor Cyan
        Write-Host "CIS Recommendation: Ensure 'Audit: Force audit policy subcategory settings (Windows Vista or later) to override audit policy category settings' is set to 'Enabled'" -ForegroundColor White
        Write-Host "Rationale: This setting allows administrators to enable the more precise auditing capabilities present in Windows Vista and later versions." -ForegroundColor Gray
        Write-Host ""
        
        # Check if computer is domain member
        $isDomainMember = Test-DomainMember
        
        if ($isDomainMember) {
            Write-Host "Domain environment detected - Group Policy configuration recommended" -ForegroundColor Yellow
            
            # Apply Group Policy setting
            $groupPolicyResult = Apply-AuditPolicySubcategoryGroupPolicy
            
            if ($groupPolicyResult.Status -eq "Success") {
                Write-Host "Group Policy setting applied successfully" -ForegroundColor Green
            } else {
                Write-Host "Group Policy setting may require manual configuration" -ForegroundColor Yellow
            }
        }
        
        # Perform main remediation
        $remediationResult = Remediate-ForceAuditPolicySubcategoryOverride
        
        return $remediationResult
    }
    catch {
        Write-Error "Audit policy subcategory override remediation failed: $_"
        return New-CISRemediationResult -CIS_ID "2.3.2.1" -Title "Ensure 'Audit: Force audit policy subcategory settings (Windows Vista or later) to override audit policy category settings' is set to 'Enabled'" -PreviousValue "Unknown" -NewValue "Unknown" -Status "Error" -Message "Remediation failed: $_" -IsCompliant $false -RequiresManualAction $true -ErrorMessage $_
    }
}

# Execute remediation if script is run directly
if ($MyInvocation.InvocationName -ne ".") {
    try {
        $remediationResult = Invoke-AuditPolicySubcategoryRemediation
        
        # Output summary
        Write-Host ""
        Write-Host "=== Remediation Summary ===" -ForegroundColor Cyan
        Write-Host "CIS ID: $($remediationResult.CIS_ID)" -ForegroundColor White
        Write-Host "Setting: $($remediationResult.Title)" -ForegroundColor White
        Write-Host "Previous Value: $($remediationResult.PreviousValue)" -ForegroundColor White
        Write-Host "New Value: $($remediationResult.NewValue)" -ForegroundColor White
        Write-Host "Status: $($remediationResult.Status)" -ForegroundColor $(if ($remediationResult.IsCompliant) { "Green" } else { "Red" })
        Write-Host "Message: $($remediationResult.Message)" -ForegroundColor White
        Write-Host "Source: $($remediationResult.Source)" -ForegroundColor White
        
        # Exit with appropriate code
        if ($remediationResult.IsCompliant) {
            exit 0
        } else {
            exit 1
        }
    }
    catch {
        Write-Error "Script execution failed: $_"
        exit 2
    }
}

# Export functions
Export-ModuleMember -Function Remediate-ForceAuditPolicySubcategoryOverride, Apply-AuditPolicySubcategoryGroupPolicy, Invoke-AuditPolicySubcategoryRemediation