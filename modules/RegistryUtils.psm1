<#
.SYNOPSIS
    Registry utility functions for Windows registry operations.
.DESCRIPTION
    Provides functions for reading, writing, and managing Windows registry keys and values.
.NOTES
    File Name      : RegistryUtils.psm1
    Author         : System Administrator
    Prerequisite   : PowerShell 5.1 or later
#>

# Function to test if a registry key exists
function Test-RegistryKey {
    <#
    .SYNOPSIS
        Checks if a registry key exists.
    .DESCRIPTION
        Returns $true if the registry key exists, $false otherwise.
    .PARAMETER KeyPath
        The full path to the registry key.
    .EXAMPLE
        if (Test-RegistryKey -KeyPath "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion") { Write-Host "Key exists" }
    .OUTPUTS
        System.Boolean
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$KeyPath
    )
    
    return Test-Path -Path $KeyPath
}

# Function to test if a registry value exists
function Test-RegistryValue {
    <#
    .SYNOPSIS
        Checks if a registry value exists.
    .DESCRIPTION
        Returns $true if the registry value exists, $false otherwise.
    .PARAMETER KeyPath
        The full path to the registry key.
    .PARAMETER ValueName
        The name of the registry value to check.
    .EXAMPLE
        if (Test-RegistryValue -KeyPath "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion" -ValueName "ProgramFilesDir") { Write-Host "Value exists" }
    .OUTPUTS
        System.Boolean
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$KeyPath,
        [Parameter(Mandatory=$true)]
        [string]$ValueName
    )
    
    if (Test-RegistryKey -KeyPath $KeyPath) {
        $value = Get-ItemProperty -Path $KeyPath -Name $ValueName -ErrorAction SilentlyContinue
        return ($null -ne $value.$ValueName)
    }
    
    return $false
}

# Function to get a registry value
function Get-RegistryValue {
    <#
    .SYNOPSIS
        Gets the value of a registry key.
    .DESCRIPTION
        Returns the value of the specified registry value.
    .PARAMETER KeyPath
        The full path to the registry key.
    .PARAMETER ValueName
        The name of the registry value to get.
    .PARAMETER DefaultValue
        The default value to return if the value doesn't exist.
    .EXAMPLE
        $value = Get-RegistryValue -KeyPath "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion" -ValueName "ProgramFilesDir"
    .OUTPUTS
        System.Object
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$KeyPath,
        [Parameter(Mandatory=$true)]
        [string]$ValueName,
        [object]$DefaultValue = $null
    )
    
    if (Test-RegistryValue -KeyPath $KeyPath -ValueName $ValueName) {
        $value = Get-ItemProperty -Path $KeyPath -Name $ValueName -ErrorAction SilentlyContinue
        return $value.$ValueName
    }
    
    return $DefaultValue
}

# Function to set a registry value
function Set-RegistryValue {
<#
.SYNOPSIS
    Sets a registry value.
.DESCRIPTION
    Creates or updates a registry value with the specified data.
.PARAMETER KeyPath
    The full path to the registry key.
.PARAMETER ValueName
    The name of the registry value to set.
.PARAMETER ValueData
    The data to store in the registry value.
.PARAMETER ValueType
    The type of the registry value (String, DWord, QWord, Binary, MultiString, ExpandString).
.EXAMPLE
    Set-RegistryValue -KeyPath "HKLM:\SOFTWARE\MyApp" -ValueName "Setting1" -ValueData "MyValue" -ValueType String
.EXAMPLE
    Set-RegistryValue -KeyPath "HKLM:\SOFTWARE\MyApp" -ValueName "Enabled" -ValueData 1 -ValueType DWord
.NOTES
    Creates the registry key if it doesn't exist.
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$KeyPath,
    [Parameter(Mandatory=$true)]
    [string]$ValueName,
    [Parameter(Mandatory=$true)]
    [object]$ValueData,
    [ValidateSet("String", "DWord", "QWord", "Binary", "MultiString", "ExpandString")]
    [string]$ValueType = "String"
)
    
    try {
        if (-not (Test-RegistryKey -KeyPath $KeyPath)) {
            New-Item -Path $KeyPath -Force | Out-Null
        }
        
        Set-ItemProperty -Path $KeyPath -Name $ValueName -Value $ValueData -Type $ValueType -Force
        Write-Host "Registry value '$ValueName' set successfully" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to set registry value '$ValueName': $_"
    }
}

