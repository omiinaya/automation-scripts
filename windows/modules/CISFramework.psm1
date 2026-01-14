<#
.SYNOPSIS
    CIS Audit Framework Module for Windows security compliance auditing.
.DESCRIPTION
    Provides standardized functions for CIS benchmark auditing with common patterns,
    result object creation, recommendation retrieval, and compliance testing.
.NOTES
    File Name      : CISFramework.psm1
    Author         : System Administrator
    Prerequisite   : PowerShell 5.1 or later
    Dependencies   : WindowsUtils, RegistryUtils, WindowsUI modules
#>

# Import required modules
Import-Module "$PSScriptRoot\WindowsUtils.psm1" -Force -WarningAction SilentlyContinue
Import-Module "$PSScriptRoot\RegistryUtils.psm1" -Force -WarningAction SilentlyContinue
Import-Module "$PSScriptRoot\WindowsUI.psm1" -Force -WarningAction SilentlyContinue

# Function to create standardized CIS audit result object
function New-CISResultObject {
    <#
    .SYNOPSIS
        Creates a standardized CIS audit result object.
    .DESCRIPTION
        Returns a consistent object structure for CIS audit results with all required properties.
    .PARAMETER CIS_ID
        The CIS benchmark ID (e.g., "1.1.1").
    .PARAMETER Title
        The title of the CIS recommendation.
    .PARAMETER CurrentValue
        The current value of the audited setting.
    .PARAMETER RecommendedValue
        The recommended value according to CIS benchmark.
    .PARAMETER ComplianceStatus
        The compliance status (Compliant, Non-Compliant, Error, Not Applicable).
    .PARAMETER Source
        The source of the audit data (Registry, Group Policy, etc.).
    .PARAMETER Details
        Additional details about the audit result.
    .PARAMETER ErrorMessage
        Error message if the audit failed.
    .PARAMETER Profile
        The CIS profile level (L1, L2).
    .EXAMPLE
        $result = New-CISResultObject -CIS_ID "1.1.1" -Title "Enforce password history" -CurrentValue "24" -RecommendedValue "24 or more" -ComplianceStatus "Compliant" -Source "Domain Policy"
    .OUTPUTS
        PSCustomObject
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$CIS_ID,
        
        [Parameter(Mandatory=$true)]
        [string]$Title,
        
        [Parameter(Mandatory=$true)]
        [object]$CurrentValue,
        
        [Parameter(Mandatory=$true)]
        [string]$RecommendedValue,
        
        [Parameter(Mandatory=$true)]
        [ValidateSet("Compliant", "Non-Compliant", "Error", "Not Applicable")]
        [string]$ComplianceStatus,
        
        [string]$Source = "Unknown",
        
        [string]$Details = "",
        
        [string]$ErrorMessage = "",
        
        [ValidateSet("L1", "L2")]
        [string]$Profile = "L1"
    )
    
    $auditTimestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $isCompliant = ($ComplianceStatus -eq "Compliant")
    
    return [PSCustomObject]@{
        CIS_ID = $CIS_ID
        Title = $Title
        CurrentValue = $CurrentValue
        RecommendedValue = $RecommendedValue
        ComplianceStatus = $ComplianceStatus
        IsCompliant = $isCompliant
        Source = $Source
        Details = $Details
        ErrorMessage = $ErrorMessage
        Profile = $Profile
        AuditTimestamp = $auditTimestamp
        ComputerName = $env:COMPUTERNAME
        UserName = $env:USERNAME
    }
}

