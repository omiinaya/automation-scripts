# Audit: Allow Administrator account lockout setting on Windows
# CIS Benchmark: 1.2.3 (L1) Ensure 'Allow Administrator account lockout' is set to 'Enabled'
# Refactored to use CIS Framework Module

[CmdletBinding()]
param()

$VerboseOutput = $PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Verbose')

# Import the required modules using ModuleIndex
$modulePath = Join-Path $PSScriptRoot "..\..\..\..\modules\ModuleIndex.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

# Check admin rights and handle elevation
if (-not (Test-AdminRights)) {
    Invoke-Elevation
}

try {
    if ($VerboseOutput) {
        Write-SectionHeader -Title "Account Lockout Policy Audit: Allow Administrator Account Lockout"
    }
    
    # Use Invoke-CISAudit with custom script block for administrator account lockout audit
    $auditResult = Invoke-CISAudit -CIS_ID "1.2.3" -AuditType "Custom" -VerboseOutput:$VerboseOutput -Section "1" -CustomScriptBlock {
        # Check if this is a domain environment
        $isDomainMember = (Get-CimInstance -ClassName Win32_ComputerSystem).PartOfDomain
        
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
            
            # Look for administrator lockout setting
            $adminLockoutLine = $policyContent | Where-Object { $_ -like "AllowAdministratorAccountLockout*" }
            
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
                $adminLockoutEnabled = $false
                $source = if ($isDomainMember) { "Domain Default (assumed)" } else { "Local Default (assumed)" }
            }
            
            # Clean up temp file
            Remove-Item $tempFile -ErrorAction SilentlyContinue
        } catch {
            # secedit method failed
        }
        
        # Method 2: Check registry (alternative method)
        if ($source -eq "Unknown") {
            try {
                # This registry path might contain the setting
                $registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
                $valueName = "AllowAdministratorAccountLockout"
                
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
        
        # Return custom audit result
        return @{
            CurrentValue = $(if ($adminLockoutEnabled) { "Enabled" } else { "Disabled" })
            Source = $source
            Details = "Allow Administrator account lockout setting audit - $(if ($isDomainMember) { 'Domain member' } else { 'Standalone workstation' })"
        }
    }
    
    # Return the compliance status
    $auditResult.IsCompliant
} catch {
    if ($VerboseOutput) {
        Wait-OnError -ErrorMessage "Failed to perform account lockout policy audit: $($_.Exception.Message)"
    } else {
        $false
    }
}