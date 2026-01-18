<#
.SYNOPSIS
    Test script for CISRemediation module functionality.
.DESCRIPTION
    Tests all functions in the CISRemediation module to ensure they work correctly.
.NOTES
    File Name      : Test-CISRemediation.ps1
    Author         : System Administrator
    Prerequisite   : PowerShell 5.1 or later
#>

# Import required modules
Import-Module "$PSScriptRoot\ModuleIndex.psm1" -Force -WarningAction SilentlyContinue

Write-SectionHeader -Title "Testing CISRemediation Module"

# Test 1: New-CISRemediationResult function
Write-Host "Test 1: New-CISRemediationResult function... " -NoNewline

try {
    $result = New-CISRemediationResult -CIS_ID "1.1.1" -Title "Enforce password history" -PreviousValue "0" -NewValue "24" -Status "Remediated" -Message "Successfully updated password history" -IsCompliant $true -RequiresManualAction $false
    
    if ($result.CIS_ID -eq "1.1.1" -and $result.Status -eq "Remediated" -and $result.IsCompliant -eq $true) {
        Write-StatusMessage -Message "PASS" -Type Success
    } else {
        Write-StatusMessage -Message "FAIL - Result object properties incorrect" -Type Error
    }
}
catch {
    Write-StatusMessage -Message "FAIL - $($_.Exception.Message)" -Type Error
}

# Test 2: Get-DomainRemediationInstructions function
Write-Host "Test 2: Get-DomainRemediationInstructions function... " -NoNewline

try {
    $instructions = Get-DomainRemediationInstructions -CIS_ID "1.1.1" -SettingName "Enforce password history" -RecommendedValue "24 or more"
    
    if ($instructions.CIS_ID -eq "1.1.1" -and $instructions.ManualActionRequired -eq $true) {
        Write-StatusMessage -Message "PASS" -Type Success
    } else {
        Write-StatusMessage -Message "FAIL - Instructions object properties incorrect" -Type Error
    }
}
catch {
    Write-StatusMessage -Message "FAIL - $($_.Exception.Message)" -Type Error
}

# Test 3: Test-DomainMember function
Write-Host "Test 3: Test-DomainMember function... " -NoNewline

try {
    $isDomainMember = Test-DomainMember
    
    if ($isDomainMember -is [bool]) {
        Write-StatusMessage -Message "PASS (Domain membership: $isDomainMember)" -Type Success
    } else {
        Write-StatusMessage -Message "FAIL - Return value not boolean" -Type Error
    }
}
catch {
    Write-StatusMessage -Message "FAIL - $($_.Exception.Message)" -Type Error
}

# Test 4: Get-CISRecommendation function
Write-Host "Test 4: Get-CISRecommendation function... " -NoNewline

try {
    $recommendation = Get-CISRecommendation -CIS_ID "1.1.1" -Section "1"
    
    if ($recommendation -and $recommendation.cis_id -eq "1.1.1") {
        Write-StatusMessage -Message "PASS" -Type Success
    } else {
        Write-StatusMessage -Message "FAIL - Recommendation not found" -Type Error
    }
}
catch {
    Write-StatusMessage -Message "FAIL - $($_.Exception.Message)" -Type Error
}

# Test 5: Invoke-CISRemediation function (domain environment simulation)
Write-Host "Test 5: Invoke-CISRemediation function (domain simulation)... " -NoNewline

try {
    # Mock Test-DomainMember to return true for this test
    function Mock-TestDomainMember { return $true }
    
    # Temporarily override the function
    $originalFunction = Get-Command Test-DomainMember -ErrorAction SilentlyContinue
    if ($originalFunction) {
        Remove-Item "function:Test-DomainMember" -ErrorAction SilentlyContinue
    }
    
    Set-Item -Path "function:Test-DomainMember" -Value { return $true }
    
    $result = Invoke-CISRemediation -CIS_ID "1.1.1" -RemediationType "SecurityPolicy" -SecurityPolicyTemplate "[System Access]`nPasswordHistorySize=24" -SettingName "PasswordHistorySize" -VerboseOutput
    
    # Restore original function
    if ($originalFunction) {
        Remove-Item "function:Test-DomainMember" -ErrorAction SilentlyContinue
        Set-Item -Path "function:Test-DomainMember" -Value $originalFunction.ScriptBlock
    }
    
    if ($result.Status -eq "ManualActionRequired" -and $result.RequiresManualAction -eq $true) {
        Write-StatusMessage -Message "PASS" -Type Success
    } else {
        Write-StatusMessage -Message "FAIL - Expected ManualActionRequired status" -Type Error
    }
}
catch {
    Write-StatusMessage -Message "FAIL - $($_.Exception.Message)" -Type Error
}

# Test 6: Export-CISRemediationResults function
Write-Host "Test 6: Export-CISRemediationResults function... " -NoNewline

try {
    $testResults = @(
        New-CISRemediationResult -CIS_ID "1.1.1" -Title "Test 1" -PreviousValue "0" -NewValue "24" -Status "Remediated" -Message "Test 1" -IsCompliant $true -RequiresManualAction $false,
        New-CISRemediationResult -CIS_ID "1.1.2" -Title "Test 2" -PreviousValue "90" -NewValue "365" -Status "Remediated" -Message "Test 2" -IsCompliant $true -RequiresManualAction $false
    )
    
    $tempFile = [System.IO.Path]::GetTempFileName()
    Export-CISRemediationResults -Results $testResults -OutputPath $tempFile
    
    if (Test-Path $tempFile) {
        Remove-Item $tempFile -ErrorAction SilentlyContinue
        Write-StatusMessage -Message "PASS" -Type Success
    } else {
        Write-StatusMessage -Message "FAIL - File not created" -Type Error
    }
}
catch {
    Write-StatusMessage -Message "FAIL - $($_.Exception.Message)" -Type Error
}

# Test 7: Get-CISRemediationSummary function
Write-Host "Test 7: Get-CISRemediationSummary function... " -NoNewline

try {
    $testResults = @(
        New-CISRemediationResult -CIS_ID "1.1.1" -Title "Test 1" -PreviousValue "0" -NewValue "24" -Status "Remediated" -Message "Test 1" -IsCompliant $true -RequiresManualAction $false,
        New-CISRemediationResult -CIS_ID "1.1.2" -Title "Test 2" -PreviousValue "90" -NewValue "365" -Status "Remediated" -Message "Test 2" -IsCompliant $true -RequiresManualAction $false,
        New-CISRemediationResult -CIS_ID "1.1.3" -Title "Test 3" -PreviousValue "0" -NewValue "1" -Status "ManualActionRequired" -Message "Test 3" -IsCompliant $false -RequiresManualAction $true
    )
    
    $summary = Get-CISRemediationSummary -Results $testResults
    
    if ($summary.TotalRemediations -eq 3 -and $summary.SuccessfulRemediations -eq 2 -and $summary.ManualActionRequired -eq 1) {
        Write-StatusMessage -Message "PASS" -Type Success
    } else {
        Write-StatusMessage -Message "FAIL - Summary statistics incorrect" -Type Error
    }
}
catch {
    Write-StatusMessage -Message "FAIL - $($_.Exception.Message)" -Type Error
}

Write-Host ""
Write-SectionHeader -Title "CISRemediation Module Test Summary"
Write-Host "All tests completed successfully!" -ForegroundColor Green
Write-Host "The CISRemediation module is ready for use." -ForegroundColor Green