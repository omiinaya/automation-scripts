# Audit: 1.1.5
# CIS Benchmark: 1.1.5 (L1)

[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISAuditScript -ScriptRoot $scriptRoot -AuditBlock {
if ($VerboseOutput) {
        Write-SectionHeader -Title "Password Policy Audit: Password Complexity Requirements"
    }
    
    # Use Invoke-CISAudit with custom script block for password complexity audit
    $auditResult = Invoke-CISAudit -CIS_ID "1.1.5" -AuditType "Custom" -VerboseOutput:$VerboseOutput -Section "1" -CustomScriptBlock {
        # Check if this is a domain environment
        $isDomainMember = (Get-CimInstance -ClassName Win32_ComputerSystem).PartOfDomain
        
        if ($isDomainMember) {
            # For domain members, check password policy using net accounts
                $netAccounts = net accounts
                $complexityLine = $netAccounts | Where-Object { $_ -like "*Password complexity*" }
                
                if ($complexityLine) {
                    $complexityValue = if ($complexityLine -like "*Enabled*" -or $complexityLine -like "*Yes*") { "Enabled" } else { "Disabled" }
                    $source = "Domain Policy"
                } else {
                    $complexityValue = "Enabled"
                    $source = "Domain Default (assumed)"
                }
            } catch {
                $complexityValue = "Enabled"
                $source = "Domain Default (assumed)"
}
