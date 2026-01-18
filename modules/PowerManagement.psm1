<#
.SYNOPSIS
    Power management functions for Windows power schemes and settings.
.DESCRIPTION
    Provides functions for managing power schemes, power settings, Windows 11 Power Mode,
    and retrieving power-related information.
.NOTES
    File Name      : PowerManagement.psm1
    Author         : System Administrator
    Prerequisite   : PowerShell 5.1 or later
#>

# Function to get all available power schemes
function Get-PowerSchemes {
    <#
    .SYNOPSIS
        Lists all available power schemes.
    .DESCRIPTION
        Returns a list of power schemes with their GUIDs and friendly names.
    .EXAMPLE
        $schemes = Get-PowerSchemes
        $schemes | Format-Table -AutoSize
    .OUTPUTS
        PSCustomObject[]
    #>
    $output = powercfg /list
    $schemes = @()
    
    foreach ($line in $output) {
        if ($line -match 'Power Scheme GUID:\s+([a-f0-9-]+)\s+\(([^)]+)\)\s+\*?') {
            $schemes += [PSCustomObject]@{
                GUID  = $matches[1]
                Name  = $matches[2]
                Active = $line -match '\*$'
            }
        }
    }
    
    return $schemes
}

# Function to get the active power scheme
function Get-ActivePowerScheme {
    <#
    .SYNOPSIS
        Gets the currently active power scheme.
    .DESCRIPTION
        Returns the active power scheme with its GUID and name.
    .EXAMPLE
        $active = Get-ActivePowerScheme
        Write-Host "Current scheme: $($active.Name)"
    .OUTPUTS
        PSCustomObject
    #>
    $schemes = Get-PowerSchemes
    return $schemes | Where-Object { $_.Active } | Select-Object -First 1
}

# Function to set a power scheme by GUID
function Set-PowerScheme {
<#
.SYNOPSIS
    Sets a power scheme as active.
.DESCRIPTION
    Activates a power scheme by its GUID.
.PARAMETER SchemeGUID
    The GUID of the power scheme to activate.
.EXAMPLE
    Set-PowerScheme -SchemeGUID "381b4222-f694-41f0-9685-ff5bb260df2e"
.NOTES
    Requires administrative privileges.
#>
param(
    [Parameter(Mandatory=$true)]
    [ValidatePattern('^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$')]
    [string]$SchemeGUID
)
    
    try {
        $result = powercfg /setactive $SchemeGUID
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Power scheme activated successfully" -ForegroundColor Green
        } else {
            Write-Error "Failed to activate power scheme"
        }
    }
    catch {
        Write-Error "Error setting power scheme: $_"
    }
}

# Function to get Windows 11 Power Mode
function Get-Windows11PowerMode {
    <#
    .SYNOPSIS
        Gets the current Windows 11 Power Mode setting.
    .DESCRIPTION
        Retrieves the current Windows 11 Power Mode (0=Recommended, 1=Better Performance, 2=Best Performance)
        from the registry for both AC and DC power states.
    .EXAMPLE
        $powerMode = Get-Windows11PowerMode
        Write-Host "Current power mode: $($powerMode.CurrentModeName)"
    .OUTPUTS
        PSCustomObject
    #>
    $registryPaths = @{
        AC = "HKCU:\Software\Microsoft\Windows\CurrentVersion\PowerSchemes\ActiveOverlayAcDc\OverlayAc"
        DC = "HKCU:\Software\Microsoft\Windows\CurrentVersion\PowerSchemes\ActiveOverlayAcDc\OverlayDc"
    }
    
    $result = [PSCustomObject]@{
        ACMode = $null
        DCMode = $null
        CurrentModeName = "Unknown"
        ACModes = @{
            0 = "Recommended"
            1 = "Better Performance"
            2 = "Best Performance"
        }
    }
    
    try {
        # Get AC power mode
        if (Test-Path $registryPaths.AC) {
            $acValue = Get-ItemProperty -Path $registryPaths.AC -Name "OverlayScheme" -ErrorAction SilentlyContinue
            if ($acValue -and $acValue.OverlayScheme -ne $null) {
                $result.ACMode = [int]$acValue.OverlayScheme
            }
        }
        
        # Get DC power mode
        if (Test-Path $registryPaths.DC) {
            $dcValue = Get-ItemProperty -Path $registryPaths.DC -Name "OverlayScheme" -ErrorAction SilentlyContinue
            if ($dcValue -and $dcValue.OverlayScheme -ne $null) {
                $result.DCMode = [int]$dcValue.OverlayScheme
            }
        }
        
        # Determine current mode based on power source
        $batteryInfo = Get-BatteryInfo
        if ($batteryInfo -and (-not $batteryInfo.PowerOnline)) {
            # On battery power (DC)
            $dcModeKey = [string]$result.DCMode
            if ($result.ACModes.ContainsKey($dcModeKey)) {
                $result.CurrentModeName = $result.ACModes[$dcModeKey]
            } else {
                $result.CurrentModeName = "Unknown"
            }
        } else {
            # On AC power
            $acModeKey = [string]$result.ACMode
            if ($result.ACModes.ContainsKey($acModeKey)) {
                $result.CurrentModeName = $result.ACModes[$acModeKey]
            } else {
                $result.CurrentModeName = "Unknown"
            }
        }
        
    } catch {
        Write-Error "Failed to get Windows 11 Power Mode: $_"
    }
    
    return $result
}