# Function to retrieve CIS recommendation data from JSON
function Get-CISRecommendation {
    <#
    .SYNOPSIS
        Retrieves CIS recommendation data from JSON files.
    .DESCRIPTION
        Loads and returns CIS benchmark recommendation data from JSON files in the docs/json directory.
    .PARAMETER CIS_ID
        The CIS benchmark ID to retrieve (e.g., "1.1.1").
    .PARAMETER Section
        The CIS section number (1, 2, 5, 9, 17, 18, 19). If not specified, searches all sections.
    .PARAMETER JsonPath
        Custom path to JSON file. If not specified, uses default docs/json directory.
    .EXAMPLE
        $recommendation = Get-CISRecommendation -CIS_ID "1.1.1"
    .EXAMPLE
        $recommendation = Get-CISRecommendation -CIS_ID "1.1.1" -Section 1
    .OUTPUTS
        PSCustomObject
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$CIS_ID,
        
        [ValidateSet("1", "2", "5", "9", "17", "18", "19")]
        [string]$Section,
        
        [string]$JsonPath
    )
    
    try {
        # Determine JSON file path
        if ($JsonPath) {
            $jsonFilePath = $JsonPath
        } elseif ($Section) {
            $jsonFilePath = Join-Path $PSScriptRoot "..\..\docs\json\cis_section_$Section.json"
        } else {
            # Search all section files
            $sectionFiles = @("1", "2", "5", "9", "17", "18", "19")
            foreach ($sectionNum in $sectionFiles) {
                $testPath = Join-Path $PSScriptRoot "..\..\docs\json\cis_section_$sectionNum.json"
                if (Test-Path $testPath) {
                    $jsonContent = Get-Content $testPath -Raw | ConvertFrom-Json
                    $recommendation = $jsonContent | Where-Object { $_.cis_id -eq $CIS_ID }
                    if ($recommendation) {
                        return $recommendation
                    }
                }
            }
            return $null
        }
        
        # Validate JSON file path
        if (-not (Test-Path $jsonFilePath)) {
            Write-Warning "CIS JSON file not found: $jsonFilePath"
            return $null
        }
        
        # Load and parse JSON
        $jsonContent = Get-Content $jsonFilePath -Raw | ConvertFrom-Json
        
        # Find the specific recommendation
        $recommendation = $jsonContent | Where-Object { $_.cis_id -eq $CIS_ID }
        
        if (-not $recommendation) {
            Write-Warning "CIS recommendation '$CIS_ID' not found in $jsonFilePath"
            return $null
        }
        
        return $recommendation
    }
    catch {
        Write-Error "Failed to retrieve CIS recommendation '$CIS_ID': $_"
        return $null
    }
}

# Function to test CIS compliance with generic patterns
function Test-CISCompliance {
    <#
    .SYNOPSIS
        Tests compliance against CIS recommendations using generic patterns.
    .DESCRIPTION
        Provides common compliance testing patterns for registry values, group policy settings,
        and service configurations based on CIS recommendations.
    .PARAMETER CIS_ID
        The CIS benchmark ID to test.
    .PARAMETER CurrentValue
        The current value to test against the recommendation.
    .PARAMETER Recommendation
        The CIS recommendation object (from Get-CISRecommendation).
    .PARAMETER TestType
        The type of compliance test (RegistryValue, GroupPolicy, ServiceState, FilePermission).
    .PARAMETER RegistryPath
        Registry path for registry-based tests.
    .PARAMETER RegistryValueName
        Registry value name for registry-based tests.
    .PARAMETER ExpectedValue
        Expected value for direct comparison tests.
    .PARAMETER ComparisonOperator
        Comparison operator for value testing (eq, ne, gt, ge, lt, le).
    .EXAMPLE
        $compliant = Test-CISCompliance -CIS_ID "1.1.1" -CurrentValue 24 -ExpectedValue 24 -ComparisonOperator "ge"
    .EXAMPLE
        $compliant = Test-CISCompliance -CIS_ID "2.3.1.1" -RegistryPath "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer" -RegistryValueName "Start" -ExpectedValue 4
    .OUTPUTS
        System.Boolean
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$CIS_ID,
        
        [Parameter(Mandatory=$true)]
        [object]$CurrentValue,
        
        [object]$Recommendation,
        
        [ValidateSet("RegistryValue", "GroupPolicy", "ServiceState", "FilePermission", "DirectComparison")]
        [string]$TestType = "DirectComparison",
        
        [string]$RegistryPath,
        
        [string]$RegistryValueName,
        
        [object]$ExpectedValue,
        
        [ValidateSet("eq", "ne", "gt", "ge", "lt", "le")]
        [string]$ComparisonOperator = "eq"
    )
    
    try {
        # If recommendation is provided, extract expected value from it
        if ($Recommendation -and -not $ExpectedValue) {
            # Parse recommendation text to extract expected value
            $recommendationText = $Recommendation.title
            if ($recommendationText -match "'(.*?)'") {
                $ExpectedValue = $matches[1]
            }
        }
        
        # Perform comparison based on operator
        switch ($ComparisonOperator) {
            "eq" { $result = $CurrentValue -eq $ExpectedValue }
            "ne" { $result = $CurrentValue -ne $ExpectedValue }
            "gt" { $result = $CurrentValue -gt $ExpectedValue }
            "ge" { $result = $CurrentValue -ge $ExpectedValue }
            "lt" { $result = $CurrentValue -lt $ExpectedValue }
            "le" { $result = $CurrentValue -le $ExpectedValue }
            default { $result = $CurrentValue -eq $ExpectedValue }
        }
        
        return $result
    }
    catch {
        Write-Error "Failed to test CIS compliance for '$CIS_ID': $_"
        return $false
    }
}

