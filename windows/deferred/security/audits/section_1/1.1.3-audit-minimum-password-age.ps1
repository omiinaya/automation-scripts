# Audit: 1.1.3
# CIS Benchmark: 1.1.3 (L1)

[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISAuditScript -ScriptRoot $scriptRoot -AuditBlock {
if ($VerboseOutput) {
        Write-SectionHeader -Title "Password Policy Audit: Minimum Password Age"
    }
    
    # Use Invoke-CISAudit with custom script block for minimum password age audit
    $auditResult = Invoke-CISAudit -CIS_ID "1.1.3" -AuditType "Custom" -VerboseOutput:$VerboseOutput -Section "1" -CustomScriptBlock {
        # Check if this is a domain environment
        $isDomainMember = (Get-CimInstance -ClassName Win32_ComputerSystem).PartOfDomain
        
        if ($isDomainMember) {
            # For domain members, check password policy using net accounts
                $netAccounts = net accounts
                $passwordAgeLine = $netAccounts | Where-Object { $_ -like "*Minimum password age*" }
                
                if ($passwordAgeLine) {
                    $passwordAgeValue = [int]($passwordAgeLine -replace "[^\d]", "")
                    $source = "Domain Policy"
                } else {
                    $passwordAgeValue = 1
                    $source = "Domain Default (assumed)"
                }
            } catch {
                $passwordAgeValue = 1
                $source = "Domain Default (assumed)"
}
