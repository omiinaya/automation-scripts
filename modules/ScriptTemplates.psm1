<#
.SYNOPSIS
    Script template functions for PowerShell automation scripts.
.DESCRIPTION
    Provides template functions for common script patterns to reduce complexity
    and eliminate code duplication across audit and remediation scripts.
.NOTES
    File Name      : ScriptTemplates.psm1
    Author         : System Administrator
    Prerequisite   : PowerShell 5.1 or later
#>

# Import CommonUtilities for error handling patterns
$originalVerbosePreference = $VerbosePreference
$VerbosePreference = 'SilentlyContinue'
Import-Module "$PSScriptRoot\CommonUtilities.psm1" -Force -WarningAction SilentlyContinue -Verbose:$false
$VerbosePreference = $originalVerbosePreference

# Helper function to import modules
function Import-ScriptModules {
    <#
    .SYNOPSIS
        Imports required modules for CIS scripts.
    .DESCRIPTION
        Standardized module import pattern for audit and remediation scripts.
    .PARAMETER ScriptRoot
        The root path of the script.
    .EXAMPLE
        Import-ScriptModules -ScriptRoot $PSScriptRoot
    .OUTPUTS
        None. Imports the modules.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$ScriptRoot
    )
    
    $modulePath = Join-Path $ScriptRoot "..\..\..\..\modules\ModuleIndex.psm1"
    Import-Module $modulePath -Force -WarningAction SilentlyContinue
}

# Helper function to check admin rights
function Test-ScriptAdminRights {
    <#
    .SYNOPSIS
        Checks admin rights and handles elevation if needed.
    .DESCRIPTION
        Standardized admin check with elevation handling.
    .PARAMETER AutoElevate
        Whether to automatically elevate if not admin.
    .EXAMPLE
        Test-ScriptAdminRights -AutoElevate $true
    .OUTPUTS
        Boolean indicating if running as admin.
    #>
    param(
        [bool]$AutoElevate = $true
    )
    
    if (-not (Test-AdminRights)) {
        if ($AutoElevate) { Invoke-Elevation }
        return $false
    }
    return $true
}

# Helper function to get verbose output flag
function Get-ScriptVerboseFlag {
    <#
    .SYNOPSIS
        Gets the verbose output flag from the current invocation.
    .DESCRIPTION
        Standardized verbose flag detection.
    .EXAMPLE
        $VerboseOutput = Get-ScriptVerboseFlag
    .OUTPUTS
        Boolean indicating verbose mode.
    #>
    param()
    
    return $PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Verbose')
}

# Helper function to handle script errors
function Handle-ScriptError {
    <#
    .SYNOPSIS
        Handles script errors with standardized error handling.
    .DESCRIPTION
        Provides consistent error handling for audit and remediation scripts.
    .PARAMETER ErrorRecord
        The error record to handle.
    .PARAMETER ScriptType
        The type of script (Audit or Remediation).
    .PARAMETER VerboseOutput
        Whether verbose output is enabled.
    .EXAMPLE
        Handle-ScriptError -ErrorRecord $_ -ScriptType "Audit" -VerboseOutput $true
    .OUTPUTS
        Returns $false in non-verbose mode, exits in verbose mode.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord,
        [string]$ScriptType = "Script",
        [bool]$VerboseOutput = $false
    )
    
    $errorMsg = "Failed to perform $ScriptType: $($ErrorRecord.Exception.Message)"
    if ($VerboseOutput) { Wait-OnError -ErrorMessage $errorMsg }
    return $false
}

# Main template function for CIS audit scripts
function Invoke-CISAuditScript {
    <#
    .SYNOPSIS
        Template function for CIS audit scripts.
    .DESCRIPTION
        Provides a standardized pattern for audit scripts including module imports,
        admin checks, and error handling.
    .PARAMETER ScriptRoot
        The root path of the script.
    .PARAMETER AuditBlock
        The script block containing the audit logic.
    .PARAMETER AutoElevate
        Whether to automatically elevate (default: $true).
    .EXAMPLE
        Invoke-CISAuditScript -ScriptRoot $PSScriptRoot -AuditBlock { Invoke-CISAudit -CIS_ID "1.1.1" }
    .OUTPUTS
        Returns the audit result or $false on error.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$ScriptRoot,
        [Parameter(Mandatory=$true)]
        [scriptblock]$AuditBlock,
        [bool]$AutoElevate = $true
    )
    
    Import-ScriptModules -ScriptRoot $ScriptRoot
    Test-ScriptAdminRights -AutoElevate $AutoElevate | Out-Null
    $VerboseOutput = Get-ScriptVerboseFlag
    
    try {
        return & $AuditBlock
    } catch {
        return Handle-ScriptError -ErrorRecord $_ -ScriptType "audit" -VerboseOutput $VerboseOutput
    }
}