# Function to set Windows 11 Power Mode
function Set-Windows11PowerMode {
    <#
    .SYNOPSIS
        Sets the Windows 11 Power Mode.
    .DESCRIPTION
        Configures Windows 11 Power Mode setting (0=Recommended, 1=Better Performance, 2=Best Performance)
        for both AC and DC power states.
    .PARAMETER Mode
        The power mode to set (0, 1, or 2).
    .PARAMETER ApplyTo
        Which power states to apply to: "AC", "DC", or "Both" (default).
    .EXAMPLE
        Set-Windows11PowerMode -Mode 2
        Set-Windows11PowerMode -Mode 1 -ApplyTo "DC"
    #>
    param(
        [Parameter(Mandatory=$true)]
        [ValidateRange(0, 2)]
        [int]$Mode,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("AC", "DC", "Both")]
        [string]$ApplyTo = "Both"
    )
    
    $registryPaths = @{
        AC = "HKCU:\Software\Microsoft\Windows\CurrentVersion\PowerSchemes\ActiveOverlayAcDc\OverlayAc"
        DC = "HKCU:\Software\Microsoft\Windows\CurrentVersion\PowerSchemes\ActiveOverlayAcDc\OverlayDc"
    }
    
    $modeNames = @{
        0 = "Recommended"
        1 = "Better Performance"
        2 = "Best Performance"
    }
    
    try {
        # Ensure registry paths exist
        foreach ($pathType in $registryPaths.Keys) {
            if ($ApplyTo -ne "Both" -and $pathType -ne $ApplyTo) {
                continue
            }
            
            $path = $registryPaths[$pathType]
            if (-not (Test-Path $path)) {
                New-Item -Path $path -Force | Out-Null
            }
            
            # Set the power mode
            Set-ItemProperty -Path $path -Name "OverlayScheme" -Value $Mode -Type DWord -Force
        }
        
        Write-Host "Power mode set to: $($modeNames[$Mode])" -ForegroundColor Green
        
        # Apply changes
        $activeScheme = Get-ActivePowerScheme
        if ($activeScheme) {
            Set-PowerScheme -SchemeGUID $activeScheme.GUID
        }
        
    } catch {
        Write-Error "Failed to set Windows 11 Power Mode: $_"
    }
}

# Function to switch Windows 11 Power Mode
function Switch-Windows11PowerMode {
    <#
    .SYNOPSIS
        Switches between Windows 11 Power Modes.
    .DESCRIPTION
        Cycles through the three Windows 11 Power Modes: Recommended (0), Better Performance (1), Best Performance (2).
    .EXAMPLE
        Switch-Windows11PowerMode
    .OUTPUTS
        PSCustomObject
    #>
    $currentMode = Get-Windows11PowerMode
    
    if ($currentMode.CurrentModeName -eq "Unknown") {
        Write-Warning "Current power mode could not be determined. Setting to Recommended mode."
        Set-Windows11PowerMode -Mode 0
        return Get-Windows11PowerMode
    }
    
    # Determine next mode (cycle through 0, 1, 2)
    $batteryInfo = Get-BatteryInfo
    $currentValue = if ($batteryInfo -and (-not $batteryInfo.PowerOnline)) {
        $currentMode.DCMode
    } else {
        $currentMode.ACMode
    }
    
    $nextMode = ($currentValue + 1) % 3
    
    # Set the new mode
    Set-Windows11PowerMode -Mode $nextMode
    
    return Get-Windows11PowerMode
}

