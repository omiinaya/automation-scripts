<#
.SYNOPSIS
    Secedit utility functions for PowerShell automation scripts.
.DESCRIPTION
    Provides standardized functions for secedit export/import operations to eliminate
    code duplication across audit and remediation scripts.
.NOTES
    File Name      : SeceditUtils.psm1
    Author         : System Administrator
    Prerequisite   : PowerShell 5.1 or later
#>

# Import CommonUtilities for error handling patterns
$originalVerbosePreference = $VerbosePreference
$VerbosePreference = 'SilentlyContinue'
Import-Module "$PSScriptRoot\CommonUtilities.psm1" -Force -WarningAction SilentlyContinue -Verbose:$false
$VerbosePreference = $originalVerbosePreference

# Function to export security policy
function Export-SecurityPolicy {
    <#
    .SYNOPSIS
        Exports the current security policy to a file.
    .DESCRIPTION
        Uses secedit to export the security policy to a specified file path.
    .PARAMETER OutputPath
        The path where the security policy will be exported.
    .EXAMPLE
        Export-SecurityPolicy -OutputPath "C:\temp\security.inf"
    .OUTPUTS
        Boolean indicating success or failure.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$OutputPath
    )
    
    $result = secedit /export /cfg $OutputPath /quiet 2>&1
    return $LASTEXITCODE -eq 0
}

# Function to import security policy
function Import-SecurityPolicy {
    <#
    .SYNOPSIS
        Imports a security policy from a file.
    .DESCRIPTION
        Uses secedit to apply a security policy from a specified file.
    .PARAMETER InputPath
        The path to the security policy file to import.
    .EXAMPLE
        Import-SecurityPolicy -InputPath "C:\temp\security.inf"
    .OUTPUTS
        Boolean indicating success or failure.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$InputPath
    )
    
    $result = secedit /configure /db secedit.sdb /cfg $InputPath /quiet 2>&1
    return $LASTEXITCODE -eq 0
}

# Function to test security policy setting
function Test-SecurityPolicy {
    <#
    .SYNOPSIS
        Tests if a security policy setting matches the expected value.
    .DESCRIPTION
        Compares a specific security policy setting against an expected value.
    .PARAMETER SettingName
        The name of the security policy setting to test.
    .PARAMETER ExpectedValue
        The expected value for the setting.
    .EXAMPLE
        Test-SecurityPolicy -SettingName "PasswordHistorySize" -ExpectedValue "24"
    .OUTPUTS
        Boolean indicating compliance.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$SettingName,
        [Parameter(Mandatory=$true)]
        [string]$ExpectedValue
    )
    
    $currentValue = Get-SecurityPolicyValue -SettingName $SettingName
    return $currentValue -eq $ExpectedValue
}

# Function to get security policy value
function Get-SecurityPolicyValue {
    <#
    .SYNOPSIS
        Gets the value of a specific security policy setting.
    .DESCRIPTION
        Retrieves the current value of a security policy setting.
    .PARAMETER SettingName
        The name of the security policy setting to retrieve.
    .EXAMPLE
        Get-SecurityPolicyValue -SettingName "PasswordHistorySize"
    .OUTPUTS
        String value of the setting, or $null if not found.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$SettingName
    )
    
    $tempFile = [System.IO.Path]::GetTempFileName()
    try {
        secedit /export /cfg $tempFile /quiet | Out-Null
        $policyContent = Get-Content $tempFile
        $settingLine = $policyContent | Where-Object { $_ -like "$SettingName*" }
        
        if ($settingLine) {
            return ($settingLine -split "=")[1].Trim()
        }
        
        return $null
    } finally {
        Remove-Item $tempFile -ErrorAction SilentlyContinue
    }
}

