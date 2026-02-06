<#
.SYNOPSIS
    Audit utility functions for PowerShell automation scripts.
.DESCRIPTION
    Provides standardized functions for auditpol operations to eliminate code duplication
    across audit and remediation scripts.
.NOTES
    File Name      : AuditUtils.psm1
    Author         : System Administrator
    Prerequisite   : PowerShell 5.1 or later
#>

# Import all modules via ModuleIndex (single source of truth)
$originalVerbosePreference = $VerbosePreference
$VerbosePreference = 'SilentlyContinue'
Import-Module "$PSScriptRoot\ModuleIndex.psm1" -Force -WarningAction SilentlyContinue -Verbose:$false
$VerbosePreference = $originalVerbosePreference

# Function to get audit policy setting
function Get-AuditPolicy {
    <#
    .SYNOPSIS
        Gets the current audit policy setting for a subcategory.
    .DESCRIPTION
        Retrieves audit policy configuration for a specified subcategory GUID.
    .PARAMETER SubcategoryGUID
        The GUID of the audit subcategory to query.
    .EXAMPLE
        Get-AuditPolicy -SubcategoryGUID "{0cce923f-69ae-11d9-bed3-505054503030}"
    .OUTPUTS
        PSCustomObject with Success and Failure settings.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$SubcategoryGUID
    )
    
    $auditResult = auditpol /get /subcategory:$SubcategoryGUID 2>&1
    $setting = Parse-AuditPolicyOutput -Output $auditResult
    return $setting
}

# Function to set audit policy
function Set-AuditPolicy {
    <#
    .SYNOPSIS
        Sets the audit policy for a subcategory.
    .DESCRIPTION
        Configures audit policy for a specified subcategory with success/failure options.
    .PARAMETER SubcategoryGUID
        The GUID of the audit subcategory to configure.
    .PARAMETER EnableSuccess
        Enable success auditing (default: $true).
    .PARAMETER EnableFailure
        Enable failure auditing (default: $true).
    .EXAMPLE
        Set-AuditPolicy -SubcategoryGUID "{0cce923f-69ae-11d9-bed3-505054503030}" -EnableSuccess $true -EnableFailure $true
    .OUTPUTS
        Boolean indicating success or failure.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$SubcategoryGUID,
        [bool]$EnableSuccess = $true,
        [bool]$EnableFailure = $true
    )
    
    $successFlag = if ($EnableSuccess) { "enable" } else { "disable" }
    $failureFlag = if ($EnableFailure) { "enable" } else { "disable" }
    $result = auditpol /set /subcategory:$SubcategoryGUID /success:$successFlag /failure:$failureFlag 2>&1
    return $LASTEXITCODE -eq 0
}

# Function to test audit policy compliance
function Test-AuditPolicy {
    <#
    .SYNOPSIS
        Tests if audit policy matches expected settings.
    .DESCRIPTION
        Compares current audit policy settings against expected values.
    .PARAMETER SubcategoryGUID
        The GUID of the audit subcategory to test.
    .PARAMETER ExpectedSuccess
        Expected success auditing state.
    .PARAMETER ExpectedFailure
        Expected failure auditing state.
    .EXAMPLE
        Test-AuditPolicy -SubcategoryGUID "{0cce923f-69ae-11d9-bed3-505054503030}" -ExpectedSuccess $true -ExpectedFailure $true
    .OUTPUTS
        Boolean indicating compliance.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$SubcategoryGUID,
        [bool]$ExpectedSuccess = $true,
        [bool]$ExpectedFailure = $true
    )
    
    $current = Get-AuditPolicy -SubcategoryGUID $SubcategoryGUID
    return ($current.Success -eq $ExpectedSuccess -and $current.Failure -eq $ExpectedFailure)
}

# Helper function to parse audit policy output
function Parse-AuditPolicyOutput {
    <#
    .SYNOPSIS
        Parses auditpol command output into structured data.
    .DESCRIPTION
        Extracts success and failure settings from auditpol output.
    .PARAMETER Output
        The output from auditpol command.
    .EXAMPLE
        Parse-AuditPolicyOutput -Output $auditResult
    .OUTPUTS
        PSCustomObject with Success and Failure properties.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string[]]$Output
    )
    
    $success = $false
    $failure = $false
    
    foreach ($line in $Output) {
        if ($line -match "Success and Failure") {
            $success = $true; $failure = $true; break
        }
        if ($line -match "Success") { $success = $true }
        if ($line -match "Failure") { $failure = $true }
    }
    
    return [PSCustomObject]@{ Success = $success; Failure = $failure }
}

# Function to get audit policy by name
function Get-AuditPolicyByName {
    <#
    .SYNOPSIS
        Gets audit policy setting by subcategory name.
    .DESCRIPTION
        Retrieves audit policy using subcategory name instead of GUID.
    .PARAMETER SubcategoryName
        The name of the audit subcategory.
    .EXAMPLE
        Get-AuditPolicyByName -SubcategoryName "Credential Validation"
    .OUTPUTS
        PSCustomObject with Success and Failure settings.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$SubcategoryName
    )
    
    $auditResult = auditpol /get /subcategory:"$SubcategoryName" 2>&1
    return Parse-AuditPolicyOutput -Output $auditResult
}

# Function to set audit policy by name
function Set-AuditPolicyByName {
    <#
    .SYNOPSIS
        Sets audit policy by subcategory name.
    .DESCRIPTION
        Configures audit policy using subcategory name.
    .PARAMETER SubcategoryName
        The name of the audit subcategory.
    .PARAMETER EnableSuccess
        Enable success auditing.
    .PARAMETER EnableFailure
        Enable failure auditing.
    .EXAMPLE
        Set-AuditPolicyByName -SubcategoryName "Credential Validation" -EnableSuccess $true -EnableFailure $true
    .OUTPUTS
        Boolean indicating success.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$SubcategoryName,
        [bool]$EnableSuccess = $true,
        [bool]$EnableFailure = $true
    )
    
    $successFlag = if ($EnableSuccess) { "enable" } else { "disable" }
    $failureFlag = if ($EnableFailure) { "enable" } else { "disable" }
    $result = auditpol /set /subcategory:"$SubcategoryName" /success:$successFlag /failure:$failureFlag 2>&1
    return $LASTEXITCODE -eq 0
}

# Function to list all audit policies
function Get-AllAuditPolicies {
    <#
    .SYNOPSIS
        Lists all audit policy subcategories and their settings.
    .DESCRIPTION
        Retrieves a complete list of audit policy configurations.
    .EXAMPLE
        Get-AllAuditPolicies
    .OUTPUTS
        Array of PSCustomObjects with policy information.
    #>
    param()
    
    $auditResult = auditpol /get /category:* 2>&1
    $policies = @()
    
    foreach ($line in $auditResult) {
        if ($line -match "^\s*([A-F0-9\-]+)\s+(.+?)\s+(Success|Failure|No Auditing)") {
            $policies += [PSCustomObject]@{
                GUID = $matches[1]
                Name = $matches[2].Trim()
                Setting = $matches[3]
            }
        }
    }
    
    return $policies
}

# Export the module members
Export-ModuleMember -Function Get-AuditPolicy, Set-AuditPolicy, Test-AuditPolicy, Get-AuditPolicyByName, Set-AuditPolicyByName, Get-AllAuditPolicies -Verbose:$false