# Function to invoke CIS audit with common patterns
function Invoke-CISAudit {
    <#
    .SYNOPSIS
        Generic CIS audit function that handles common audit patterns.
    .DESCRIPTION
        Provides a standardized framework for CIS audits with support for registry,
        group policy, service state, and custom audit patterns.
    .PARAMETER CIS_ID
        The CIS benchmark ID to audit.
    .PARAMETER AuditType
        The type of audit to perform (Registry, GroupPolicy, Service, Custom).
    .PARAMETER RegistryPath
        Registry path for registry-based audits.
    .PARAMETER RegistryValueName
        Registry value name for registry-based audits.
    .PARAMETER ServiceName
        Service name for service-based audits.
    .PARAMETER CustomScriptBlock
        Custom script block for complex audits.
    .PARAMETER VerboseOutput
        Enable verbose output.
    .PARAMETER Section
        CIS section number for recommendation lookup.
    .EXAMPLE
        $result = Invoke-CISAudit -CIS_ID "1.1.1" -AuditType "Registry" -RegistryPath "HKLM:\SOFTWARE\Policies\Microsoft\Windows" -RegistryValueName "PasswordHistorySize"
    .EXAMPLE
        $result = Invoke-CISAudit -CIS_ID "2.3.1.1" -AuditType "Service" -ServiceName "LanmanServer"
    .OUTPUTS
        PSCustomObject
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$CIS_ID,
        
        [Parameter(Mandatory=$true)]
        [ValidateSet("Registry", "GroupPolicy", "Service", "Custom")]
        [string]$AuditType,
        
        [string]$RegistryPath,
        
        [string]$RegistryValueName,
        
        [string]$ServiceName,
        
        [scriptblock]$CustomScriptBlock,
        
        [switch]$VerboseOutput,
        
        [ValidateSet("1", "2", "5", "9", "17", "18", "19")]
        [string]$Section
    )
    
    try {
        # Get CIS recommendation
        $recommendation = Get-CISRecommendation -CIS_ID $CIS_ID -Section $Section
        
        if (-not $recommendation) {
            return New-CISResultObject -CIS_ID $CIS_ID -Title "Unknown" -CurrentValue "Unknown" -RecommendedValue "Unknown" -ComplianceStatus "Error" -ErrorMessage "CIS recommendation not found"
        }
        
        # Perform audit based on type
        $currentValue = $null
        $source = "Unknown"
        $details = ""
        
        switch ($AuditType) {
            "Registry" {
                if (-not $RegistryPath -or -not $RegistryValueName) {
                    return New-CISResultObject -CIS_ID $CIS_ID -Title $recommendation.title -CurrentValue "N/A" -RecommendedValue "N/A" -ComplianceStatus "Error" -ErrorMessage "Registry path and value name required for registry audit"
                }
                
                if (Test-RegistryKey -KeyPath $RegistryPath) {
                    $currentValue = Get-RegistryValue -KeyPath $RegistryPath -ValueName $RegistryValueName -DefaultValue "Not Set"
                    $source = "Registry"
                    $details = "Registry path: $RegistryPath"
                } else {
                    $currentValue = "Key not found"
                    $source = "Registry"
                    $details = "Registry key does not exist: $RegistryPath"
                }
            }
            
            "GroupPolicy" {
                # For group policy, we typically check registry paths that store policy settings
                if (-not $RegistryPath -or -not $RegistryValueName) {
                    return New-CISResultObject -CIS_ID $CIS_ID -Title $recommendation.title -CurrentValue "N/A" -RecommendedValue "N/A" -ComplianceStatus "Error" -ErrorMessage "Registry path and value name required for group policy audit"
                }
                
                if (Test-RegistryKey -KeyPath $RegistryPath) {
                    $currentValue = Get-RegistryValue -KeyPath $RegistryPath -ValueName $RegistryValueName -DefaultValue "Not Configured"
                    $source = "Group Policy"
                    $details = "Group Policy registry path: $RegistryPath"
                } else {
                    $currentValue = "Policy not configured"
                    $source = "Group Policy"
                    $details = "Group Policy setting not configured: $RegistryPath"
                }
            }
            
            "Service" {
                if (-not $ServiceName) {
                    return New-CISResultObject -CIS_ID $CIS_ID -Title $recommendation.title -CurrentValue "N/A" -RecommendedValue "N/A" -ComplianceStatus "Error" -ErrorMessage "Service name required for service audit"
                }
                
                if (Test-ServiceExists -ServiceName $ServiceName) {
                    $service = Get-Service -Name $ServiceName
                    $currentValue = $service.Status.ToString()
                    $source = "Service Control Manager"
                    $details = "Service: $ServiceName, Status: $currentValue"
                } else {
                    $currentValue = "Service not found"
                    $source = "Service Control Manager"
                    $details = "Service does not exist: $ServiceName"
                }
            }
            
            "Custom" {
                if (-not $CustomScriptBlock) {
                    return New-CISResultObject -CIS_ID $CIS_ID -Title $recommendation.title -CurrentValue "N/A" -RecommendedValue "N/A" -ComplianceStatus "Error" -ErrorMessage "Custom script block required for custom audit"
                }
                
                try {
                    $customResult = & $CustomScriptBlock
                    $currentValue = $customResult.CurrentValue
                    $source = $customResult.Source
                    $details = $customResult.Details
                }
                catch {
                    return New-CISResultObject -CIS_ID $CIS_ID -Title $recommendation.title -CurrentValue "Error" -RecommendedValue "N/A" -ComplianceStatus "Error" -ErrorMessage "Custom audit failed: $_"
                }
            }
        }
        
        # Determine compliance status
        $complianceStatus = "Non-Compliant"
        
        # Parse recommendation to extract expected value
        $expectedValue = $null
        $comparisonOperator = "ge"
        
        if ($recommendation.title -match "'(.*?)'") {
            $expectedValueText = $matches[1]
            
            # Handle different recommendation patterns
            if ($expectedValueText -match "(\d+) or more") {
                $expectedValue = [int]$matches[1]
                $comparisonOperator = "ge"
            } elseif ($expectedValueText -match "(\d+) or fewer") {
                $expectedValue = [int]$matches[1]
                $comparisonOperator = "le"
            } elseif ($expectedValueText -match "Enabled") {
                $expectedValue = "Enabled"
                $comparisonOperator = "eq"
            } elseif ($expectedValueText -match "Disabled") {
                $expectedValue = "Disabled"
                $comparisonOperator = "eq"
            } else {
                # Try to parse as number
                if ([int]::TryParse($expectedValueText, [ref]$expectedValue)) {
                    $comparisonOperator = "eq"
                } else {
                    $expectedValue = $expectedValueText
                    $comparisonOperator = "eq"
                }
            }
        }
        
        # Test compliance
        $isCompliant = Test-CISCompliance -CIS_ID $CIS_ID -CurrentValue $currentValue -ExpectedValue $expectedValue -ComparisonOperator $comparisonOperator
        
        if ($isCompliant) {
            $complianceStatus = "Compliant"
        }
        
        # Create result object
        $result = New-CISResultObject -CIS_ID $CIS_ID -Title $recommendation.title -CurrentValue $currentValue -RecommendedValue $recommendation.title -ComplianceStatus $complianceStatus -Source $source -Details $details -Profile $recommendation.profile
        
        # Output verbose information if requested
        if ($VerboseOutput) {
            Write-Host ""
            Write-SectionHeader -Title "CIS Audit: $CIS_ID"
            Write-Host "Setting: $($result.Title)" -ForegroundColor White
            Write-Host "Current Value: $($result.CurrentValue)" -ForegroundColor White
            Write-Host "Recommended: $($result.RecommendedValue)" -ForegroundColor White
            Write-Host "Compliance: $($result.ComplianceStatus)" -ForegroundColor $(if ($result.IsCompliant) { "Green" } else { "Red" })
            Write-Host "Source: $($result.Source)" -ForegroundColor White
            if ($result.Details) {
                Write-Host "Details: $($result.Details)" -ForegroundColor Gray
            }
        }
        
        return $result
    }
    catch {
        return New-CISResultObject -CIS_ID $CIS_ID -Title "Error" -CurrentValue "Error" -RecommendedValue "N/A" -ComplianceStatus "Error" -ErrorMessage "Audit failed: $_"
    }
}

