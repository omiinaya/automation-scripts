# Audit: 1.2.1
# CIS Benchmark: 1.2.1 (L1)

[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISAuditScript -ScriptRoot $scriptRoot -AuditBlock {
if ($VerboseOutput) {
        Write-SectionHeader -Title "Account Lockout Policy Audit: Account Lockout Duration"
    }
    
    # Use Invoke-CISAudit with custom script block for account lockout duration audit
    $auditResult = Invoke-CISAudit -CIS_ID "1.2.1" -AuditType "Custom" -VerboseOutput:$VerboseOutput -Section "1" -CustomScriptBlock {
        # Check if this is a domain environment
        $isDomainMember = (Get-CimInstance -ClassName Win32_ComputerSystem).PartOfDomain
        
        # Check the actual setting using secedit
            # Export current security policy
            $tempFile = [System.IO.Path]::GetTempFileName()
            secedit /export /cfg $tempFile /quiet
            
            # Read the exported policy
            $policyContent = Get-Content $tempFile
            $lockoutDurationLine = $policyContent | Where-Object { $_ -like "LockoutDuration*" }
            
            if ($lockoutDurationLine) {
                $lockoutDurationValue = ($lockoutDurationLine -split "=")[1].Trim()
                $lockoutDuration = [int]$lockoutDurationValue
                $source = if ($isDomainMember) { "Domain Policy" } else { "Local Policy" }
            } else {
                $lockoutDuration = 0
                $source = if ($isDomainMember) { "Domain Default" } else { "Local Default" }
            }
            
            # Clean up temp file
            Remove-Item $tempFile -ErrorAction SilentlyContinue
        } catch {
            $lockoutDuration = 0
            $source = if ($isDomainMember) { "Domain Default (assumed)" } else { "Local Default (assumed)" }
}