# Function to remove a registry value
function Remove-RegistryValue {
    <#
    .SYNOPSIS
        Removes a registry value.
    .DESCRIPTION
        Deletes a registry value from the specified key.
    .PARAMETER KeyPath
        The full path to the registry key.
    .PARAMETER ValueName
        The name of the registry value to remove.
    .EXAMPLE
        Remove-RegistryValue -KeyPath "HKLM:\SOFTWARE\MyApp" -ValueName "OldSetting"
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$KeyPath,
        [Parameter(Mandatory=$true)]
        [string]$ValueName
    )
    
    try {
        if (Test-RegistryValue -KeyPath $KeyPath -ValueName $ValueName) {
            Remove-ItemProperty -Path $KeyPath -Name $ValueName -Force
            Write-Host "Registry value '$ValueName' removed successfully" -ForegroundColor Green
        } else {
            Write-Warning "Registry value '$ValueName' does not exist"
        }
    }
    catch {
        Write-Error "Failed to remove registry value '$ValueName': $_"
    }
}

# Function to remove a registry key
function Remove-RegistryKey {
<#
.SYNOPSIS
    Removes a registry key and all its subkeys.
.DESCRIPTION
    Deletes a registry key and all its contents recursively.
.PARAMETER KeyPath
    The full path to the registry key to remove.
.EXAMPLE
    Remove-RegistryKey -KeyPath "HKLM:\SOFTWARE\MyApp"
.NOTES
    This action is irreversible. Use with caution.
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$KeyPath
)
    
    try {
        if (Test-RegistryKey -KeyPath $KeyPath) {
            Remove-Item -Path $KeyPath -Recurse -Force
            Write-Host "Registry key '$KeyPath' removed successfully" -ForegroundColor Green
        } else {
            Write-Warning "Registry key '$KeyPath' does not exist"
        }
    }
    catch {
        Write-Error "Failed to remove registry key '$KeyPath': $_"
    }
}

# Function to create a registry key
function New-RegistryKey {
    <#
    .SYNOPSIS
        Creates a new registry key.
    .DESCRIPTION
        Creates a new registry key with optional force flag.
    .PARAMETER KeyPath
        The full path to the registry key to create.
    .PARAMETER Force
        Overwrites the key if it already exists.
    .EXAMPLE
        New-RegistryKey -KeyPath "HKLM:\SOFTWARE\MyApp\Settings"
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$KeyPath,
        [switch]$Force
    )
    
    try {
        if (Test-RegistryKey -KeyPath $KeyPath) {
            if ($Force) {
                Write-Host "Registry key '$KeyPath' already exists (using -Force)" -ForegroundColor Yellow
            } else {
                Write-Warning "Registry key '$KeyPath' already exists"
                return
            }
        }
        
        New-Item -Path $KeyPath -Force:$Force | Out-Null
        Write-Host "Registry key '$KeyPath' created successfully" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to create registry key '$KeyPath': $_"
    }
}

