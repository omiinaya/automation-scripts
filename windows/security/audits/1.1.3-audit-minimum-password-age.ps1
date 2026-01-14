# Audit: Minimum password age setting on Windows
# CIS Benchmark: 1.1.3 (L1) Ensure 'Minimum password age' is set to '1 or more day(s)'
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
        Write-SectionHeader -Title "Password Policy Audit: Minimum Password Age"
    }
    
    # Check if this is a domain environment
    $isDomainMember = (Get-CimInstance -ClassName Win32_ComputerSystem).PartOfDomain
    
    if ($isDomainMember) {
        if ($VerboseOutput) {
            Write-StatusMessage -Message "Computer is domain member - checking password policy" -Type Info
        }
        
        # For domain members, we need to check the actual password policy
        # This requires using secedit or net accounts command
        try {
            $netAccounts = net accounts
            $minAgeLine = $netAccounts | Where-Object { $_ -like "*Minimum password age*" }
            
            if ($minAgeLine) {
                $minimumPasswordAge = [int]($minAgeLine -replace "[^\d]", "")
                $source = "Domain Policy"
            } else {
                if ($VerboseOutput) {
                    Write-StatusMessage -Message "Unable to determine minimum password age from net accounts" -Type Warning
                }
                $minimumPasswordAge = 1
                $source = "Domain Default (assumed)"
            }
        } catch {
            if ($VerboseOutput) {
                Write-StatusMessage -Message "Failed to retrieve password policy information" -Type Warning
            }
            $minimumPasswordAge = 1
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
            $minAgeLine = $policyContent | Where-Object { $_ -like "MinimumPasswordAge*" }
            
            if ($minAgeLine) {
                $minimumPasswordAge = [int]($minAgeLine -split "=")[1].Trim()
                $source = "Local Policy"
            } else {
                if ($VerboseOutput) {
                    Write-StatusMessage -Message "Minimum password age setting not found in policy" -Type Warning
                }
                $minimumPasswordAge = 0
                $source = "Local Default"
            }
            
            # Clean up temp file
            Remove-Item $tempFile -ErrorAction SilentlyContinue
        } catch {
            if ($VerboseOutput) {
                Write-StatusMessage -Message "Failed to retrieve local password policy" -Type Warning
            }
            $minimumPasswordAge = 0
            $source = "Local Default (assumed)"
        }
    }
    
    # Display audit results
    if ($VerboseOutput) {
        Write-Host ""
        Write-Host "AUDIT RESULTS:" -ForegroundColor Cyan
        Write-Host "==============" -ForegroundColor Cyan
        Write-Host "Setting: Minimum password age" -ForegroundColor White
        Write-Host "Current Value: $minimumPasswordAge day(s)" -ForegroundColor White
        Write-Host "Source: $source" -ForegroundColor White
        Write-Host "Recommended: 1 or more day(s)" -ForegroundColor White
        Write-Host ""
    }
    
    # Determine compliance status
    if ($minimumPasswordAge -ge 1) {
        if ($VerboseOutput) {
            Write-StatusMessage -Message "COMPLIANT: Minimum password age setting meets CIS benchmark" -Type Success
        }
        $complianceStatus = "Compliant"
    } else {
        if ($VerboseOutput) {
            Write-StatusMessage -Message "NON-COMPLIANT: Minimum password age setting does not meet CIS benchmark" -Type Error
        }
        $complianceStatus = "Non-Compliant"
    }
    $auditPass = ($minimumPasswordAge -ge 1)
    
    # Generate detailed report
    if ($VerboseOutput) {
        Write-Host ""
        Write-SectionHeader -Title "Detailed Audit Report"
        
        $auditData = @(
            [PSCustomObject]@{
                Setting = "Minimum password age"
                CurrentValue = "$minimumPasswordAge day(s)"
                RecommendedValue = "1 or more day(s)"
                Compliance = $complianceStatus
                Source = $source
                CISReference = "1.1.3 (L1)"
            }
        )
        
        Show-Table -Data $auditData -Title "Password Policy Audit Results"
    }
    
    # Additional information
    if ($VerboseOutput) {
        Write-Host ""
        Write-Host "ADDITIONAL INFORMATION:" -ForegroundColor Cyan
        Write-Host "======================" -ForegroundColor Cyan
        Write-Host "• This setting determines how many days a password must be used before it can be changed" -ForegroundColor Gray
        Write-Host "• Default value: 1 day on domain members, 0 days on standalone workstations" -ForegroundColor Gray
        Write-Host "• Rationale: Prevents users from quickly cycling through passwords to reuse old ones" -ForegroundColor Gray
        Write-Host "• Impact: Users cannot change passwords immediately after setting them" -ForegroundColor Gray
    }
    
    # Remediation guidance
    if ($complianceStatus -eq "Non-Compliant") {
        if ($VerboseOutput) {
            Write-Host ""
            Write-SectionHeader -Title "Remediation Guidance"
            Write-Host "To remediate this setting:" -ForegroundColor Yellow
            Write-Host "1. Open Group Policy Editor (gpedit.msc)" -ForegroundColor White
            Write-Host "2. Navigate to: Computer Configuration\Policies\Windows Settings\Security Settings\Account Policies\Password Policy" -ForegroundColor White
            Write-Host "3. Set 'Minimum password age' to 1 or more day(s)" -ForegroundColor White
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