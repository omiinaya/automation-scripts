# Audit: 2.2.3
# CIS Benchmark: 2.2.3 (L1)

[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISAuditScript -ScriptRoot $scriptRoot -AuditBlock {
if ($VerboseOutput) {
        Write-SectionHeader -Title "User Rights Assignment Audit: Act as part of the operating system"
    }
    
    # Use Invoke-CISAudit with custom script block for user rights assignment audit
    $auditResult = Invoke-CISAudit -CIS_ID "2.2.3" -AuditType "Custom" -VerboseOutput:$VerboseOutput -Section "2" -CustomScriptBlock {
        # Check user rights assignment using secedit
            # Export current security policy
            $tempFile = [System.IO.Path]::GetTempFileName()
            secedit /export /cfg $tempFile /quiet
            
            # Read the exported policy
            $policyContent = Get-Content $tempFile
            $actAsOSLine = $policyContent | Where-Object { $_ -like "SeTcbPrivilege*" }
            
            if ($actAsOSLine) {
                $actAsOSValue = ($actAsOSLine -split "=")[1].Trim()
                $source = "Local Policy"
                
                # Check if the value is "No One" (empty or specific value)
                if ([string]::IsNullOrWhiteSpace($actAsOSValue) -or $actAsOSValue -eq "") {
                    $currentValue = "No One"
                } else {
                    $currentValue = $actAsOSValue
                }
            } else {
                $currentValue = "No One"
                $source = "Local Default"
            }
            
            # Clean up temp file
            Remove-Item $tempFile -ErrorAction SilentlyContinue
        } catch {
            $currentValue = "No One"
            $source = "Local Default (assumed)"
}
