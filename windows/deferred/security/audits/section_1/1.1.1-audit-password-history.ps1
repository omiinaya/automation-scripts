# Audit: Enforce password history setting on Windows
# CIS Benchmark: 1.1.1 (L1) Ensure 'Enforce password history' is set to '24 or more password(s)'

[CmdletBinding()]
param()

# Import ScriptTemplates module and invoke audit with boilerplate handling
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISAuditScript -ScriptRoot $scriptRoot -AuditBlock {
    # Check if this is a domain environment
    $isDomainMember = (Get-CimInstance -ClassName Win32_ComputerSystem).PartOfDomain
    
    if ($isDomainMember) {
        # For domain members, check password policy using net accounts
        try {
            $netAccounts = net accounts
            $passwordHistoryLine = $netAccounts | Where-Object { $_ -like "*Password history*" }
            
            if ($passwordHistoryLine) {
                $passwordHistoryValue = [int]($passwordHistoryLine -replace "[^\d]", "")
                $source = "Domain Policy"
            } else {
                $passwordHistoryValue = 24
                $source = "Domain Default (assumed)"
            }
        } catch {
            $passwordHistoryValue = 24
            $source = "Domain Default (assumed)"
        }
    } else {
        # For standalone systems, check local policy using secedit
        try {
            $tempFile = [System.IO.Path]::GetTempFileName()
            secedit /export /cfg $tempFile /quiet
            
            $policyContent = Get-Content $tempFile
            $passwordHistoryLine = $policyContent | Where-Object { $_ -like "PasswordHistorySize*" }
            
            if ($passwordHistoryLine) {
                $passwordHistoryValue = [int]($passwordHistoryLine -split "=")[1].Trim()
                $source = "Local Policy"
            } else {
                $passwordHistoryValue = 0
                $source = "Local Default"
            }
            
            Remove-Item $tempFile -ErrorAction SilentlyContinue
        } catch {
            $passwordHistoryValue = 0
            $source = "Local Default (assumed)"
        }
    }
    
    # Return custom audit result
    return @{
        CurrentValue = $passwordHistoryValue
        Source = $source
        Details = "Password history setting audit - $(if ($isDomainMember) { 'Domain member' } else { 'Standalone workstation' })"
    }
}