# Main template function for CIS remediation scripts
function Invoke-CISRemediationScript {
    <#
    .SYNOPSIS
        Template function for CIS remediation scripts.
    .DESCRIPTION
        Provides a standardized pattern for remediation scripts including module imports,
        admin checks, security policy application, and error handling.
    .PARAMETER ScriptRoot
        The root path of the script.
    .PARAMETER RemediationBlock
        The script block containing the remediation logic.
    .PARAMETER AutoElevate
        Whether to automatically elevate (default: $true).
    .EXAMPLE
        Invoke-CISRemediationScript -ScriptRoot $PSScriptRoot -RemediationBlock { Invoke-CISRemediation -CIS_ID "1.1.1" }
    .OUTPUTS
        Returns the remediation result or $false on error.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$ScriptRoot,
        [Parameter(Mandatory=$true)]
        [scriptblock]$RemediationBlock,
        [bool]$AutoElevate = $true
    )
    
    Import-ScriptModules -ScriptRoot $ScriptRoot
    Test-ScriptAdminRights -AutoElevate $AutoElevate | Out-Null
    $VerboseOutput = Get-ScriptVerboseFlag
    
    try {
        return & $RemediationBlock
    } catch {
        return Handle-ScriptError -ErrorRecord $_ -ScriptType "remediation" -VerboseOutput $VerboseOutput
    }
}

# Helper function to write conditional section header
function Write-ConditionalSectionHeader {
    <#
    .SYNOPSIS
        Writes a section header only in verbose mode.
    .DESCRIPTION
        Standardized conditional header writing.
    .PARAMETER Title
        The title of the section.
    .PARAMETER VerboseOutput
        Whether verbose output is enabled.
    .EXAMPLE
        Write-ConditionalSectionHeader -Title "Audit Title" -VerboseOutput $true
    .OUTPUTS
        None. Writes to console if verbose.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Title,
        [bool]$VerboseOutput = $false
    )
    
    if ($VerboseOutput) { Write-SectionHeader -Title $Title }
}

# Helper function to return remediation result
function Return-RemediationResult {
    <#
    .SYNOPSIS
        Returns remediation result based on verbose mode.
    .DESCRIPTION
        Standardized result return pattern for remediation scripts.
    .PARAMETER Result
        The remediation result object.
    .PARAMETER VerboseOutput
        Whether verbose output is enabled.
    .EXAMPLE
        Return-RemediationResult -Result $result -VerboseOutput $true
    .OUTPUTS
        Returns full result in verbose mode, IsCompliant otherwise.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Result,
        [bool]$VerboseOutput = $false
    )
    
    if ($VerboseOutput) { return $Result }
    return $Result.IsCompliant
}

# Template function for service audit
function Invoke-ServiceAuditTemplate {
    <#
    .SYNOPSIS
        Template function for service-based audits.
    .DESCRIPTION
        Standardized pattern for auditing Windows services.
    .PARAMETER CIS_ID
        The CIS recommendation ID.
    .PARAMETER ServiceName
        The name of the service to audit.
    .PARAMETER ServiceDisplayName
        The display name of the service.
    .PARAMETER Section
        The CIS section number.
    .PARAMETER VerboseOutput
        Whether verbose output is enabled.
    .EXAMPLE
        Invoke-ServiceAuditTemplate -CIS_ID "5.1" -ServiceName "BTAGService" -ServiceDisplayName "Bluetooth Audio Gateway" -Section "5"
    .OUTPUTS
        Returns the audit result.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$CIS_ID,
        [Parameter(Mandatory=$true)]
        [string]$ServiceName,
        [Parameter(Mandatory=$true)]
        [string]$ServiceDisplayName,
        [Parameter(Mandatory=$true)]
        [string]$Section,
        [bool]$VerboseOutput = $false
    )
    
    Write-ConditionalSectionHeader -Title "Service Audit: $ServiceDisplayName" -VerboseOutput $VerboseOutput
    return Invoke-CISAudit -CIS_ID $CIS_ID -AuditType "Service" -ServiceName $ServiceName -VerboseOutput:$VerboseOutput -Section $Section
}

