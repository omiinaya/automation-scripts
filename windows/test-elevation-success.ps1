<#
.SYNOPSIS
    Simple test script to verify successful elevation behavior.
.DESCRIPTION
    This script tests that successful elevation closes automatically.
#>

# Import the WindowsUtils module
Import-Module "$PSScriptRoot/modules/WindowsUtils.psm1" -Force

Write-Host "Testing Successful Elevation" -ForegroundColor Green
Write-Host "=============================" -ForegroundColor Green
Write-Host "This script should run and close automatically when successful." -ForegroundColor Cyan

# Test basic elevation
Request-Elevation

Write-Host "If you see this, elevation was not required or failed." -ForegroundColor Yellow