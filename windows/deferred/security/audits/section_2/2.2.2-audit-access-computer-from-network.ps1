# Audit: 2.2.2
# CIS Benchmark: 2.2.2 (L1)

[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISAuditScript -ScriptRoot $scriptRoot -AuditBlock {
if ($VerboseOutput) {
        Write-SectionHeader -Title "User Rights Assignment Audit: Access this computer from the network"
    }
    
    # Use Invoke-CISAudit with custom script block for user rights assignment audit
    $auditResult = Invoke-CISAudit -CIS_ID "2.2.2" -AuditType "Custom" -VerboseOutput:$VerboseOutput -Section "2" -CustomScriptBlock {
        # Check user rights assignment using secedit
            # Export current security policy
            $tempFile = [System.IO.Path]::GetTempFileName()
            secedit /export /cfg $tempFile /quiet
            
            # Read the exported policy
            $policyContent = Get-Content $tempFile
            $networkAccessLine = $policyContent | Where-Object { $_ -like "SeNetworkLogonRight*" }
            
            if ($networkAccessLine) {
                $networkAccessValue = ($networkAccessLine -split "=")[1].Trim()
                $source = "Local Policy"
                
                # Check if the value contains the required groups
                $currentValue = $networkAccessValue
            } else {
                $currentValue = "Administrators, Remote Desktop Users"
                $source = "Local Default"
            }
            
            # Clean up temp file
            Remove-Item $tempFile -ErrorAction SilentlyContinue
        } catch {
            $currentValue = "Administrators, Remote Desktop Users"
            $source = "Local Default (assumed)"
}
