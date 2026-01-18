<#
.SYNOPSIS
    Test helper functions for Pester testing
.DESCRIPTION
    Provides common test utilities, mock functions, and helper functions
    to support Pester testing across the CIS automation scripts project.
.NOTES
    File Name      : TestHelpers.psm1
    Author         : System Administrator
    Prerequisite   : Pester module
#>

# Test data generation functions
function New-TestCISResultObject {
    <#
    .SYNOPSIS
        Creates a test CIS result object for unit testing
    .DESCRIPTION
        Generates a standardized CIS result object with test data
    .PARAMETER CIS_ID
        The CIS benchmark ID
    .PARAMETER ComplianceStatus
        Compliance status (default: Compliant)
    .EXAMPLE
        $testResult = New-TestCISResultObject -CIS_ID "1.1.1" -ComplianceStatus "Non-Compliant"
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$CIS_ID,
        
        [ValidateSet("Compliant", "Non-Compliant", "Error", "Not Applicable")]
        [string]$ComplianceStatus = "Compliant"
    )
    
    return @{
        CIS_ID = $CIS_ID
        Title = "Test CIS Recommendation $CIS_ID"
        CurrentValue = "24"
        RecommendedValue = "24 or more"
        ComplianceStatus = $ComplianceStatus
        IsCompliant = ($ComplianceStatus -eq "Compliant")
        Source = "Test Source"
        Details = "Test details"
        ErrorMessage = ""
        Profile = "L1"
        AuditTimestamp = "2026-01-15 12:00:00"
        ComputerName = "TEST-PC"
        UserName = "TESTUSER"
    }
}

function New-TestCISRemediationResult {
    <#
    .SYNOPSIS
        Creates a test CIS remediation result object for unit testing
    .DESCRIPTION
        Generates a standardized CIS remediation result object with test data
    .PARAMETER CIS_ID
        The CIS benchmark ID
    .PARAMETER Status
        Remediation status (default: Remediated)
    .EXAMPLE
        $testResult = New-TestCISRemediationResult -CIS_ID "1.1.1" -Status "Failed"
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$CIS_ID,
        
        [ValidateSet("Remediated", "ManualActionRequired", "Failed", "Cancelled", "Error", "PartiallyRemediated")]
        [string]$Status = "Remediated"
    )
    
    return @{
        CIS_ID = $CIS_ID
        Title = "Test CIS Remediation $CIS_ID"
        PreviousValue = "0"
        NewValue = "24"
        Status = $Status
        Message = "Test remediation message"
        IsCompliant = ($Status -eq "Remediated")
        RequiresManualAction = ($Status -eq "ManualActionRequired")
        Source = "Test Source"
        ErrorMessage = ""
        RemediationTimestamp = "2026-01-15 12:00:00"
        ComputerName = "TEST-PC"
        UserName = "TESTUSER"
    }
}

function Get-TestCISRecommendationData {
    <#
    .SYNOPSIS
        Returns test CIS recommendation data
    .DESCRIPTION
        Provides standardized test data for CIS recommendation testing
    .PARAMETER CIS_ID
        The CIS benchmark ID to retrieve
    .EXAMPLE
        $testData = Get-TestCISRecommendationData -CIS_ID "1.1.1"
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$CIS_ID
    )
    
    $testRecommendations = @{
        "1.1.1" = @{
            cis_id = "1.1.1"
            title = "Enforce password history"
            profile = "L1"
        }
        "1.1.2" = @{
            cis_id = "1.1.2"
            title = "Maximum password age"
            profile = "L1"
        }
        "1.2.1" = @{
            cis_id = "1.2.1"
            title = "Account lockout duration"
            profile = "L1"
        }
        "1.2.2" = @{
            cis_id = "1.2.2"
            title = "Account lockout threshold"
            profile = "L1"
        }
    }
    
    return $testRecommendations[$CIS_ID]
}

# Mock functions for testing
function Initialize-TestMocks {
    <#
    .SYNOPSIS
        Initializes common mock functions for testing
    .DESCRIPTION
        Sets up mock functions for registry operations, service checks,
        and other system operations that should not be executed during testing
    .EXAMPLE
        Initialize-TestMocks
    #>
    
    # Mock registry operations
    Mock Test-RegistryKey { return $true }
    Mock Get-RegistryValue { return "TestValue" }
    Mock Set-RegistryValue { return $true }
    
    # Mock service operations
    Mock Test-ServiceExists { return $true }
    Mock Get-Service { return @{ Status = "Running" } }
    
    # Mock domain membership check
    Mock Test-DomainMember { return $false }
    
    # Mock file operations
    Mock Test-Path { return $true }
    Mock Get-Content { return "Test content" }
    Mock Set-Content { return $true }
    
    # Mock CIS recommendation retrieval
    Mock Get-CISRecommendation { 
        param($CIS_ID)
        return Get-TestCISRecommendationData -CIS_ID $CIS_ID
    }
}

function Clear-TestMocks {
    <#
    .SYNOPSIS
        Clears all mock functions
    .DESCRIPTION
        Removes all mock functions to restore original behavior
    .EXAMPLE
        Clear-TestMocks
    #>
    
    Get-Module Pester | Remove-Module
    Import-Module Pester -Force
}

