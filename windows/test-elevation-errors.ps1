<#
.SYNOPSIS
    Test script to verify error handling in elevated PowerShell windows.
.DESCRIPTION
    This script tests various error scenarios to ensure proper error display
    and user interaction in elevated contexts.
#>

# Import the WindowsUtils module
Import-Module "$PSScriptRoot/modules/WindowsUtils.psm1" -Force

Write-Host "Testing Elevation Error Handling" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

# Test 1: Force an error scenario to test elevation
Write-Host "`nTest 1: Testing script with intentional error..." -ForegroundColor Yellow

# Create a temporary script that will cause an error
$testErrorScript = [System.IO.Path]::GetTempFileName() + ".ps1"
$errorScriptContent = @"
Write-Host "This is a test script that will generate an error..." -ForegroundColor Cyan
Start-Sleep -Seconds 1
Write-Error "This is an intentional error for testing purposes"
Write-Host "This message should still appear after the error" -ForegroundColor Green
exit 1
"@

$errorScriptContent | Out-File -FilePath $testErrorScript -Encoding UTF8

Write-Host "Created test script at: $testErrorScript" -ForegroundColor Gray

# Test 2: Try to run the script with elevation
Write-Host "`nTest 2: Attempting to run error-generating script with elevation..." -ForegroundColor Yellow
Write-Host "You should see a UAC prompt. Accept it to test error display." -ForegroundColor Yellow

# Temporarily modify the script path to use our test script
$originalInvocation = $MyInvocation
$MyInvocation | Add-Member -NotePropertyName ScriptName -NotePropertyValue $testErrorScript -Force

# Test the elevation - this should show the error properly
Request-Elevation

# Clean up
if (Test-Path $testErrorScript) {
    Remove-Item $testErrorScript -Force
}

Write-Host "Test completed. If you saw proper error display, the fix is working!" -ForegroundColor Green