# Function to get power scheme GUID by name
function Get-PowerSchemeByName {
<#
.SYNOPSIS
    Gets a power scheme by its name.
.DESCRIPTION
    Returns the power scheme with the specified name or pattern.
.PARAMETER Name
    The name or pattern to search for.
.PARAMETER ExactMatch
    Require exact name match.
.EXAMPLE
    $scheme = Get-PowerSchemeByName -Name "High performance"
.OUTPUTS
    PSCustomObject
.NOTES
    Case-insensitive search by default.
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$Name,
    [switch]$ExactMatch
)
    
    $schemes = Get-PowerSchemes
    
    if ($ExactMatch) {
        return $schemes | Where-Object { $_.Name -eq $Name } | Select-Object -First 1
    } else {
        return $schemes | Where-Object { $_.Name -like "*$Name*" } | Select-Object -First 1
    }
}

# Function to get power setting value
function Get-PowerSetting {
<#
.SYNOPSIS
    Gets the value of a power setting.
.DESCRIPTION
    Retrieves the current value of a specific power setting.
.PARAMETER SettingGUID
    The GUID of the power setting.
.PARAMETER PowerSchemeGUID
    Optional. The GUID of the power scheme to query (defaults to active scheme).
.EXAMPLE
    $value = Get-PowerSetting -SettingGUID "238c9fa8-0aad-41ed-83f4-97be242c8f20"
.OUTPUTS
    PSCustomObject
.NOTES
    Returns null if the setting cannot be retrieved.
#>
param(
    [Parameter(Mandatory=$true)]
    [ValidatePattern('^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$')]
    [string]$SettingGUID,
    [ValidatePattern('^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$')]
    [string]$PowerSchemeGUID = ""
)
    
    if ([string]::IsNullOrEmpty($PowerSchemeGUID)) {
        $PowerSchemeGUID = (Get-ActivePowerScheme).GUID
    }
    
    try {
        $output = powercfg /query $PowerSchemeGUID $SettingGUID
        
        $result = [PSCustomObject]@{
            SettingGUID = $SettingGUID
            PowerSchemeGUID = $PowerSchemeGUID
            ACValue = $null
            DCValue = $null
            RawOutput = $output
        }
        
        # Parse the output for AC and DC values
        foreach ($line in $output) {
            if ($line -match 'Current AC Power Setting Index:\s+0x([0-9a-fA-F]+)') {
                $result.ACValue = Convert-HexStringToInt -HexString $matches[1]
            }
            if ($line -match 'Current DC Power Setting Index:\s+0x([0-9a-fA-F]+)') {
                $result.DCValue = Convert-HexStringToInt -HexString $matches[1]
            }
        }
        
        return $result
    }
    catch {
        Write-Error "Failed to get power setting: $_"
        return $null
    }
}

# Function to set power setting value
function Set-PowerSetting {
<#
.SYNOPSIS
    Sets the value of a power setting.
.DESCRIPTION
    Configures a specific power setting for both AC and DC power.
.PARAMETER SettingGUID
    The GUID of the power setting.
.PARAMETER Value
    The value to set (0 for never, minutes otherwise).
.PARAMETER PowerSchemeGUID
    Optional. The GUID of the power scheme to modify (defaults to active scheme).
.EXAMPLE
    Set-PowerSetting -SettingGUID "238c9fa8-0aad-41ed-83f4-97be242c8f20" -Value 0
.EXAMPLE
    Set-PowerSetting -SettingGUID "238c9fa8-0aad-41ed-83f4-97be242c8f20" -Value 900
.NOTES
    Requires administrative privileges.
#>
param(
    [Parameter(Mandatory=$true)]
    [ValidatePattern('^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$')]
    [string]$SettingGUID,
    [Parameter(Mandatory=$true)]
    [ValidateRange(0, 999999)]
    [int]$Value,
    [ValidatePattern('^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$')]
    [string]$PowerSchemeGUID = ""
)
    
    if ([string]::IsNullOrEmpty($PowerSchemeGUID)) {
        $PowerSchemeGUID = (Get-ActivePowerScheme).GUID
    }
    
    try {
        powercfg /setacvalueindex $PowerSchemeGUID sub_none $SettingGUID $Value
        powercfg /setdcvalueindex $PowerSchemeGUID sub_none $SettingGUID $Value
        powercfg /setactive $PowerSchemeGUID
        
        Write-Host "Power setting updated successfully" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to set power setting: $_"
    }
}

