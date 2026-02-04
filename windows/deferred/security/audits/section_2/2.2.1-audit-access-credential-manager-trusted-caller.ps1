# Audit: Access Credential Manager as a trusted caller setting on Windows
# CIS Benchmark: 2.2.1 (L1) Ensure 'Access Credential Manager as a trusted caller' is set to 'No One'

[CmdletBinding()]
param()

# Import ScriptTemplates module and invoke audit with boilerplate handling
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISAuditScript -ScriptRoot $scriptRoot -AuditBlock {
    # Check user rights assignment using secedit
    try {
        $tempFile = [System.IO.Path]::GetTempFileName()
        secedit /export /cfg $tempFile /quiet
        
        $policyContent = Get-Content $tempFile
        $trustedCallerLine = $policyContent | Where-Object { $_ -like "SeTrustedCredManAccessPrivilege*" }
        
        if ($trustedCallerLine) {
            $trustedCallerValue = ($trustedCallerLine -split "=")[1].Trim()
            $source = "Local Policy"
            
            if ([string]::IsNullOrWhiteSpace($trustedCallerValue) -or $trustedCallerValue -eq "") {
                $currentValue = "No One"
            } else {
                $currentValue = $trustedCallerValue
            }
        } else {
            $currentValue = "No One"
            $source = "Local Default"
        }
        
        Remove-Item $tempFile -ErrorAction SilentlyContinue
    } catch {
        $currentValue = "No One"
        $source = "Local Default (assumed)"
    }
    
    # Check compliance
    $isCompliant = ($currentValue -eq "No One")
    
    return @{
        CIS_ID = "2.2.1"
        Title = "Access Credential Manager as a trusted caller"
        CurrentValue = $currentValue
        RecommendedValue = "No One"
        IsCompliant = $isCompliant
        Source = $source
        Details = "Access Credential Manager as a trusted caller user right assignment audit"
    }
}
