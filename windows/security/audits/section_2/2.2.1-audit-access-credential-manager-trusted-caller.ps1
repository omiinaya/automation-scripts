# Audit: Access Credential Manager as a trusted caller setting on Windows
# CIS Benchmark: 2.2.1 (L1) Ensure 'Access Credential Manager as a trusted caller' is set to 'No One'
# Refactored to use CIS Framework Module

[CmdletBinding()]
param()

$VerboseOutput = $PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Verbose')

# Import the required modules using ModuleIndex
$modulePath = Join-Path $PSScriptRoot "..\..\..\..\modules\ModuleIndex.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue -Verbose:$false

# Check admin rights and handle elevation
if (-not (Test-AdminRights)) {
    Invoke-Elevation
}

try {
    if ($VerboseOutput) {
        Write-SectionHeader -Title "User Rights Assignment Audit: Access Credential Manager as a trusted caller"
    }
    
    # Check user rights assignment using secedit
    try {
        # Export current security policy
        $tempFile = [System.IO.Path]::GetTempFileName()
        secedit /export /cfg $tempFile /quiet
        
        # Read the exported policy
        $policyContent = Get-Content $tempFile
        $trustedCallerLine = $policyContent | Where-Object { $_ -like "SeTrustedCredManAccessPrivilege*" }
        
        if ($trustedCallerLine) {
            $trustedCallerValue = ($trustedCallerLine -split "=")[1].Trim()
            $source = "Local Policy"
            
            # Check if the value is "No One" (empty or specific value)
            if ([string]::IsNullOrWhiteSpace($trustedCallerValue) -or $trustedCallerValue -eq "") {
                $currentValue = "No One"
            } else {
                $currentValue = $trustedCallerValue
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
    
    # Define the correct setting name and recommended value
    $settingName = "Access Credential Manager as a trusted caller"
    $recommendedValue = "No One"
    
    # Check compliance
    $isCompliant = ($currentValue -eq "No One")
    $complianceStatus = if ($isCompliant) { "Compliant" } else { "Non-Compliant" }
    
    # Output verbose information if requested
    if ($VerboseOutput) {
        Write-Host ""
        Write-SectionHeader -Title "CIS Audit: 2.2.1"
        Write-Host "Setting: $settingName" -ForegroundColor White
        Write-Host "Current Value: $currentValue" -ForegroundColor White
        Write-Host "Recommended: $recommendedValue" -ForegroundColor White
        Write-Host "Compliance: $complianceStatus" -ForegroundColor $(if ($isCompliant) { "Green" } else { "Red" })
        Write-Host "Source: $source" -ForegroundColor White
        Write-Host "Details: Access Credential Manager as a trusted caller user right assignment audit" -ForegroundColor Gray
    }
    
    # Return the compliance status
    $isCompliant
} catch {
    if ($VerboseOutput) {
        Write-Error "Failed to perform user rights assignment audit: $($_.Exception.Message)"
    } else {
        $false
    }
}