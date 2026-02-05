# Audit: 1.1.4
# CIS Benchmark: 1.1.4 (L1)

[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISAuditScript -ScriptRoot $scriptRoot -AuditBlock {
if ($VerboseOutput) {
        Write-SectionHeader -Title "Password Policy Audit: Minimum Password Length"
    }
    
    # Use Invoke-CISAudit with custom script block for minimum password length audit
    $auditResult = Invoke-CISAudit -CIS_ID "1.1.4" -AuditType "Custom" -VerboseOutput:$VerboseOutput -Section "1" -CustomScriptBlock {
        # Check if this is a domain environment
        $isDomainMember = (Get-CimInstance -ClassName Win32_ComputerSystem).PartOfDomain
        
        if ($isDomainMember) {
            # For domain members, check password policy using net accounts
                $netAccounts = net accounts
                $passwordLengthLine = $netAccounts | Where-Object { $_ -like "*Minimum password length*" }
                
                if ($passwordLengthLine) {
                    $passwordLengthValue = [int]($passwordLengthLine -replace "[^\d]", "")
                    $source = "Domain Policy"
                } else {
                    $passwordLengthValue = 7
                    $source = "Domain Default (assumed)"
                }
            } catch {
                $passwordLengthValue = 7
                $source = "Domain Default (assumed)"
}