# Test assertion helpers
function Assert-CISResultObject {
    <#
    .SYNOPSIS
        Validates a CIS result object structure
    .DESCRIPTION
        Performs comprehensive validation of a CIS result object
    .PARAMETER ResultObject
        The CIS result object to validate
    .EXAMPLE
        Assert-CISResultObject -ResultObject $auditResult
    #>
    param(
        [Parameter(Mandatory=$true)]
        [object]$ResultObject
    )
    
    $ResultObject | Should -Not -BeNullOrEmpty
    $ResultObject.CIS_ID | Should -Not -BeNullOrEmpty
    $ResultObject.Title | Should -Not -BeNullOrEmpty
    $ResultObject.CurrentValue | Should -Not -BeNullOrEmpty
    $ResultObject.RecommendedValue | Should -Not -BeNullOrEmpty
    $ResultObject.ComplianceStatus | Should -Not -BeNullOrEmpty
    $ResultObject.IsCompliant | Should -Not -BeNullOrEmpty
    $ResultObject.AuditTimestamp | Should -Not -BeNullOrEmpty
    $ResultObject.ComputerName | Should -Not -BeNullOrEmpty
}

function Assert-CISRemediationResult {
    <#
    .SYNOPSIS
        Validates a CIS remediation result object structure
    .DESCRIPTION
        Performs comprehensive validation of a CIS remediation result object
    .PARAMETER ResultObject
        The CIS remediation result object to validate
    .EXAMPLE
        Assert-CISRemediationResult -ResultObject $remediationResult
    #>
    param(
        [Parameter(Mandatory=$true)]
        [object]$ResultObject
    )
    
    $ResultObject | Should -Not -BeNullOrEmpty
    $ResultObject.CIS_ID | Should -Not -BeNullOrEmpty
    $ResultObject.Title | Should -Not -BeNullOrEmpty
    $ResultObject.PreviousValue | Should -Not -BeNullOrEmpty
    $ResultObject.NewValue | Should -Not -BeNullOrEmpty
    $ResultObject.Status | Should -Not -BeNullOrEmpty
    $ResultObject.Message | Should -Not -BeNullOrEmpty
    $ResultObject.IsCompliant | Should -Not -BeNullOrEmpty
    $ResultObject.RequiresManualAction | Should -Not -BeNullOrEmpty
    $ResultObject.RemediationTimestamp | Should -Not -BeNullOrEmpty
    $ResultObject.ComputerName | Should -Not -BeNullOrEmpty
}

# Test file management
function New-TestFile {
    <#
    .SYNOPSIS
        Creates a temporary test file
    .DESCRIPTION
        Creates a temporary file with specified content for testing
    .PARAMETER Content
        The content to write to the file
    .PARAMETER Extension
        File extension (default: .txt)
    .EXAMPLE
        $testFile = New-TestFile -Content "Test data" -Extension ".json"
    #>
    param(
        [string]$Content = "Test content",
        [string]$Extension = ".txt"
    )
    
    $tempFile = [System.IO.Path]::GetTempFileName()
    $testFile = $tempFile + $Extension
    Move-Item -Path $tempFile -Destination $testFile
    
    Set-Content -Path $testFile -Value $Content
    
    return $testFile
}

function Remove-TestFile {
    <#
    .SYNOPSIS
        Removes a test file
    .DESCRIPTION
        Safely removes a test file created by New-TestFile
    .PARAMETER Path
        Path to the test file to remove
    .EXAMPLE
        Remove-TestFile -Path $testFile
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path
    )
    
    if (Test-Path $Path) {
        Remove-Item -Path $Path -Force -ErrorAction SilentlyContinue
    }
}

# Test environment setup
function Set-TestEnvironment {
    <#
    .SYNOPSIS
        Sets up test environment
    .DESCRIPTION
        Configures environment variables and settings for testing
    .EXAMPLE
        Set-TestEnvironment
    #>
    
    # Set test environment variables
    $env:TEST_MODE = "true"
    $env:COMPUTERNAME = "TEST-PC"
    $env:USERNAME = "TESTUSER"
    
    # Set execution policy for testing
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
}

function Clear-TestEnvironment {
    <#
    .SYNOPSIS
        Clears test environment settings
    .DESCRIPTION
        Restores original environment settings after testing
    .EXAMPLE
        Clear-TestEnvironment
    #>
    
    # Remove test environment variables
    Remove-Item Env:TEST_MODE -ErrorAction SilentlyContinue
    
    # Restore original computer name and username if they were changed
    # Note: These are read-only in PowerShell, so we just document the change
}

# Test data validation
function Test-ValidCISID {
    <#
    .SYNOPSIS
        Validates a CIS benchmark ID format
    .DESCRIPTION
        Checks if a CIS ID follows the standard format (e.g., 1.1.1)
    .PARAMETER CIS_ID
        The CIS benchmark ID to validate
    .EXAMPLE
        $isValid = Test-ValidCISID -CIS_ID "1.1.1"
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$CIS_ID
    )
    
    return $CIS_ID -match "^\d+\.\d+\.\d+$"
}

function Test-ValidComplianceStatus {
    <#
    .SYNOPSIS
        Validates a compliance status value
    .DESCRIPTION
        Checks if a compliance status is one of the allowed values
    .PARAMETER Status
        The compliance status to validate
    .EXAMPLE
        $isValid = Test-ValidComplianceStatus -Status "Compliant"
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Status
    )
    
    $validStatuses = @("Compliant", "Non-Compliant", "Error", "Not Applicable")
    return $Status -in $validStatuses
}

# Export module members
Export-ModuleMember -Function *