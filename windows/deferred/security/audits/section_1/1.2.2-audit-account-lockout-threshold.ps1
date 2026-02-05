# Audit: 1.2.2
# CIS Benchmark: 1.2.2 (L1)

[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISAuditScript -ScriptRoot $scriptRoot -AuditBlock {
if ($VerboseOutput) {
        Write-SectionHeader -Title "Account Lockout Policy Audit: Account Lockout Threshold"
    }
    
    # Use Invoke-CISAudit with custom script block for account lockout threshold audit
    $auditResult = Invoke-CISAudit -CIS_ID "1.2.2" -AuditType "Custom" -VerboseOutput:$VerboseOutput -Section "1" -CustomScriptBlock {
        # Check if this is a domain environment
        $isDomainMember = (Get-CimInstance -ClassName Win32_ComputerSystem).PartOfDomain
        
        # Check the actual setting using secedit
            # Export current security policy
            $tempFile = [System.IO.Path]::GetTempFileName()
            secedit /export /cfg $tempFile /quiet
            
            # Read the exported policy
            $policyContent = Get-Content $tempFile
            $lockoutThresholdLine = $policyContent | Where-Object { $_ -like "LockoutBadCount*" }
            
            if ($lockoutThresholdLine) {
                $lockoutThresholdValue = ($lockoutThresholdLine -split "=")[1].Trim()
                $lockoutThreshold = [int]$lockoutThresholdValue
                $source = if ($isDomainMember) { "Domain Policy" } else { "Local Policy" }
            } else {
                $lockoutThreshold = 0
                $source = if ($isDomainMember) { "Domain Default" } else { "Local Default" }
            }
            
            # Clean up temp file
            Remove-Item $tempFile -ErrorAction SilentlyContinue
        } catch {
            $lockoutThreshold = 0
            $source = if ($isDomainMember) { "Domain Default (assumed)" } else { "Local Default (assumed)" }
}
