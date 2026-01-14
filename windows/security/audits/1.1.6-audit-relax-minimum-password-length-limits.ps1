# Audit: Relax minimum password length limits setting on Windows
# CIS Benchmark: 1.1.6 (L1) Ensure 'Relax minimum password length limits' is set to 'Enabled'
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
        Write-SectionHeader -Title "Password Policy Audit: Relax Minimum Password Length Limits"
    }
    
    # Check if this is a domain environment
    $isDomainMember = (Get-CimInstance -ClassName Win32_ComputerSystem).PartOfDomain
    
    if ($VerboseOutput) {
        Write-StatusMessage -Message "Note: This setting only affects local accounts on the computer" -Type Info
    }
    
    # This setting is stored in the registry
    try {
        $registryPath = "HKLM:\System\CurrentControlSet\Control\SAM"
        $valueName = "RelaxMinimumPasswordLengthLimits"
        
        if (Test-Path $registryPath) {
            $registryValue = Get-ItemProperty -Path $registryPath -Name $valueName -ErrorAction SilentlyContinue
            
            if ($registryValue -ne $null) {
                $relaxLimits = ($registryValue.$valueName -eq 1)
                $source = "Registry Policy"
            } else {
                if ($VerboseOutput) {
                    Write-StatusMessage -Message "Registry value not found, checking default" -Type Warning
                }
                $relaxLimits = $false
                $source = "Default (Disabled)"
            }
        } else {
            if ($VerboseOutput) {
                Write-StatusMessage -Message "Registry path not found" -Type Warning
            }
            $relaxLimits = $false
            $source = "Default (Disabled)"
        }
    } catch {
        if ($VerboseOutput) {
            Write-StatusMessage -Message "Failed to retrieve registry setting" -Type Warning
        }
        $relaxLimits = $false
        $source = "Default (assumed Disabled)"
    }
    
    # Display audit results
    if ($VerboseOutput) {
        Write-Host ""
        Write-Host "AUDIT RESULTS:" -ForegroundColor Cyan
        Write-Host "==============" -ForegroundColor Cyan
        Write-Host "Setting: Relax minimum password length limits" -ForegroundColor White
        Write-Host "Current Value: $(if ($relaxLimits) { 'Enabled' } else { 'Disabled' })" -ForegroundColor White
        Write-Host "Source: $source" -ForegroundColor White
        Write-Host "Recommended: Enabled" -ForegroundColor White
        Write-Host ""
    }
    
    # Determine compliance status
    if ($relaxLimits) {
        if ($VerboseOutput) {
            Write-StatusMessage -Message "COMPLIANT: Relax minimum password length limits setting meets CIS benchmark" -Type Success
        }
        $complianceStatus = "Compliant"
    } else {
        if ($VerboseOutput) {
            Write-StatusMessage -Message "NON-COMPLIANT: Relax minimum password length limits setting does not meet CIS benchmark" -Type Error
        }
        $complianceStatus = "Non-Compliant"
    }
    $auditPass = $relaxLimits
    
    # Generate detailed report
    if ($VerboseOutput) {
        Write-Host ""
        Write-SectionHeader -Title "Detailed Audit Report"
        
        $auditData = @(
            [PSCustomObject]@{
                Setting = "Relax minimum password length limits"
                CurrentValue = if ($relaxLimits) { "Enabled" } else { "Disabled" }
                RecommendedValue = "Enabled"
                Compliance = $complianceStatus
                Source = $source
                CISReference = "1.1.6 (L1)"
            }
        )
        
        Show-Table -Data $auditData -Title "Password Policy Audit Results"
    }
    
    # Additional information
    if ($VerboseOutput) {
        Write-Host ""
        Write-Host "ADDITIONAL INFORMATION:" -ForegroundColor Cyan
        Write-Host "======================" -ForegroundColor Cyan
        Write-Host "• This setting determines whether the minimum password length setting can be increased beyond the legacy limit of 14 characters" -ForegroundColor Gray
        Write-Host "• Default value: Disabled (minimum password length may be configured to a maximum of 14 characters)" -ForegroundColor Gray
        Write-Host "• Rationale: Enables enforcement of longer and generally stronger passwords or passphrases where MFA is not in use" -ForegroundColor Gray
        Write-Host "• Impact: The Minimum password length setting may be configured higher than 14 characters" -ForegroundColor Gray
        Write-Host "• Note: This setting only affects local accounts on the computer" -ForegroundColor Gray
    }
    
    # Remediation guidance
    if ($complianceStatus -eq "Non-Compliant") {
        if ($VerboseOutput) {
            Write-Host ""
            Write-SectionHeader -Title "Remediation Guidance"
            Write-Host "To remediate this setting:" -ForegroundColor Yellow
            Write-Host "1. Open Group Policy Editor (gpedit.msc)" -ForegroundColor White
            Write-Host "2. Navigate to: Computer Configuration\Policies\Windows Settings\Security Settings\Account Policies\Password Policy" -ForegroundColor White
            Write-Host "3. Set 'Relax minimum password length limits' to Enabled" -ForegroundColor White
            Write-Host "4. Apply the policy and run 'gpupdate /force'" -ForegroundColor White
            Write-Host ""
            Write-Host "Note: This setting is only available within the built-in OS security template of Windows 10 Release 2004 and Server 2022 (or newer)" -ForegroundColor Gray
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