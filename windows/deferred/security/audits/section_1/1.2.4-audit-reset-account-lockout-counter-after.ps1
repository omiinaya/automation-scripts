# Audit: 1.2.4
# CIS Benchmark: 1.2.4 (L1)

[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISAuditScript -ScriptRoot $scriptRoot -AuditBlock {
if ($VerboseOutput) {
        Write-SectionHeader -Title "Account Lockout Policy Audit: Reset Account Lockout Counter After"
    }
    
    # Use Invoke-CISAudit with custom script block for reset account lockout counter audit
    $auditResult = Invoke-CISAudit -CIS_ID "1.2.4" -AuditType "Custom" -VerboseOutput:$VerboseOutput -Section "1" -CustomScriptBlock {
        # Check if this is a domain environment
        $isDomainMember = (Get-CimInstance -ClassName Win32_ComputerSystem).PartOfDomain
        
        # Check the actual setting using secedit
            # Export current security policy
            $tempFile = [System.IO.Path]::GetTempFileName()
            secedit /export /cfg $tempFile /quiet
            
            # Read the exported policy
            $policyContent = Get-Content $tempFile
            $resetCounterLine = $policyContent | Where-Object { $_ -like "ResetLockoutCount*" }
            
            if ($resetCounterLine) {
                $resetCounterValue = ($resetCounterLine -split "=")[1].Trim()
                $resetCounter = [int]$resetCounterValue
                $source = if ($isDomainMember) { "Domain Policy" } else { "Local Policy" }
            } else {
                $resetCounter = 0
                $source = if ($isDomainMember) { "Domain Default" } else { "Local Default" }
            }
            
            # Clean up temp file
            Remove-Item $tempFile -ErrorAction SilentlyContinue
        } catch {
            $resetCounter = 0
            $source = if ($isDomainMember) { "Domain Default (assumed)" } else { "Local Default (assumed)" }
}
