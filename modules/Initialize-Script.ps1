#requires -Version 5.1
<#
.SYNOPSIS
    Shared initialization script for all CIS audit and remediation scripts.
.DESCRIPTION
    Centralizes common initialization tasks like module imports, admin checks,
    and verbose flag detection to eliminate code duplication across scripts.
.EXAMPLE
    . "$PSScriptRoot\..\..\..\modules\Initialize-Script.ps1"
    Initialize-Script -ScriptRoot $PSScriptRoot
.EXAMPLE
    . "$PSScriptRoot\..\..\..\modules\Initialize-Script.ps1"
    Initialize-Script -ScriptRoot $PSScriptRoot -CheckAdminRights
.NOTES
    Author: Automation Team
    Version: 1.0
#>

function Initialize-Script {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptRoot,

        [Parameter()]
        [switch]$CheckAdminRights,

        [Parameter()]
        [switch]$SkipElevation
    )

    # Determine the module import path based on script location depth
    # Audit/Remediation: ..\..\..\..\modules\ModuleIndex.psm1 (4 levels deep)
    # Optimization: ..\..\..\modules\ModuleIndex.psm1 (3 levels deep)
    $depth = ($ScriptRoot -split '\\').Count - ($ScriptRoot.Split('\')[0] -split '\\').Count

    if ($depth -ge 4) {
        $relativePath = "..\..\..\..\modules\ModuleIndex.psm1"
    } else {
        $relativePath = "..\..\..\modules\ModuleIndex.psm1"
    }

    $modulePath = Join-Path $ScriptRoot $relativePath

    # Suppress verbose output during module import
    $originalVerbosePreference = $VerbosePreference
    $VerbosePreference = 'SilentlyContinue'

    try {
        Import-Module $modulePath -Force -WarningAction SilentlyContinue -Verbose:$false -ErrorAction Stop
    }
    catch {
        throw "Failed to import ModuleIndex.psm1 from '$modulePath'. Error: $($_.Exception.Message)"
    }
    finally {
        $VerbosePreference = $originalVerbosePreference
    }

    # Get verbose output flag
    $verboseOutput = $PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Verbose')

    # Check admin rights if requested
    if ($CheckAdminRights -and -not (Test-AdminRights)) {
        if (-not $SkipElevation) {
            Invoke-Elevation
            # Script will exit after elevation, so we won't reach here
        }
    }

    # Return initialization results
    return [PSCustomObject]@{
        VerboseOutput = $verboseOutput
        ModulePath = $modulePath
        ScriptRoot = $ScriptRoot
    }
}

function Get-VerboseOutputFlag {
    [CmdletBinding()]
    param()
    return $PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Verbose')
}

function Invoke-AuditWithStandardErrorHandling {
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$AuditBlock,

        [Parameter(Mandatory = $true)]
        [string]$AuditName,

        [Parameter(Mandatory = $true)]
        [bool]$VerboseOutput
    )

    try {
        return & $AuditBlock
    }
    catch {
        if ($VerboseOutput) {
            Wait-OnError -ErrorMessage "Failed to perform $AuditName audit: $($_.Exception.Message)"
        }
        return $false
    }
}

function Invoke-RemediationWithStandardErrorHandling {
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$RemediationBlock,

        [Parameter(Mandatory = $true)]
        [string]$RemediationName,

        [Parameter(Mandatory = $true)]
        [bool]$VerboseOutput
    )

    try {
        $result = & $RemediationBlock

        # Return appropriate result based on verbose mode
        if ($VerboseOutput) {
            return $result
        } else {
            return $result.IsCompliant
        }
    }
    catch {
        if ($VerboseOutput) {
            Wait-OnError -ErrorMessage "Failed to perform $RemediationName remediation: $($_.Exception.Message)"
        }
        return $false
    }
}

function Write-ConditionalSectionHeader {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,

        [Parameter(Mandatory = $true)]
        [bool]$VerboseOutput
    )

    if ($VerboseOutput) {
        Write-SectionHeader -Title $Title
    }
}

Export-ModuleMember -Function Initialize-Script, Get-VerboseOutputFlag, Invoke-AuditWithStandardErrorHandling, Invoke-RemediationWithStandardErrorHandling, Write-ConditionalSectionHeader