# Template function for registry audit
function Invoke-RegistryAuditTemplate {
    <#
    .SYNOPSIS
        Template function for registry-based audits.
    .DESCRIPTION
        Standardized pattern for auditing registry settings.
    .PARAMETER CIS_ID
        The CIS recommendation ID.
    .PARAMETER RegistryPath
        The registry path to audit.
    .PARAMETER RegistryValueName
        The registry value name to audit.
    .PARAMETER SettingDisplayName
        The display name of the setting.
    .PARAMETER Section
        The CIS section number.
    .PARAMETER VerboseOutput
        Whether verbose output is enabled.
    .EXAMPLE
        Invoke-RegistryAuditTemplate -CIS_ID "18.1.1.1" -RegistryPath "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization" -RegistryValueName "NoLockScreenCamera" -SettingDisplayName "Lock Screen Camera" -Section "18"
    .OUTPUTS
        Returns the audit result.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$CIS_ID,
        [Parameter(Mandatory=$true)]
        [string]$RegistryPath,
        [Parameter(Mandatory=$true)]
        [string]$RegistryValueName,
        [Parameter(Mandatory=$true)]
        [string]$SettingDisplayName,
        [Parameter(Mandatory=$true)]
        [string]$Section,
        [bool]$VerboseOutput = $false
    )
    
    Write-ConditionalSectionHeader -Title "Registry Audit: $SettingDisplayName" -VerboseOutput $VerboseOutput
    return Invoke-CISAudit -CIS_ID $CIS_ID -AuditType "Registry" -RegistryPath $RegistryPath -RegistryValueName $RegistryValueName -VerboseOutput:$VerboseOutput -Section $Section
}

# Template function for registry remediation
function Invoke-RegistryRemediationTemplate {
    <#
    .SYNOPSIS
        Template function for registry-based remediations.
    .DESCRIPTION
        Standardized pattern for remediating registry settings.
    .PARAMETER CIS_ID
        The CIS recommendation ID.
    .PARAMETER RegistryPath
        The registry path to remediate.
    .PARAMETER RegistryValueName
        The registry value name to remediate.
    .PARAMETER RegistryValueData
        The value data to set.
    .PARAMETER RegistryValueType
        The registry value type.
    .PARAMETER SettingDisplayName
        The display name of the setting.
    .PARAMETER Section
        The CIS section number.
    .PARAMETER VerboseOutput
        Whether verbose output is enabled.
    .EXAMPLE
        Invoke-RegistryRemediationTemplate -CIS_ID "18.1.1.1" -RegistryPath "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization" -RegistryValueName "NoLockScreenCamera" -RegistryValueData 1 -RegistryValueType "DWord" -SettingDisplayName "Lock Screen Camera" -Section "18"
    .OUTPUTS
        Returns the remediation result.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$CIS_ID,
        [Parameter(Mandatory=$true)]
        [string]$RegistryPath,
        [Parameter(Mandatory=$true)]
        [string]$RegistryValueName,
        [Parameter(Mandatory=$true)]
        [object]$RegistryValueData,
        [Parameter(Mandatory=$true)]
        [string]$RegistryValueType,
        [Parameter(Mandatory=$true)]
        [string]$SettingDisplayName,
        [Parameter(Mandatory=$true)]
        [string]$Section,
        [bool]$VerboseOutput = $false
    )
    
    Write-ConditionalSectionHeader -Title "Registry Remediation: $SettingDisplayName" -VerboseOutput $VerboseOutput
    $result = Invoke-CISRemediation -CIS_ID $CIS_ID -RemediationType "Registry" -RegistryPath $RegistryPath -RegistryValueName $RegistryValueName -RegistryValueData $RegistryValueData -RegistryValueType $RegistryValueType -VerboseOutput:$VerboseOutput -Section $Section
    return Return-RemediationResult -Result $result -VerboseOutput $VerboseOutput
}

# Export the module members
Export-ModuleMember -Function Import-ScriptModules, Test-ScriptAdminRights, Get-ScriptVerboseFlag, Handle-ScriptError, Invoke-CISAuditScript, Invoke-CISRemediationScript, Write-ConditionalSectionHeader, Return-RemediationResult, Invoke-ServiceAuditTemplate, Invoke-RegistryAuditTemplate, Invoke-RegistryRemediationTemplate -Verbose:$false