# Function to export registry key
function Export-RegistryKey {
    <#
    .SYNOPSIS
        Exports a registry key to a .reg file.
    .DESCRIPTION
        Creates a backup of a registry key and its values to a .reg file.
    .PARAMETER KeyPath
        The full path to the registry key to export.
    .PARAMETER ExportPath
        The path where the .reg file will be saved.
    .EXAMPLE
        Export-RegistryKey -KeyPath "HKLM:\SOFTWARE\MyApp" -ExportPath "C:\backup\myapp.reg"
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$KeyPath,
        [Parameter(Mandatory=$true)]
        [string]$ExportPath
    )
    
    try {
        if (-not (Test-RegistryKey -KeyPath $KeyPath)) {
            Write-Error "Registry key '$KeyPath' does not exist"
            return
        }
        
        $regPath = $KeyPath -replace ":", ""
        reg export $regPath $ExportPath /y
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Registry key exported to '$ExportPath' successfully" -ForegroundColor Green
        } else {
            Write-Error "Failed to export registry key"
        }
    }
    catch {
        Write-Error "Failed to export registry key: $_"
    }
}

# Function to import registry file
function Import-RegistryFile {
    <#
    .SYNOPSIS
        Imports a .reg file into the registry.
    .DESCRIPTION
        Imports registry settings from a .reg file.
    .PARAMETER ImportPath
        The path to the .reg file to import.
    .EXAMPLE
        Import-RegistryFile -ImportPath "C:\backup\myapp.reg"
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$ImportPath
    )
    
    try {
        if (-not (Test-Path -Path $ImportPath)) {
            Write-Error "Registry file '$ImportPath' does not exist"
            return
        }
        
        reg import $ImportPath
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Registry file imported successfully" -ForegroundColor Green
        } else {
            Write-Error "Failed to import registry file"
        }
    }
    catch {
        Write-Error "Failed to import registry file: $_"
    }
}

# Function to find registry values
function Find-RegistryValue {
    <#
    .SYNOPSIS
        Finds registry values by name or data.
    .DESCRIPTION
        Searches through registry keys for values matching the search criteria.
    .PARAMETER SearchTerm
        The term to search for in value names or data.
    .PARAMETER KeyPath
        The registry key path to start searching from.
    .PARAMETER SearchData
        Search in value data as well as names.
    .EXAMPLE
        Find-RegistryValue -SearchTerm "MyApp" -KeyPath "HKLM:\SOFTWARE"
    .OUTPUTS
        PSCustomObject[]
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$SearchTerm,
        [string]$KeyPath = "HKLM:\SOFTWARE",
        [switch]$SearchData
    )
    
    function Find-RegistryRecursive {
        param($Path, $Term, $SearchInData)
        
        $results = @()
        
        try {
            $key = Get-Item -Path $Path -ErrorAction SilentlyContinue
            if ($key) {
                # Search in value names
                $values = Get-ItemProperty -Path $Path -ErrorAction SilentlyContinue
                foreach ($valueName in $key.GetValueNames()) {
                    if ($valueName -like "*$Term*") {
                        $results += [PSCustomObject]@{
                            KeyPath   = $Path
                            ValueName = $valueName
                            ValueData = $values.$valueName
                            Type      = "ValueName"
                        }
                    }
                    
                    # Search in value data if requested
                    if ($SearchInData) {
                        $valueData = $values.$valueName
                        if ($valueData -like "*$Term*") {
                            $results += [PSCustomObject]@{
                                KeyPath   = $Path
                                ValueName = $valueName
                                ValueData = $valueData
                                Type      = "ValueData"
                            }
                        }
                    }
                }
                
                # Search in subkeys
                $subKeys = Get-ChildItem -Path $Path -ErrorAction SilentlyContinue
                foreach ($subKey in $subKeys) {
                    $results += Find-RegistryRecursive -Path $subKey.PSPath -Term $Term -SearchInData $SearchInData
                }
            }
        }
        catch {
            Write-Verbose "Error accessing registry key: $_"
        }
        
        return $results
    }
    
    return Find-RegistryRecursive -Path $KeyPath -Term $SearchTerm -SearchInData $SearchData
}

# Export the module members
Export-ModuleMember -Function Test-RegistryKey, Test-RegistryValue, Get-RegistryValue, Set-RegistryValue, Remove-RegistryValue, Remove-RegistryKey, New-RegistryKey, Export-RegistryKey, Import-RegistryFile, Find-RegistryValue -Verbose:$false