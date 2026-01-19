# Toggle "Show thumbnails instead of icons" setting
# This controls the checkbox in Performance Options > Visual Effects
# Controls whether file explorer shows thumbnails or icons only

# Function to pause on error
function Wait-OnError {
    param(
        [string]$ErrorMessage
    )
    Write-Host "`nERROR: $ErrorMessage" -ForegroundColor Red
    Write-Host "Press Enter to close this window..." -ForegroundColor Yellow
    Read-Host
}

# Import the Windows modules
$modulePath = Join-Path $PSScriptRoot "..\..\..\modules\ModuleIndex.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

try {
    # The thumbnails/icons setting is controlled by IconsOnly
    # This is the actual registry value that Performance Options UI modifies
    # Note: 0 = thumbnails, 1 = icons only (inverted logic)
    $registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    $valueName = "IconsOnly"
    
    # Ensure the registry path exists
    if (-not (Test-Path $registryPath)) {
        Write-StatusMessage -Message "Creating registry path: $registryPath" -Type Info
        New-Item -Path $registryPath -Force | Out-Null
    }
    
    # Get current value (default to 0/thumbnails if not set)
    $currentValue = Get-ItemProperty -Path $registryPath -Name $valueName -ErrorAction SilentlyContinue | Select-Object -ExpandProperty $valueName
    
    if ($null -eq $currentValue) {
        # If value doesn't exist, assume thumbnails are enabled (Windows default)
        Write-StatusMessage -Message "Registry value not found, assuming thumbnails enabled (Windows default)" -Type Info
        $currentValue = 0
    }
    
    # Display current state
    $currentState = if ($currentValue -eq 0) { "thumbnails" } else { "icons only" }
    Write-StatusMessage -Message "Current state: $currentState" -Type Info
    
    # Toggle the setting
    # 0 = Enabled (show thumbnails)
    # 1 = Disabled (show icons only)
    $newValue = if ($currentValue -eq 0) { 1 } else { 0 }
    $newState = if ($newValue -eq 0) { "thumbnails" } else { "icons only" }
    
    # Apply the new setting
    Write-StatusMessage -Message "Setting IconsOnly to $newValue ($newState)..." -Type Info
    Set-ItemProperty -Path $registryPath -Name $valueName -Value $newValue -Type DWord
    
    # Verify the change was applied
    $verifyValue = Get-ItemProperty -Path $registryPath -Name $valueName -ErrorAction Stop | Select-Object -ExpandProperty $valueName
    if ($verifyValue -ne $newValue) {
        throw "Registry value verification failed. Expected: $newValue, Got: $verifyValue"
    }
    
    # Refresh Explorer to apply changes immediately
    Write-StatusMessage -Message "Refreshing Explorer settings..." -Type Info
    Invoke-ExplorerRefresh
    
    Write-StatusMessage -Message "Show thumbnails instead of icons: $newState" -Type Success
    Write-StatusMessage -Message "Changes applied immediately - no Explorer restart required" -Type Info
    
} catch {
    Wait-OnError -ErrorMessage "Failed to toggle thumbnails/icons setting: $($_.Exception.Message)"
}