# Function to check if computer is domain member
function Test-DomainMember {
    <#
    .SYNOPSIS
        Checks if the computer is a domain member.
    .DESCRIPTION
        Returns $true if the computer is joined to a domain, $false otherwise.
    .EXAMPLE
        if (Test-DomainMember) { Write-Host "Computer is domain member" }
    .OUTPUTS
        System.Boolean
    #>
    try {
        $computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem
        return $computerSystem.PartOfDomain
    }
    catch {
        Write-Warning "Failed to determine domain membership: $_"
        return $false
    }
}

# Function to export audit results to CSV
function Export-CISAuditResults {
    <#
    .SYNOPSIS
        Exports CIS audit results to CSV file.
    .DESCRIPTION
        Creates a CSV file containing audit results for reporting and analysis.
    .PARAMETER Results
        Array of CIS audit result objects.
    .PARAMETER OutputPath
        Path where the CSV file will be saved.
    .EXAMPLE
        Export-CISAuditResults -Results $auditResults -OutputPath "C:\audit\results.csv"
    #>
    param(
        [Parameter(Mandatory=$true)]
        [array]$Results,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath
    )
    
    try {
        # Ensure output directory exists
        $outputDir = Split-Path $OutputPath -Parent
        if (-not (Test-Path $outputDir)) {
            New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
        }
        
        # Export to CSV
        $Results | Export-Csv -Path $OutputPath -NoTypeInformation
        
        Write-StatusMessage -Message "Audit results exported to: $OutputPath" -Type Success
    }
    catch {
        Write-Error "Failed to export audit results: $_"
    }
}

