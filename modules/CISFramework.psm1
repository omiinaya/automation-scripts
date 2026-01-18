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
        
        [string]$Section,
        
        [string]$JsonPath
    )
    
    try {
        # Determine JSON file path
        if ($JsonPath) {
            $jsonFilePath = $JsonPath
        } else {
            # Try to find JSON file with various patterns
            $patterns = @(
                "cis_section_$($CIS_ID.Replace('.','_')).json",
                "cis_section_$($CIS_ID.Split('.')[0])*.json"
            )
            
            foreach ($pattern in $patterns) {
                $testPath = Join-Path $PSScriptRoot "..\..\docs\json\$pattern"
                if (Test-Path $testPath) {
                    $jsonFilePath = $testPath
                    break
                }
            }
            
            # If still not found, try direct path construction
            if (-not $jsonFilePath) {
                $directPath = Join-Path $PSScriptRoot "..\..\docs\json\cis_section_$($CIS_ID.Replace('.','_')).json"
                if (Test-Path $directPath) {
                    $jsonFilePath = $directPath
                }
            }
        }
        
        # If no JSON file found, return a more specific default recommendation
        if (-not $jsonFilePath) {
            # Create a more meaningful default recommendation based on CIS_ID
            $defaultRecommendations = @{
                "1.1.1" = @{Title="Enforce password history"; RecommendedValue="24 or more passwords remembered"}
                "1.1.2" = @{Title="Maximum password age"; RecommendedValue="365 or fewer days, but not 0"}
                "1.1.3" = @{Title="Minimum password age"; RecommendedValue="1 or more day(s)"}
                "1.1.4" = @{Title="Minimum password length"; RecommendedValue="14 or more character(s)"}
                "1.1.5" = @{Title="Password complexity requirements"; RecommendedValue="Enabled"}
                "1.1.6" = @{Title="Relax minimum password length limits"; RecommendedValue="Disabled"}
                "1.1.7" = @{Title="Store passwords using reversible encryption"; RecommendedValue="Disabled"}
                "1.2.1" = @{Title="Account lockout duration"; RecommendedValue="15 or more minute(s)"}
                "1.2.2" = @{Title="Account lockout threshold"; RecommendedValue="5 or fewer invalid logon attempt(s), but not 0"}
                "1.2.3" = @{Title="Allow administrator account lockout"; RecommendedValue="Enabled"}
                "1.2.4" = @{Title="Reset account lockout counter after"; RecommendedValue="15 or more minute(s)"}
                # Add more CIS IDs as needed
            }
            
            if ($defaultRecommendations.ContainsKey($CIS_ID)) {
                $defaultRec = $defaultRecommendations[$CIS_ID]
                return [PSCustomObject]@{
                    cis_id = $CIS_ID
                    title = $defaultRec.Title
                    profile = "L1"
                    description = "CIS benchmark recommendation"
                    rationale = "Security compliance requirement"
                    impact = "Improves security posture"
                    audit_procedure = "Check system configuration"
                    remediation_procedure = "Apply security settings"
                    default_value = $defaultRec.RecommendedValue
                    page_number = 0
                }
            } else {
                return [PSCustomObject]@{
                    cis_id = $CIS_ID
                    title = "CIS Benchmark $CIS_ID"
                    profile = "L1"
                    description = "CIS benchmark recommendation"
                    rationale = "Security compliance requirement"
                    impact = "Improves security posture"
                    audit_procedure = "Check system configuration"
                    remediation_procedure = "Apply security settings"
                    default_value = "Compliant value"
                    page_number = 0
                }
            }
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
        
        # Handle type conversion for comparison
        $currentValueToCompare = $CurrentValue
        $expectedValueToCompare = $ExpectedValue
        
        # Extract numeric value from recommendation strings like "1 or more day(s)"
        if ($ExpectedValue -is [string] -and $ExpectedValue -match "(\d+)\s+or\s+more") {
            $expectedValueToCompare = [int]$matches[1]
            # For "or more" recommendations, use greater than or equal comparison
            if ($ComparisonOperator -eq "eq") {
                $ComparisonOperator = "ge"
            }
        } elseif ($ExpectedValue -is [string] -and $ExpectedValue -match "(\d+)\s+or\s+fewer") {
            $expectedValueToCompare = [int]$matches[1]
            # For "or fewer" recommendations, use less than or equal comparison
            if ($ComparisonOperator -eq "eq") {
                $ComparisonOperator = "le"
            }
        } elseif ($ExpectedValue -is [string] -and $ExpectedValue -match "(\d+)") {
            # Try to extract any numeric value
            $expectedValueToCompare = [int]$matches[1]
        }
        
        # Try to convert both values to the same type for comparison
        # Only attempt numeric conversion if both values are numeric strings
        if ($CurrentValue -is [int] -and $expectedValueToCompare -is [string]) {
            # Try to convert expected value to integer
            if ([int]::TryParse($expectedValueToCompare, [ref]$expectedValueToCompare)) {
                $expectedValueToCompare = [int]$expectedValueToCompare
            }
        } elseif ($CurrentValue -is [string] -and $expectedValueToCompare -is [int]) {
            # Try to convert current value to integer
            if ([int]::TryParse($CurrentValue, [ref]$currentValueToCompare)) {
                $currentValueToCompare = [int]$CurrentValue
            }
        } elseif ($CurrentValue -is [string] -and $expectedValueToCompare -is [string]) {
            # For string-to-string comparison, handle non-numeric values gracefully
            # Don't attempt numeric conversion for non-numeric strings like "*S-1-5-32-544" or "No One"
            if (-not [int]::TryParse($CurrentValue, [ref]$null) -and -not [int]::TryParse($expectedValueToCompare, [ref]$null)) {
                # Both are non-numeric strings, compare as-is
                $currentValueToCompare = $CurrentValue
                $expectedValueToCompare = $expectedValueToCompare
            }
        }
        
        # Perform comparison based on operator
        switch ($ComparisonOperator) {
            "eq" { $result = $currentValueToCompare -eq $expectedValueToCompare }
            "ne" { $result = $currentValueToCompare -ne $expectedValueToCompare }
            "gt" { $result = $currentValueToCompare -gt $expectedValueToCompare }
            "ge" { $result = $currentValueToCompare -ge $expectedValueToCompare }
            "lt" { $result = $currentValueToCompare -lt $expectedValueToCompare }
            "le" { $result = $currentValueToCompare -le $expectedValueToCompare }
            default { $result = $currentValueToCompare -eq $expectedValueToCompare }
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
        
        [string]$Section
    )
    
    try {
        # Get CIS recommendation
        $recommendation = Get-CISRecommendation -CIS_ID $CIS_ID -Section $Section
        
        # Use default recommendation if not found
        if (-not $recommendation) {
            $recommendation = [PSCustomObject]@{
                title = "CIS Benchmark $CIS_ID"
            }
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
        
        # Extract recommendation text from title (remove CIS Benchmark prefix)
        $recommendationText = $recommendation.title -replace "^.*?Ensure\\s+", "" -replace "\\s+is\\s+set\\s+to.*$", ""
        
        # Handle different recommendation patterns
        # For user rights assignment audits, use string comparison
        if ($CIS_ID -like "2.2.*" -and $AuditType -eq "Custom") {
            # User rights assignment - compare strings directly
            $expectedValue = "Administrators"
            $comparisonOperator = "eq"
        } elseif ($recommendationText -match "(\d+) or more") {
            $expectedValue = [int]$matches[1]
            $comparisonOperator = "ge"
        } elseif ($recommendationText -match "(\d+) or fewer") {
            $expectedValue = [int]$matches[1]
            $comparisonOperator = "le"
        } elseif ($recommendationText -match "Enabled") {
            $expectedValue = "Enabled"
            $comparisonOperator = "eq"
        } elseif ($recommendationText -match "Disabled") {
            $expectedValue = "Disabled"
            $comparisonOperator = "eq"
        } elseif ($recommendationText -match "(\d+)") {
            # Try to extract numeric value
            $expectedValue = [int]$matches[1]
            $comparisonOperator = "eq"
        } else {
            # Use default value from recommendation if available
            if ($recommendation.default_value -and $recommendation.default_value -ne "Compliant value") {
                $expectedValue = $recommendation.default_value
                $comparisonOperator = "eq"
            } else {
                # Fallback to generic comparison
                $expectedValue = $recommendationText
                $comparisonOperator = "eq"
            }
        }
        
        # Test compliance
        $isCompliant = Test-CISCompliance -CIS_ID $CIS_ID -CurrentValue $currentValue -ExpectedValue $expectedValue -ComparisonOperator $comparisonOperator
        
        if ($isCompliant) {
            $complianceStatus = "Compliant"
        }
        
        # Create result object with proper recommended value
        $recommendedValue = if ($recommendation.default_value -and $recommendation.default_value -ne "Compliant value") {
            $recommendation.default_value
        } elseif ($recommendation.title -match "Ensure.*is set to '(.*?)'") {
            $matches[1]
        } elseif ($recommendation.title -match "'(.*?)'") {
            $matches[1]
        } elseif ($recommendation.title -match "Ensure.*is set to (.*?)\.") {
            $matches[1]
        } else {
            # Extract meaningful recommendation from title
            $recommendation.title -replace "^.*?Ensure\\s+", "" -replace "\\s+is\\s+set\\s+to.*$", ""
        }
        
        $result = New-CISResultObject -CIS_ID $CIS_ID -Title $recommendation.title -CurrentValue $currentValue -RecommendedValue $recommendedValue -ComplianceStatus $complianceStatus -Source $source -Details $details -Profile $recommendation.profile
        
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