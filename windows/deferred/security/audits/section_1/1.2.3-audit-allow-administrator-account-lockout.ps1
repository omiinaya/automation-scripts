# Audit: 1.2.3
# CIS Benchmark: 1.2.3 (L1)

[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISAuditScript -ScriptRoot $scriptRoot -AuditBlock {
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
