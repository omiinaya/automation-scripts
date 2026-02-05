# Audit: 1.1.7
# CIS Benchmark: 1.1.7 (L1)

[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISAuditScript -ScriptRoot $scriptRoot -AuditBlock {
if ($VerboseOutput) {
        Write-SectionHeader -Title "Password Policy Audit: Store Passwords Using Reversible Encryption"
    }
    
    # Use Invoke-CISAudit with custom script block for reversible encryption audit
    $auditResult = Invoke-CISAudit -CIS_ID "1.1.7" -AuditType "Custom" -VerboseOutput:$VerboseOutput -Section "1" -CustomScriptBlock {
        # Check if this is a domain environment
        $isDomainMember = (Get-CimInstance -ClassName Win32_ComputerSystem).PartOfDomain
        
        if ($isDomainMember) {
            # For domain members, check password policy using net accounts
                $netAccounts = net accounts
                $reversibleLine = $netAccounts | Where-Object { $_ -like "*reversible*" }
                
                if ($reversibleLine) {
                    $reversibleValue = if ($reversibleLine -like "*Enabled*" -or $reversibleLine -like "*Yes*") { "Enabled" } else { "Disabled" }
                    $source = "Domain Policy"
                } else {
                    $reversibleValue = "Disabled"
                    $source = "Domain Default (assumed)"
                }
            } catch {
                $reversibleValue = "Disabled"
                $source = "Domain Default (assumed)"
}