# Function to get power setting GUID by name
function Get-PowerSettingGUID {
    <#
    .SYNOPSIS
        Gets the GUID of a power setting by name.
    .DESCRIPTION
        Searches for a power setting and returns its GUID.
    .PARAMETER SettingName
        The name of the setting to search for.
    .EXAMPLE
        $guid = Get-PowerSettingGUID -SettingName "Sleep after"
    .OUTPUTS
        string
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$SettingName
    )
    
    try {
        $output = powercfg /query
        
        $currentScheme = ""
        $inSetting = $false
        $settingGUID = ""
        
        foreach ($line in $output) {
            if ($line -match 'Power Scheme GUID:\s+([a-f0-9-]+)') {
                $currentScheme = $matches[1]
            }
            
            if ($line -match '\s+Power Setting GUID:\s+([a-f0-9-]+)\s+\(([^)]+)\)') {
                $guid = $matches[1]
                $name = $matches[2]
                
                if ($name -like "*$SettingName*") {
                    return $guid
                }
            }
        }
        
        return $null
    }
    catch {
        Write-Error "Failed to find power setting GUID: $_"
        return $null
    }
}

# Function to get common power settings
function Get-PowerSettings {
    <#
    .SYNOPSIS
        Gets common power settings for the current scheme.
    .DESCRIPTION
        Returns a collection of common power settings and their current values.
    .PARAMETER PowerSchemeGUID
        Optional. The GUID of the power scheme to query (defaults to active scheme).
    .EXAMPLE
        $settings = Get-PowerSettings
        $settings | Format-Table -AutoSize
    .OUTPUTS
        PSCustomObject[]
    #>
    param(
        [string]$PowerSchemeGUID = ""
    )
    
    if ([string]::IsNullOrEmpty($PowerSchemeGUID)) {
        $PowerSchemeGUID = (Get-ActivePowerScheme).GUID
    }
    
    $commonSettings = @(
        @{Name = "Sleep after"; GUID = "29f6c1db-86da-48c5-9fdb-f2b67b1f44da"},
        @{Name = "Hibernate after"; GUID = "9d7815a6-7ee4-497e-8888-515a05f02364"},
        @{Name = "Turn off display after"; GUID = "3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e"},
        @{Name = "Dim display after"; GUID = "17aaa29b-8b43-4b94-aafe-35f64daaf1ee"}
    )
    
    $results = @()
    
    foreach ($setting in $commonSettings) {
        $value = Get-PowerSetting -SettingGUID $setting.GUID -PowerSchemeGUID $PowerSchemeGUID
        
        if ($value) {
            $results += [PSCustomObject]@{
                SettingName = $setting.Name
                SettingGUID = $setting.GUID
                ACValue = if ($value.ACValue -eq 0) { "Never" } else { "$($value.ACValue) minutes" }
                DCValue = if ($value.DCValue -eq 0) { "Never" } else { "$($value.DCValue) minutes" }
                RawACValue = $value.ACValue
                RawDCValue = $value.DCValue
            }
        }
    }
    
    return $results
}