# Function to generate audit summary report
function Get-CISAuditSummary {
    <#
    .SYNOPSIS
        Generates a summary report from CIS audit results.
    .DESCRIPTION
        Creates a summary object with compliance statistics and overall status.
    .PARAMETER Results
        Array of CIS audit result objects.
    .EXAMPLE
        $summary = Get-CISAuditSummary -Results $auditResults
    .OUTPUTS
        PSCustomObject
    #>
    param(
        [Parameter(Mandatory=$true)]
        [array]$Results
    )
    
    $totalAudits = $Results.Count
    $compliantAudits = ($Results | Where-Object { $_.IsCompliant }).Count
    $nonCompliantAudits = ($Results | Where-Object { $_.ComplianceStatus -eq "Non-Compliant" }).Count
    $errorAudits = ($Results | Where-Object { $_.ComplianceStatus -eq "Error" }).Count
    $notApplicableAudits = ($Results | Where-Object { $_.ComplianceStatus -eq "Not Applicable" }).Count
    
    $compliancePercentage = if ($totalAudits -gt 0) { [math]::Round(($compliantAudits / $totalAudits) * 100, 2) } else { 0 }
    
    $overallStatus = if ($compliancePercentage -ge 90) { "Excellent" }
                     elseif ($compliancePercentage -ge 75) { "Good" }
                     elseif ($compliancePercentage -ge 50) { "Fair" }
                     else { "Poor" }
    
    return [PSCustomObject]@{
        TotalAudits = $totalAudits
        CompliantAudits = $compliantAudits
        NonCompliantAudits = $nonCompliantAudits
        ErrorAudits = $errorAudits
        NotApplicableAudits = $notApplicableAudits
        CompliancePercentage = $compliancePercentage
        OverallStatus = $overallStatus
        AuditTimestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        ComputerName = $env:COMPUTERNAME
    }
}

# Export the module members
Export-ModuleMember -Function New-CISResultObject, Get-CISRecommendation, Test-CISCompliance, Invoke-CISAudit, Test-DomainMember, Export-CISAuditResults, Get-CISAuditSummary
