# Comprehensive power settings exploration
Write-Host "Exploring Power Settings on Your System..." -ForegroundColor Yellow
Write-Host "===========================================" -ForegroundColor Yellow

# Get all power schemes
Write-Host "`nAvailable Power Schemes:" -ForegroundColor Green
try {
    $schemes = powercfg -list
    $schemes
} catch {
    Write-Host "Error getting power schemes: $($_.Exception.Message)" -ForegroundColor Red
}

# List all power settings subgroups
Write-Host "`nPower Settings Subgroups:" -ForegroundColor Green
try {
    $subgroups = powercfg -query
    if ($subgroups -like "*SUB_GROUP*") {
        $subgroups | Where-Object { $_ -like "*SUB_GROUP*" }
    } else {
        Write-Host "No subgroup information available in standard format" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Error getting subgroups: $($_.Exception.Message)" -ForegroundColor Red
}

# Search for processor-related settings
Write-Host "`nSearching for Processor/Power Settings:" -ForegroundColor Green
try {
    $allSettings = powercfg -query 2>&1
    $processorSettings = $allSettings | Select-String -Pattern "processor|power|cpu|core|park"
    if ($processorSettings) {
        $processorSettings
    } else {
        Write-Host "No processor/power related settings found in powercfg output" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Error searching for processor settings: $($_.Exception.Message)" -ForegroundColor Red
}

# Alternative approach: Check registry directly
Write-Host "`nChecking Registry for CPU Power Settings:" -ForegroundColor Green
$registryPaths = @(
    "HKLM:\SYSTEM\CurrentControlSet\Control\Power",
    "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings",
    "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power"
)

foreach ($path in $registryPaths) {
    if (Test-Path $path) {
        Write-Host "`nRegistry Path: $path" -ForegroundColor Cyan
        try {
            Get-ChildItem $path -ErrorAction SilentlyContinue | ForEach-Object {
                if ($_.Name -like "*processor*" -or $_.Name -like "*power*" -or $_.Name -like "*cpu*") {
                    Write-Host "  Found: $($_.Name)" -ForegroundColor White
                }
            }
        } catch {
            Write-Host "  Error accessing: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "Registry path not found: $path" -ForegroundColor Yellow
    }
}

# Check if specific CPU parking GUIDs exist
Write-Host "`nChecking Specific CPU Parking GUIDs:" -ForegroundColor Green
$cpuGuids = @(
    "54533251-82be-4824-96c1-47b60b740d00",  # CPU subgroup
    "0cc5b647-c1df-4637-891a-dec35c318583"   # CPU parking
)

foreach ($guid in $cpuGuids) {
    Write-Host "Testing GUID: $guid" -ForegroundColor Cyan
    try {
        $result = powercfg -query $guid 2>&1
        if ($result -like "*not found*" -or $LASTEXITCODE -ne 0) {
            Write-Host "  GUID not found or inaccessible" -ForegroundColor Red
        } else {
            Write-Host "  GUID exists:" -ForegroundColor Green
            $result | Select-Object -First 5
        }
    } catch {
        Write-Host "  Error testing GUID: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`nPress Enter to close..." -ForegroundColor Yellow
Read-Host