# Function to get battery information
function Get-BatteryInfo {
    <#
    .SYNOPSIS
        Gets battery status and information.
    .DESCRIPTION
        Returns battery charge level, charging status, and estimated runtime.
    .EXAMPLE
        $battery = Get-BatteryInfo
        Write-Host "Battery: $($battery.ChargeLevel)% - $($battery.Status)"
    .OUTPUTS
        PSCustomObject
    #>
    try {
        $battery = Get-CimInstance -ClassName Win32_Battery
        
        if ($battery) {
            # Use Win32_Battery's PowerOnline property instead of non-existent Win32_PowerPlan
            $powerOnline = $battery.BatteryStatus -eq 2 -or $battery.BatteryStatus -eq 6
            
            return [PSCustomObject]@{
                ChargeLevel = $battery.EstimatedChargeRemaining
                Status      = $battery.BatteryStatus
                EstimatedRuntime = $battery.EstimatedRunTime
                PowerOnline = $powerOnline
                BatteryHealth = $battery.EstimatedChargeRemaining
                BatteryType = $battery.Description
            }
        } else {
            Write-Verbose "No battery found - system might be a desktop"
            return $null
        }
    }
    catch {
        Write-Error "Failed to get battery information: $_"
        return $null
    }
}

# Function to duplicate power scheme
function Copy-PowerScheme {
    <#
    .SYNOPSIS
        Creates a copy of an existing power scheme.
    .DESCRIPTION
        Duplicates a power scheme with a new name.
    .PARAMETER SourceSchemeGUID
        The GUID of the source power scheme.
    .PARAMETER NewName
        The name for the new power scheme.
    .EXAMPLE
        $newScheme = Copy-PowerScheme -SourceSchemeGUID "381b4222-f694-41f0-9685-ff5bb260df2e" -NewName "My Custom Scheme"
    .OUTPUTS
        PSCustomObject
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$SourceSchemeGUID,
        [Parameter(Mandatory=$true)]
        [string]$NewName
    )
    
    try {
        $output = powercfg /duplicatescheme $SourceSchemeGUID
        if ($output -match 'Power Scheme GUID:\s+([a-f0-9-]+)') {
            $newGUID = $matches[1]
            powercfg /changename $newGUID $NewName
            
            return [PSCustomObject]@{
                GUID = $newGUID
                Name = $NewName
                SourceGUID = $SourceSchemeGUID
            }
        }
        
        Write-Error "Failed to duplicate power scheme"
        return $null
    }
    catch {
        Write-Error "Failed to copy power scheme: $_"
        return $null
    }
}

# Function to delete power scheme
function Remove-PowerScheme {
    <#
    .SYNOPSIS
        Deletes a power scheme.
    .DESCRIPTION
        Removes a power scheme by its GUID.
    .PARAMETER SchemeGUID
        The GUID of the power scheme to delete.
    .EXAMPLE
        Remove-PowerScheme -SchemeGUID "a1841308-3541-4fab-bc81-f71556f20b4a"
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$SchemeGUID
    )
    
    try {
        $result = powercfg /delete $SchemeGUID
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Power scheme deleted successfully" -ForegroundColor Green
        } else {
            Write-Error "Failed to delete power scheme"
        }
    }
    catch {
        Write-Error "Failed to delete power scheme: $_"
    }
}

# Function to safely convert hex string to integer
function Convert-HexStringToInt {
    <#
    .SYNOPSIS
        Safely converts a hex string to integer, handling leading zeros.
    .DESCRIPTION
        Converts hex strings like "0000012c" to integers, handling edge cases.
    .PARAMETER HexString
        The hex string to convert.
    .EXAMPLE
        $value = Convert-HexStringToInt -HexString "0000012c"
    .OUTPUTS
        System.Int32
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$HexString
    )
    
    try {
        # Remove leading zeros and 0x prefix
        $cleanHex = $HexString -replace '^0x', '' -replace '^0+', ''
        if ([string]::IsNullOrEmpty($cleanHex)) { $cleanHex = '0' }
        
        return [Convert]::ToInt32($cleanHex, 16)
    } catch {
        Write-Error "Failed to convert hex string '$HexString' to integer: $_"
        return 0
    }
}

# Export the module members
Export-ModuleMember -Function Get-PowerSchemes, Get-ActivePowerScheme, Set-PowerScheme, Get-PowerSchemeByName, Get-PowerSetting, Set-PowerSetting, Get-PowerSettingGUID, Get-PowerSettings, Get-BatteryInfo, Copy-PowerScheme, Remove-PowerScheme, Convert-HexStringToInt, Get-Windows11PowerMode, Set-Windows11PowerMode, Switch-Windows11PowerMode