# Function to apply security policy template
function Apply-SecurityPolicyTemplate {
    <#
    .SYNOPSIS
        Applies a security policy template content.
    .DESCRIPTION
        Creates a temporary file from template content and applies it using secedit.
    .PARAMETER TemplateContent
        The security policy template content as a string.
    .EXAMPLE
        Apply-SecurityPolicyTemplate -TemplateContent $template
    .OUTPUTS
        Boolean indicating success or failure.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$TemplateContent
    )
    
    $tempFile = [System.IO.Path]::GetTempFileName()
    try {
        $TemplateContent | Out-File -FilePath $tempFile -Encoding Unicode
        $result = secedit /configure /db secedit.sdb /cfg $tempFile /quiet 2>&1
        return $LASTEXITCODE -eq 0
    } finally {
        Remove-Item $tempFile -ErrorAction SilentlyContinue
    }
}

# Function to get security policy section
function Get-SecurityPolicySection {
    <#
    .SYNOPSIS
        Gets a specific section from the security policy.
    .DESCRIPTION
        Retrieves all settings from a specific section of the security policy.
    .PARAMETER SectionName
        The name of the section to retrieve (e.g., "System Access", "Privilege Rights").
    .EXAMPLE
        Get-SecurityPolicySection -SectionName "System Access"
    .OUTPUTS
        Hashtable of setting names to values.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$SectionName
    )
    
    $tempFile = [System.IO.Path]::GetTempFileName()
    try {
        secedit /export /cfg $tempFile /quiet | Out-Null
        $policyContent = Get-Content $tempFile
        $section = @{}
        $inSection = $false
        
        foreach ($line in $policyContent) {
            if ($line -match "^\[$SectionName\]") {
                $inSection = $true; continue
            }
            if ($inSection -and $line -match "^\[") {
                break
            }
            if ($inSection -and $line -match "^(.+?)\s*=\s*(.*)$") {
                $section[$matches[1].Trim()] = $matches[2].Trim()
            }
        }
        
        return $section
    } finally {
        Remove-Item $tempFile -ErrorAction SilentlyContinue
    }
}

# Function to create security policy template
function New-SecurityPolicyTemplate {
    <#
    .SYNOPSIS
        Creates a security policy template string.
    .DESCRIPTION
        Generates a secedit-compatible template string from provided settings.
    .PARAMETER SystemAccess
        Hashtable of system access settings.
    .PARAMETER PrivilegeRights
        Hashtable of privilege rights settings.
    .EXAMPLE
        New-SecurityPolicyTemplate -SystemAccess @{PasswordHistorySize = 24}
    .OUTPUTS
        String containing the secedit template.
    #>
    param(
        [hashtable]$SystemAccess,
        [hashtable]$PrivilegeRights
    )
    
    $template = @"
[Unicode]
Unicode=yes
[Version]
signature="`$CHICAGO`$"
Revision=1
"@
    
    if ($SystemAccess) {
        $template += "`n[System Access]`n"
        foreach ($key in $SystemAccess.Keys) {
            $template += "$key = $($SystemAccess[$key])`n"
        }
    }
    
    if ($PrivilegeRights) {
        $template += "`n[Privilege Rights]`n"
        foreach ($key in $PrivilegeRights.Keys) {
            $template += "$key = $($PrivilegeRights[$key])`n"
        }
    }
    
    return $template
}

# Function to verify security policy change
function Test-SecurityPolicyChange {
    <#
    .SYNOPSIS
        Verifies that a security policy change was applied successfully.
    .DESCRIPTION
        Checks if a specific setting now has the expected value after a change.
    .PARAMETER SettingName
        The name of the setting to verify.
    .PARAMETER ExpectedValue
        The expected value after the change.
    .EXAMPLE
        Test-SecurityPolicyChange -SettingName "PasswordHistorySize" -ExpectedValue "24"
    .OUTPUTS
        Boolean indicating the change was applied.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$SettingName,
        [Parameter(Mandatory=$true)]
        [string]$ExpectedValue
    )
    
    $currentValue = Get-SecurityPolicyValue -SettingName $SettingName
    return $currentValue -eq $ExpectedValue
}

# Export the module members
Export-ModuleMember -Function Export-SecurityPolicy, Import-SecurityPolicy, Test-SecurityPolicy, Get-SecurityPolicyValue, Apply-SecurityPolicyTemplate, Get-SecurityPolicySection, New-SecurityPolicyTemplate, Test-SecurityPolicyChange -Verbose:$false
