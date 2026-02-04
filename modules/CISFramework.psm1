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
    Dependencies   : CommonUtilities, WindowsUtils, RegistryUtils, WindowsUI modules
#>

# ============================================================================
# CENTRALIZED MODULE IMPORT APPROACH
# ============================================================================
# This module uses the centralized import approach via CommonUtilities.
# All module paths are resolved using Get-ModulePath function for consistency.
# Common utility functions (Test-AdminRights, Test-ServiceExists, etc.) are
# imported from CommonUtilities to eliminate code duplication.
# ============================================================================

# Import CommonUtilities module first for centralized utilities
$originalVerbosePreference = $VerbosePreference
$VerbosePreference = 'SilentlyContinue'

Import-Module "$PSScriptRoot\CommonUtilities.psm1" -Force -WarningAction SilentlyContinue -Verbose:$false

# Import required modules using Get-ModulePath for centralized path resolution
$modulePath = Get-ModulePath
Import-Module "$modulePath\WindowsUtils.psm1" -Force -WarningAction SilentlyContinue -Verbose:$false
Import-Module "$modulePath\RegistryUtils.psm1" -Force -WarningAction SilentlyContinue -Verbose:$false
Import-Module "$modulePath\WindowsUI.psm1" -Force -WarningAction SilentlyContinue -Verbose:$false

# Restore original verbose preference
$VerbosePreference = $originalVerbosePreference

# Set module-level verbose preference to ensure all internal verbose messages are suppressed
$script:VerbosePreference = 'SilentlyContinue'

# ============================================================================
# HELPER FUNCTIONS FOR Get-CISRecommendation
# ============================================================================

function Private-GetJsonPatterns {
    <#
    .SYNOPSIS
        Returns JSON file patterns for CIS ID lookup.
    #>
    param([string]$CIS_ID)
    
    return @(
        "cis_section_$($CIS_ID.Replace('.','_')).json",
        "cis_section_$($CIS_ID.Split('.')[0])*.json",
        "cis_section_$($CIS_ID.Split('.')[0])_$($CIS_ID.Split('.')[1])*.json"
    )
}

function Private-FindJsonFile {
    <#
    .SYNOPSIS
        Finds JSON file matching patterns.
    #>
    param([string[]]$Patterns, [string]$BasePath)
    
    foreach ($pattern in $Patterns) {
        $testPath = Join-Path $BasePath $pattern
        if (Test-Path $testPath) { return $testPath }
    }
    return $null
}

function Private-GetJsonFilePath {
    <#
    .SYNOPSIS
        Resolves JSON file path for CIS recommendation.
    #>
    param([string]$CIS_ID, [string]$JsonPath, [string]$BasePath)
    
    if ($JsonPath) { return $JsonPath }
    
    $patterns = Private-GetJsonPatterns -CIS_ID $CIS_ID
    $foundPath = Private-FindJsonFile -Patterns $patterns -BasePath $BasePath
    
    if ($foundPath) { return $foundPath }
    
    $directPath = Join-Path $BasePath "cis_section_$($CIS_ID.Replace('.','_')).json"
    if (Test-Path $directPath) { return $directPath }
    
    return $null
}

function Private-GetPasswordPolicyDefaults {
    <#
    .SYNOPSIS
        Returns password policy default recommendations.
    #>
    return @{
        "1.1.1" = @{Title="Enforce password history"; RecommendedValue="24 or more passwords remembered"}
        "1.1.2" = @{Title="Maximum password age"; RecommendedValue="365 or fewer days, but not 0"}
        "1.1.3" = @{Title="Minimum password age"; RecommendedValue="1 or more day(s)"}
        "1.1.4" = @{Title="Minimum password length"; RecommendedValue="14 or more character(s)"}
        "1.1.5" = @{Title="Password complexity requirements"; RecommendedValue="Enabled"}
        "1.1.6" = @{Title="Relax minimum password length limits"; RecommendedValue="Disabled"}
        "1.1.7" = @{Title="Store passwords using reversible encryption"; RecommendedValue="Disabled"}
    }
}

function Private-GetLockoutPolicyDefaults {
    <#
    .SYNOPSIS
        Returns account lockout policy default recommendations.
    #>
    return @{
        "1.2.1" = @{Title="Account lockout duration"; RecommendedValue="15 or more minute(s)"}
        "1.2.2" = @{Title="Account lockout threshold"; RecommendedValue="5 or fewer invalid logon attempt(s), but not 0"}
        "1.2.3" = @{Title="Allow administrator account lockout"; RecommendedValue="Enabled"}
        "1.2.4" = @{Title="Reset account lockout counter after"; RecommendedValue="15 or more minute(s)"}
    }
}

function Private-GetOtherDefaults {
    <#
    .SYNOPSIS
        Returns other default recommendations.
    #>
    return @{
        "2.2.1" = @{Title="Access Credential Manager as a trusted caller"; RecommendedValue="No One"}
        "2.2.2" = @{Title="Access this computer from the network"; RecommendedValue="Administrators, Remote Desktop Users"}
        "2.2.3" = @{Title="Act as part of the operating system"; RecommendedValue="No One"}
        "5.4" = @{Title="Downloaded Maps Manager (MapsBroker)"; RecommendedValue="Disabled"}
    }
}

function Private-GetDefaultRecommendations {
    <#
    .SYNOPSIS
        Returns all default recommendations dictionary.
    #>
    $defaults = @{}
    $defaults += Private-GetPasswordPolicyDefaults
    $defaults += Private-GetLockoutPolicyDefaults
    $defaults += Private-GetOtherDefaults
    return $defaults
}

function Private-CreateRecommendationObject {
    <#
    .SYNOPSIS
        Creates recommendation object with properties.
    #>
    param([string]$CIS_ID, [string]$Title, [string]$RecommendedValue)
    
    return [PSCustomObject]@{
        cis_id = $CIS_ID
        title = $Title
        profile = "L1"
        description = "CIS benchmark recommendation"
        rationale = "Security compliance requirement"
        impact = "Improves security posture"
        audit_procedure = "Check system configuration"
        remediation_procedure = "Apply security settings"
        default_value = $RecommendedValue
        page_number = 0
    }
}

function Private-GetTitleFromCISID {
    <#
    .SYNOPSIS
        Generates title from CIS ID pattern.
    #>
    param([string]$CIS_ID)
    
    return switch -Wildcard ($CIS_ID) {
        "1.1.*" { "Password Policy Settings" }
        "1.2.*" { "Account Lockout Policy Settings" }
        "2.2.*" { "User Rights Assignment Settings" }
        "2.3.*" { "Security Options Settings" }
        "5.*" { "Service Configuration Settings" }
        "9.*" { "Windows Firewall Settings" }
        "17.*" { "Audit Policy Settings" }
        "18.*" { "Administrative Templates Settings" }
        "19.*" { "Security Settings" }
        default { "CIS Security Setting" }
    }
}

function Private-GetDefaultRecommendation {
    <#
    .SYNOPSIS
        Gets default recommendation for CIS ID.
    #>
    param([string]$CIS_ID)
    
    $defaults = Private-GetDefaultRecommendations
    
    if ($defaults.ContainsKey($CIS_ID)) {
        $defaultRec = $defaults[$CIS_ID]
        return Private-CreateRecommendationObject -CIS_ID $CIS_ID -Title $defaultRec.Title -RecommendedValue $defaultRec.RecommendedValue
    }
    
    $title = Private-GetTitleFromCISID -CIS_ID $CIS_ID
    return Private-CreateRecommendationObject -CIS_ID $CIS_ID -Title "$title - $CIS_ID" -RecommendedValue "Compliant value"
}

function Private-LoadAndParseJson {
    <#
    .SYNOPSIS
        Loads and parses JSON file.
    #>
    param([string]$JsonFilePath)
    
    if (-not (Test-Path $JsonFilePath)) {
        Write-Warning "CIS JSON file not found: $JsonFilePath"
        return $null
    }
    
    return Get-Content $JsonFilePath -Raw | ConvertFrom-Json
}

function Private-FindRecommendationInJson {
    <#
    .SYNOPSIS
        Finds specific recommendation in JSON content.
    #>
    param([object]$JsonContent, [string]$CIS_ID)
    
    $recommendation = $JsonContent | Where-Object { $_.cis_id -eq $CIS_ID }
    
    if (-not $recommendation) {
        Write-Warning "CIS recommendation '$CIS_ID' not found in JSON"
        return $null
    }
    
    return $recommendation
}

function Private-LoadJsonRecommendation {
    <#
    .SYNOPSIS
        Loads and parses JSON recommendation file.
    #>
    param([string]$JsonFilePath, [string]$CIS_ID)
    
    $jsonContent = Private-LoadAndParseJson -JsonFilePath $JsonFilePath
    if (-not $jsonContent) { return $null }
    
    return Private-FindRecommendationInJson -JsonContent $jsonContent -CIS_ID $CIS_ID
}

# ============================================================================
# HELPER FUNCTIONS FOR Test-CISCompliance
# ============================================================================

function Private-CompareServiceStatus {
    <#
    .SYNOPSIS
        Compares service status with expected value.
    #>
    param([string]$CurrentValue, [string]$ExpectedValue)
    
    if ($CurrentValue -eq "Running" -and $ExpectedValue -eq "Disabled") { return $false }
    if ($CurrentValue -eq "Stopped" -and $ExpectedValue -eq "Disabled") { return $true }
    if ($CurrentValue -eq "Running" -and $ExpectedValue -eq "Enabled") { return $false }
    if ($CurrentValue -eq "Stopped" -and $ExpectedValue -eq "Enabled") { return $false }
    
    return $null
}

function Private-IsErrorCondition {
    <#
    .SYNOPSIS
        Checks if current value indicates error condition.
    #>
    param([string]$CurrentValue)
    
    $errorConditions = @("Key not found", "Policy not configured", "Service not found")
    return $errorConditions -contains $CurrentValue
}

function Private-ExtractMoreOrFewer {
    <#
    .SYNOPSIS
        Extracts numeric value from "or more" or "or fewer" patterns.
    #>
    param([string]$ExpectedValue, [ref]$ComparisonOperator)
    
    if ($ExpectedValue -match "(\d+)\s+or\s+more") {
        $ComparisonOperator.Value = "ge"
        return [int]$matches[1]
    }
    
    if ($ExpectedValue -match "(\d+)\s+or\s+fewer") {
        $ComparisonOperator.Value = "le"
        return [int]$matches[1]
    }
    
    return $null
}

function Private-ExtractAnyNumeric {
    <#
    .SYNOPSIS
        Extracts any numeric value from string.
    #>
    param([string]$ExpectedValue)
    
    if ($ExpectedValue -match "(\d+)") {
        return [int]$matches[1]
    }
    
    return $null
}

function Private-ExtractNumericValue {
    <#
    .SYNOPSIS
        Extracts numeric value from recommendation string.
    #>
    param([string]$ExpectedValue, [ref]$ComparisonOperator)
    
    $result = Private-ExtractMoreOrFewer -ExpectedValue $ExpectedValue -ComparisonOperator $ComparisonOperator
    if ($result) { return $result }
    
    return Private-ExtractAnyNumeric -ExpectedValue $ExpectedValue
}

function Private-TryParseNumericStrings {
    <#
    .SYNOPSIS
        Attempts to parse both strings as numbers.
    #>
    param([string]$CurrentValue, [string]$ExpectedValue, [ref]$CurrentNum, [ref]$ExpectedNum)
    
    $canParseCurrent = [double]::TryParse($CurrentValue, [ref]$CurrentNum.Value)
    $canParseExpected = [double]::TryParse($ExpectedValue, [ref]$ExpectedNum.Value)
    
    return $canParseCurrent -and $canParseExpected
}

function Private-CompareStringValues {
    <#
    .SYNOPSIS
        Compares string values with common CIS patterns.
    #>
    param([string]$CurrentValue, [string]$ExpectedValue)
    
    if ($CurrentValue -eq $ExpectedValue) { return $true }
    if ($CurrentValue -eq "Enabled" -and $ExpectedValue -eq "Disabled") { return $false }
    if ($CurrentValue -eq "Disabled" -and $ExpectedValue -eq "Enabled") { return $false }
    
    return $CurrentValue -eq $ExpectedValue
}

function Private-ConvertIntToString {
    <#
    .SYNOPSIS
        Converts int to string for comparison.
    #>
    param([object]$IntValue, [object]$StringValue, [ref]$Result)
    
    [int]$temp = 0
    if ([int]::TryParse($StringValue, [ref]$temp)) {
        $Result.Value = $temp
        return $true
    }
    return $false
}

function Private-ConvertStringToInt {
    <#
    .SYNOPSIS
        Converts string to int for comparison.
    #>
    param([object]$StringValue, [object]$IntValue, [ref]$Result)
    
    [int]$temp = 0
    if ([int]::TryParse($StringValue, [ref]$temp)) {
        $Result.Value = $temp
        return $true
    }
    return $false
}

function Private-ConvertTypesForComparison {
    <#
    .SYNOPSIS
        Converts types for comparison.
    #>
    param([object]$CurrentValue, [object]$ExpectedValue, [ref]$CurrentToCompare, [ref]$ExpectedToCompare)
    
    $CurrentToCompare.Value = $CurrentValue
    $ExpectedToCompare.Value = $ExpectedValue
    
    if ($CurrentValue -is [int] -and $ExpectedValue -is [string]) {
        Private-ConvertIntToString -IntValue $CurrentValue -StringValue $ExpectedValue -Result ([ref]$ExpectedToCompare.Value)
    }
    
    if ($CurrentValue -is [string] -and $ExpectedValue -is [int]) {
        Private-ConvertStringToInt -StringValue $CurrentValue -IntValue $ExpectedValue -Result ([ref]$CurrentToCompare.Value)
    }
}

function Private-PerformComparison {
    <#
    .SYNOPSIS
        Performs comparison based on operator.
    #>
    param([object]$CurrentValue, [object]$ExpectedValue, [string]$ComparisonOperator)
    
    return switch ($ComparisonOperator) {
        "eq" { $CurrentValue -eq $ExpectedValue }
        "ne" { $CurrentValue -ne $ExpectedValue }
        "gt" { $CurrentValue -gt $ExpectedValue }
        "ge" { $CurrentValue -ge $ExpectedValue }
        "lt" { $CurrentValue -lt $ExpectedValue }
        "le" { $CurrentValue -le $ExpectedValue }
        default { $CurrentValue -eq $ExpectedValue }
    }
}

# ============================================================================
# HELPER FUNCTIONS FOR Invoke-CISAudit
# ============================================================================

function Private-PerformRegistryAudit {
    <#
    .SYNOPSIS
        Performs registry-based audit.
    #>
    param([string]$RegistryPath, [string]$RegistryValueName)
    
    if (Test-RegistryKey -KeyPath $RegistryPath) {
        $currentValue = Get-RegistryValue -KeyPath $RegistryPath -ValueName $RegistryValueName -DefaultValue "Not Set"
        return @{ CurrentValue = $currentValue; Source = "Registry"; Details = "Registry path: $RegistryPath" }
    }
    
    return @{ CurrentValue = "Key not found"; Source = "Registry"; Details = "Registry key does not exist: $RegistryPath" }
}

function Private-PerformGroupPolicyAudit {
    <#
    .SYNOPSIS
        Performs group policy-based audit.
    #>
    param([string]$RegistryPath, [string]$RegistryValueName)
    
    if (Test-RegistryKey -KeyPath $RegistryPath) {
        $currentValue = Get-RegistryValue -KeyPath $RegistryPath -ValueName $RegistryValueName -DefaultValue "Not Configured"
        return @{ CurrentValue = $currentValue; Source = "Group Policy"; Details = "Group Policy registry path: $RegistryPath" }
    }
    
    return @{ CurrentValue = "Policy not configured"; Source = "Group Policy"; Details = "Group Policy setting not configured: $RegistryPath" }
}

function Private-PerformServiceAudit {
    <#
    .SYNOPSIS
        Performs service-based audit.
    #>
    param([string]$ServiceName)
    
    if (CommonUtilities\Test-ServiceExists -ServiceName $ServiceName) {
        $service = Get-Service -Name $ServiceName
        return @{ CurrentValue = $service.Status.ToString(); Source = "Service Control Manager"; Details = "Service: $ServiceName, Status: $($service.Status)" }
    }
    
    return @{ CurrentValue = "Service not found"; Source = "Service Control Manager"; Details = "Service does not exist: $ServiceName" }
}

function Private-PerformCustomAudit {
    <#
    .SYNOPSIS
        Performs custom script block audit.
    #>
    param([scriptblock]$CustomScriptBlock)
    
    try {
        $customResult = & $CustomScriptBlock
        return @{ CurrentValue = $customResult.CurrentValue; Source = $customResult.Source; Details = $customResult.Details }
    }
    catch {
        throw "Custom audit failed: $_"
    }
}

function Private-GetRecommendationText {
    <#
    .SYNOPSIS
        Extracts recommendation text from title.
    #>
    param([object]$Recommendation)
    
    return $Recommendation.title -replace "^.*?Ensure\s+", "" -replace "\s+is\s+set\s+to.*$", ""
}

function Private-ExtractUserRightsValue {
    <#
    .SYNOPSIS
        Extracts user rights assignment value.
    #>
    param([object]$Recommendation, [ref]$ExpectedValue)
    
    if ($Recommendation.title -match "Ensure.*is set to '(.*?)'") {
        $ExpectedValue.Value = $matches[1]
        return $true
    }
    
    if ($Recommendation.title -match "'(.*?)'") {
        $ExpectedValue.Value = $matches[1]
        return $true
    }
    
    return $false
}

function Private-HandleUserRightsAudit {
    <#
    .SYNOPSIS
        Handles user rights assignment audit extraction.
    #>
    param([string]$CIS_ID, [string]$AuditType, [object]$Recommendation, [ref]$ExpectedValue, [ref]$ComparisonOperator)
    
    if ($CIS_ID -like "2.2.*" -and $AuditType -eq "Custom") {
        if (Private-ExtractUserRightsValue -Recommendation $Recommendation -ExpectedValue ([ref]$ExpectedValue.Value)) {
            $ComparisonOperator.Value = "eq"
            return $true
        }
        $ExpectedValue.Value = "Administrators"
        $ComparisonOperator.Value = "eq"
        return $true
    }
    return $false
}

function Private-HandleMoreOrFewerPattern {
    <#
    .SYNOPSIS
        Handles "or more" or "or fewer" numeric patterns.
    #>
    param([string]$RecommendationText, [ref]$ExpectedValue, [ref]$ComparisonOperator)
    
    if ($RecommendationText -match "(\d+) or more") {
        $ExpectedValue.Value = [int]$matches[1]
        $ComparisonOperator.Value = "ge"
        return $true
    }
    
    if ($RecommendationText -match "(\d+) or fewer") {
        $ExpectedValue.Value = [int]$matches[1]
        $ComparisonOperator.Value = "le"
        return $true
    }
    
    return $false
}

function Private-HandleAnyNumericPattern {
    <#
    .SYNOPSIS
        Handles any numeric pattern.
    #>
    param([string]$RecommendationText, [ref]$ExpectedValue, [ref]$ComparisonOperator)
    
    if ($RecommendationText -match "(\d+)") {
        $ExpectedValue.Value = [int]$matches[1]
        $ComparisonOperator.Value = "eq"
        return $true
    }
    
    return $false
}

function Private-HandleNumericRecommendation {
    <#
    .SYNOPSIS
        Handles numeric recommendation patterns.
    #>
    param([string]$RecommendationText, [ref]$ExpectedValue, [ref]$ComparisonOperator)
    
    if (Private-HandleMoreOrFewerPattern -RecommendationText $RecommendationText -ExpectedValue ([ref]$ExpectedValue.Value) -ComparisonOperator ([ref]$ComparisonOperator.Value)) {
        return $true
    }
    
    return Private-HandleAnyNumericPattern -RecommendationText $RecommendationText -ExpectedValue ([ref]$ExpectedValue.Value) -ComparisonOperator ([ref]$ComparisonOperator.Value)
}

function Private-HandleEnabledDisabledRecommendation {
    <#
    .SYNOPSIS
        Handles Enabled/Disabled recommendation patterns.
    #>
    param([string]$RecommendationText, [ref]$ExpectedValue, [ref]$ComparisonOperator)
    
    if ($RecommendationText -match "Enabled") {
        $ExpectedValue.Value = "Enabled"
        $ComparisonOperator.Value = "eq"
        return $true
    }
    
    if ($RecommendationText -match "Disabled") {
        $ExpectedValue.Value = "Disabled"
        $ComparisonOperator.Value = "eq"
        return $true
    }
    
    return $false
}

function Private-HandleDefaultValueRecommendation {
    <#
    .SYNOPSIS
        Handles default value recommendation.
    #>
    param([object]$Recommendation, [ref]$ExpectedValue, [ref]$ComparisonOperator)
    
    if ($Recommendation.default_value -and $Recommendation.default_value -ne "Compliant value") {
        $ExpectedValue.Value = $Recommendation.default_value
        $ComparisonOperator.Value = "eq"
        return $true
    }
    return $false
}

function Private-InitializeExtractionDefaults {
    <#
    .SYNOPSIS
        Initializes default values for extraction.
    #>
    param([object]$Recommendation, [ref]$ExpectedValue, [ref]$ComparisonOperator)
    
    $ExpectedValue.Value = $null
    $ComparisonOperator.Value = "ge"
    return Private-GetRecommendationText -Recommendation $Recommendation
}

function Private-SetFallbackExpectedValue {
    <#
    .SYNOPSIS
        Sets fallback expected value from recommendation text.
    #>
    param([string]$RecommendationText, [ref]$ExpectedValue, [ref]$ComparisonOperator)
    
    $ExpectedValue.Value = $RecommendationText
    $ComparisonOperator.Value = "eq"
}

function Private-ExtractExpectedValueFromRecommendation {
    <#
    .SYNOPSIS
        Extracts expected value and comparison operator from recommendation.
    #>
    param([string]$CIS_ID, [string]$AuditType, [object]$Recommendation, [ref]$ExpectedValue, [ref]$ComparisonOperator)
    
    $recommendationText = Private-InitializeExtractionDefaults -Recommendation $Recommendation -ExpectedValue ([ref]$ExpectedValue.Value) -ComparisonOperator ([ref]$ComparisonOperator.Value)
    
    if (Private-HandleUserRightsAudit -CIS_ID $CIS_ID -AuditType $AuditType -Recommendation $Recommendation -ExpectedValue ([ref]$ExpectedValue.Value) -ComparisonOperator ([ref]$ComparisonOperator.Value)) { return }
    if (Private-HandleNumericRecommendation -RecommendationText $recommendationText -ExpectedValue ([ref]$ExpectedValue.Value) -ComparisonOperator ([ref]$ComparisonOperator.Value)) { return }
    if (Private-HandleEnabledDisabledRecommendation -RecommendationText $recommendationText -ExpectedValue ([ref]$ExpectedValue.Value) -ComparisonOperator ([ref]$ComparisonOperator.Value)) { return }
    if (Private-HandleDefaultValueRecommendation -Recommendation $Recommendation -ExpectedValue ([ref]$ExpectedValue.Value) -ComparisonOperator ([ref]$ComparisonOperator.Value)) { return }
    
    Private-SetFallbackExpectedValue -RecommendationText $recommendationText -ExpectedValue ([ref]$ExpectedValue.Value) -ComparisonOperator ([ref]$ComparisonOperator.Value)
}

function Private-MapDisabledServiceStatus {
    <#
    .SYNOPSIS
        Maps service status for Disabled recommendation.
    #>
    param([ref]$CurrentValue, [ref]$ExpectedValue)
    
    $ExpectedValue.Value = "Disabled"
    if ($CurrentValue.Value -eq "Stopped") { $CurrentValue.Value = "Disabled" }
    elseif ($CurrentValue.Value -eq "Running") { $CurrentValue.Value = "Enabled" }
}

function Private-MapEnabledServiceStatus {
    <#
    .SYNOPSIS
        Maps service status for Enabled recommendation.
    #>
    param([ref]$CurrentValue, [ref]$ExpectedValue)
    
    $ExpectedValue.Value = "Enabled"
    if ($CurrentValue.Value -eq "Running") { $CurrentValue.Value = "Enabled" }
    elseif ($CurrentValue.Value -eq "Stopped") { $CurrentValue.Value = "Disabled" }
}

function Private-MapServiceStatusForComparison {
    <#
    .SYNOPSIS
        Maps service status to Disabled/Enabled for comparison.
    #>
    param([string]$AuditType, [string]$RecommendationText, [ref]$CurrentValue, [ref]$ExpectedValue)
    
    if ($AuditType -ne "Service") { return }
    
    if ($RecommendationText -match "Disabled") {
        Private-MapDisabledServiceStatus -CurrentValue ([ref]$CurrentValue.Value) -ExpectedValue ([ref]$ExpectedValue.Value)
    }
    elseif ($RecommendationText -match "Enabled") {
        Private-MapEnabledServiceStatus -CurrentValue ([ref]$CurrentValue.Value) -ExpectedValue ([ref]$ExpectedValue.Value)
    }
}

function Private-ExtractFromTitlePatterns {
    <#
    .SYNOPSIS
        Extracts value from title patterns.
    #>
    param([object]$Recommendation)
    
    if ($Recommendation.title -match "Ensure.*is set to '(.*?)'") { return $matches[1] }
    if ($Recommendation.title -match "'(.*?)'") { return $matches[1] }
    if ($Recommendation.title -match "Ensure.*is set to (.*?)\.") { return $matches[1] }
    
    return $null
}

function Private-ExtractRecommendedValue {
    <#
    .SYNOPSIS
        Extracts recommended value from recommendation object.
    #>
    param([object]$Recommendation)
    
    if ($Recommendation.default_value -and $Recommendation.default_value -ne "Compliant value") {
        return $Recommendation.default_value
    }
    
    $extracted = Private-ExtractFromTitlePatterns -Recommendation $Recommendation
    if ($extracted) { return $extracted }
    
    return Private-GetRecommendationText -Recommendation $Recommendation
}

function Private-GetComplianceColor {
    <#
    .SYNOPSIS
        Gets color based on compliance status.
    #>
    param([PSCustomObject]$Result)
    
    return if ($Result.IsCompliant) { "Green" } else { "Red" }
}

function Private-WriteVerboseAuditOutput {
    <#
    .SYNOPSIS
        Writes verbose audit output to console.
    #>
    param([PSCustomObject]$Result)
    
    Write-Host ""
    Write-SectionHeader -Title "CIS Audit: $($Result.CIS_ID)"
    Write-Host "Setting: $($Result.Title)" -ForegroundColor White
    Write-Host "Current Value: $($Result.CurrentValue)" -ForegroundColor White
    Write-Host "Recommended: $($Result.RecommendedValue)" -ForegroundColor White
    $color = Private-GetComplianceColor -Result $Result
    Write-Host "Compliance: $($Result.ComplianceStatus)" -ForegroundColor $color
    Write-Host "Source: $($Result.Source)" -ForegroundColor White
    if ($Result.Details) { Write-Host "Details: $($Result.Details)" -ForegroundColor Gray }
}

# ============================================================================
# HELPER FUNCTIONS FOR Invoke-CISScript
# ============================================================================

function Private-ImportModuleIfNeeded {
    <#
    .SYNOPSIS
        Imports module if not already loaded.
    #>
    param([string]$ModuleName, [string]$ModulePath)
    
    if (-not (Get-Module -Name $ModuleName -ErrorAction SilentlyContinue)) {
        $moduleFilePath = Join-Path $ModulePath "$ModuleName.psm1"
        if (Test-Path $moduleFilePath) {
            Import-Module $moduleFilePath -Force -WarningAction SilentlyContinue -Verbose:$false
        }
        else {
            throw "Required module '$ModuleName' is not loaded and module file not found."
        }
    }
}

function Private-VerifyRequiredModules {
    <#
    .SYNOPSIS
        Verifies and imports required modules.
    #>
    param([string[]]$RequiredModules, [string]$ModulePath)
    
    foreach ($moduleName in $RequiredModules) {
        Private-ImportModuleIfNeeded -ModuleName $moduleName -ModulePath $ModulePath
    }
}

function Private-HandleAutoElevate {
    <#
    .SYNOPSIS
        Handles auto-elevation scenario.
    #>
    param([switch]$VerboseOutput)
    
    if ($VerboseOutput) { Write-StatusMessage -Message "Elevating privileges..." -Type Info }
    return "Elevate"
}

function Private-HandleManualElevation {
    <#
    .SYNOPSIS
        Handles manual elevation scenario.
    #>
    param()
    
    Write-StatusMessage -Message "WARNING: This operation may require administrator privileges" -Type Warning
    Write-StatusMessage -Message "Some operations may fail without elevated permissions" -Type Warning
    
    $continue = Show-Confirmation -Message "Continue without administrator privileges?" -DefaultChoice "No"
    return if ($continue) { "Continue" } else { "Cancel" }
}

function Private-HandleMissingAdminRights {
    <#
    .SYNOPSIS
        Handles missing administrator rights.
    #>
    param([switch]$AutoElevate, [switch]$VerboseOutput)
    
    if ($AutoElevate) {
        return Private-HandleAutoElevate -VerboseOutput:$VerboseOutput
    }
    
    return Private-HandleManualElevation
}

function Private-ElevatePrivileges {
    <#
    .SYNOPSIS
        Elevates script privileges.
    #>
    param([string]$CurrentScript)
    
    if (-not $currentScript -or -not (Test-Path $currentScript)) {
        throw "Cannot determine script path for elevation. Please run PowerShell as administrator."
    }
    
    $arguments = "-ExecutionPolicy Bypass -File `"$currentScript`""
    Start-Process -FilePath "powershell.exe" -ArgumentList $arguments -Verb RunAs -Wait
    exit 0
}

function Private-GetCurrentScriptPath {
    <#
    .SYNOPSIS
        Gets the current script path.
    #>
    param([System.Management.Automation.InvocationInfo]$Invocation)
    
    $currentScript = $Invocation.MyCommand.Path
    if (-not $currentScript) {
        $currentScript = (Get-Variable MyInvocation -Scope 1).Value.MyCommand.Path
    }
    return $currentScript
}

function Private-WriteVerboseScriptHeader {
    <#
    .SYNOPSIS
        Writes verbose script execution header.
    #>
    param([string]$ScriptType, [string]$CIS_ID, [string]$ServiceName, [bool]$IsAdmin)
    
    Write-SectionHeader -Title "CIS Script Execution"
    Write-Host "Script Type: $ScriptType" -ForegroundColor White
    if ($CIS_ID) { Write-Host "CIS ID: $CIS_ID" -ForegroundColor White }
    if ($ServiceName) { Write-Host "Service: $ServiceName" -ForegroundColor White }
    Write-Host "Admin Rights: $(if ($IsAdmin) { 'Yes' } else { 'No' })" -ForegroundColor White
    Write-Host ""
}

function Private-WriteScriptErrorOutput {
    <#
    .SYNOPSIS
        Writes script error output to console.
    #>
    param([PSCustomObject]$ErrorInfo)
    
    Write-StatusMessage -Message "Script execution failed" -Type Error
    Write-Host "Error Details: $($ErrorInfo.ErrorMessage)" -ForegroundColor Red
    Write-Host "Error Type: $($ErrorInfo.ErrorType)" -ForegroundColor Red
    Write-Host "Recommendation: $($ErrorInfo.Recommendation)" -ForegroundColor Yellow
}

# ============================================================================
# PUBLIC FUNCTIONS
# ============================================================================

function Private-CreateResultTimestamp {
    <#
    .SYNOPSIS
        Creates audit timestamp.
    #>
    return Get-Date -Format "yyyy-MM-dd HH:mm:ss"
}

function Private-GetComplianceFlag {
    <#
    .SYNOPSIS
        Gets compliance flag from status.
    #>
    param([string]$ComplianceStatus)
    
    return ($ComplianceStatus -eq "Compliant")
}

function Private-BuildResultObject {
    <#
    .SYNOPSIS
        Builds result object from parameters.
    #>
    param([string]$CIS_ID, [string]$Title, [object]$CurrentValue, [string]$RecommendedValue, [string]$ComplianceStatus, [bool]$IsCompliant, [string]$Source, [string]$Details, [string]$ErrorMessage, [string]$Profile, [string]$AuditTimestamp)
    
    return [PSCustomObject]@{
        CIS_ID = $CIS_ID
        Title = $Title
        CurrentValue = $CurrentValue
        RecommendedValue = $RecommendedValue
        ComplianceStatus = $ComplianceStatus
        IsCompliant = $IsCompliant
        Source = $Source
        Details = $Details
        ErrorMessage = $ErrorMessage
        Profile = $Profile
        AuditTimestamp = $AuditTimestamp
        ComputerName = $env:COMPUTERNAME
        UserName = $env:USERNAME
    }
}

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
    
    $auditTimestamp = Private-CreateResultTimestamp
    $isCompliant = Private-GetComplianceFlag -ComplianceStatus $ComplianceStatus
    
    return Private-BuildResultObject -CIS_ID $CIS_ID -Title $Title -CurrentValue $CurrentValue -RecommendedValue $RecommendedValue -ComplianceStatus $ComplianceStatus -IsCompliant $isCompliant -Source $Source -Details $Details -ErrorMessage $ErrorMessage -Profile $Profile -AuditTimestamp $auditTimestamp
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
        $basePath = Join-Path $PSScriptRoot "..\..\docs\json"
        $jsonFilePath = Private-GetJsonFilePath -CIS_ID $CIS_ID -JsonPath $JsonPath -BasePath $basePath
        
        if (-not $jsonFilePath) { return Private-GetDefaultRecommendation -CIS_ID $CIS_ID }
        
        return Private-LoadJsonRecommendation -JsonFilePath $jsonFilePath -CIS_ID $CIS_ID
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
        if ($Recommendation -and -not $ExpectedValue) {
            if ($Recommendation.title -match "'(.*?)'") { $ExpectedValue = $matches[1] }
        }
        
        $currentValueToCompare = $CurrentValue
        $expectedValueToCompare = $ExpectedValue
        
        if ($CurrentValue -is [string] -and $expectedValueToCompare -is [string]) {
            $serviceResult = Private-CompareServiceStatus -CurrentValue $CurrentValue -ExpectedValue $expectedValueToCompare
            if ($serviceResult -ne $null) { return $serviceResult }
            if (Private-IsErrorCondition -CurrentValue $CurrentValue) { return $false }
        }
        
        $numericValue = Private-ExtractNumericValue -ExpectedValue $ExpectedValue -ComparisonOperator ([ref]$ComparisonOperator)
        if ($numericValue) { $expectedValueToCompare = $numericValue }
        
        if ($CurrentValue -is [string] -and $expectedValueToCompare -is [string]) {
            $currentNum = 0; $expectedNum = 0
            if (Private-TryParseNumericStrings -CurrentValue $CurrentValue -ExpectedValue $expectedValueToCompare -CurrentNum ([ref]$currentNum) -ExpectedNum ([ref]$expectedNum)) {
                $currentValueToCompare = $currentNum
                $expectedValueToCompare = $expectedNum
            }
            else { return Private-CompareStringValues -CurrentValue $CurrentValue -ExpectedValue $expectedValueToCompare }
        }
        
        Private-ConvertTypesForComparison -CurrentValue $CurrentValue -ExpectedValue $ExpectedValue -CurrentToCompare ([ref]$currentValueToCompare) -ExpectedToCompare ([ref]$expectedValueToCompare)
        
        return Private-PerformComparison -CurrentValue $currentValueToCompare -ExpectedValue $expectedValueToCompare -ComparisonOperator $ComparisonOperator
    }
    catch {
        Write-Error "Failed to test CIS compliance for '$CIS_ID': $_"
        return $false
    }
}

function Private-GetRecommendationOrDefault {
    <#
    .SYNOPSIS
        Gets recommendation or creates default.
    #>
    param([string]$CIS_ID, [string]$Section)
    
    $recommendation = Get-CISRecommendation -CIS_ID $CIS_ID -Section $Section
    if (-not $recommendation) {
        $recommendation = [PSCustomObject]@{ title = "CIS Benchmark $CIS_ID" }
    }
    return $recommendation
}

function Private-PerformAuditByType {
    <#
    .SYNOPSIS
        Performs audit based on type.
    #>
    param([string]$AuditType, [string]$CIS_ID, [string]$RegistryPath, [string]$RegistryValueName, [string]$ServiceName, [scriptblock]$CustomScriptBlock, [object]$Recommendation)
    
    switch ($AuditType) {
        "Registry" {
            if (-not $RegistryPath -or -not $RegistryValueName) {
                return New-CISResultObject -CIS_ID $CIS_ID -Title $recommendation.title -CurrentValue "N/A" -RecommendedValue "N/A" -ComplianceStatus "Error" -ErrorMessage "Registry path and value name required for registry audit"
            }
            return Private-PerformRegistryAudit -RegistryPath $RegistryPath -RegistryValueName $RegistryValueName
        }
        "GroupPolicy" {
            if (-not $RegistryPath -or -not $RegistryValueName) {
                return New-CISResultObject -CIS_ID $CIS_ID -Title $recommendation.title -CurrentValue "N/A" -RecommendedValue "N/A" -ComplianceStatus "Error" -ErrorMessage "Registry path and value name required for group policy audit"
            }
            return Private-PerformGroupPolicyAudit -RegistryPath $RegistryPath -RegistryValueName $RegistryValueName
        }
        "Service" {
            if (-not $ServiceName) {
                return New-CISResultObject -CIS_ID $CIS_ID -Title $recommendation.title -CurrentValue "N/A" -RecommendedValue "N/A" -ComplianceStatus "Error" -ErrorMessage "Service name required for service audit"
            }
            return Private-PerformServiceAudit -ServiceName $ServiceName
        }
        "Custom" {
            if (-not $CustomScriptBlock) {
                return New-CISResultObject -CIS_ID $CIS_ID -Title $recommendation.title -CurrentValue "N/A" -RecommendedValue "N/A" -ComplianceStatus "Error" -ErrorMessage "Custom script block required for custom audit"
            }
            return Private-PerformCustomAudit -CustomScriptBlock $CustomScriptBlock
        }
    }
}

function Private-ProcessAuditResult {
    <#
    .SYNOPSIS
        Processes audit result and returns final result.
    #>
    param([hashtable]$AuditResult, [string]$CIS_ID, [string]$AuditType, [object]$Recommendation, [switch]$VerboseOutput)
    
    $currentValue = $auditResult.CurrentValue
    $source = $auditResult.Source
    $details = $auditResult.Details
    
    $expectedValue = $null
    $comparisonOperator = "ge"
    Private-ExtractExpectedValueFromRecommendation -CIS_ID $CIS_ID -AuditType $AuditType -Recommendation $recommendation -ExpectedValue ([ref]$expectedValue) -ComparisonOperator ([ref]$comparisonOperator)
    
    $recommendationText = Private-GetRecommendationText -Recommendation $recommendation
    Private-MapServiceStatusForComparison -AuditType $AuditType -RecommendationText $recommendationText -CurrentValue ([ref]$currentValue) -ExpectedValue ([ref]$expectedValue)
    
    $isCompliant = Test-CISCompliance -CIS_ID $CIS_ID -CurrentValue $currentValue -ExpectedValue $expectedValue -ComparisonOperator $comparisonOperator
    $complianceStatus = if ($isCompliant) { "Compliant" } else { "Non-Compliant" }
    
    $recommendedValue = Private-ExtractRecommendedValue -Recommendation $recommendation
    $result = New-CISResultObject -CIS_ID $CIS_ID -Title $recommendation.title -CurrentValue $currentValue -RecommendedValue $recommendedValue -ComplianceStatus $complianceStatus -Source $source -Details $details -Profile $recommendation.profile
    
    if ($VerboseOutput) { Private-WriteVerboseAuditOutput -Result $result }
    
    return $result
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
        $recommendation = Private-GetRecommendationOrDefault -CIS_ID $CIS_ID -Section $Section
        $auditResult = Private-PerformAuditByType -AuditType $AuditType -CIS_ID $CIS_ID -RegistryPath $RegistryPath -RegistryValueName $RegistryValueName -ServiceName $ServiceName -CustomScriptBlock $CustomScriptBlock -Recommendation $recommendation
        
        return Private-ProcessAuditResult -AuditResult $auditResult -CIS_ID $CIS_ID -AuditType $AuditType -Recommendation $recommendation -VerboseOutput:$VerboseOutput
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
        $outputDir = Split-Path $OutputPath -Parent
        if (-not (Test-Path $outputDir)) {
            New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
        }
        
        $Results | Export-Csv -Path $OutputPath -NoTypeInformation
        Write-StatusMessage -Message "Audit results exported to: $OutputPath" -Type Success
    }
    catch {
        Write-Error "Failed to export audit results: $_"
    }
}

function Private-ClassifyError {
    <#
    .SYNOPSIS
        Classifies error based on message pattern.
    #>
    param([string]$ErrorMessage)
    
    return switch -Wildcard ($errorMessage) {
        "*Access denied*" { "PermissionError", "Run the script as administrator or check user permissions." }
        "*Cannot find path*" { "PathNotFoundError", "Verify the file or registry path exists." }
        "*Service was not found*" { "ServiceNotFoundError", "The specified service may not exist on this Windows version." }
        "*Registry key does not exist*" { "RegistryKeyNotFoundError", "The registry key may not exist or may require administrator access." }
        "*Group Policy*" { "GroupPolicyError", "This may require domain administrator privileges." }
        "*The RPC server is unavailable*" { "RPCError", "Check if the RPC service is running and accessible." }
        "*Timeout*" { "TimeoutError", "The operation timed out. Try again or increase timeout settings." }
        "*Insufficient system resources*" { "ResourceError", "Check system resources and try again." }
        default { "Unknown", "Check the error details and try again." }
    }
}

function Private-GetScriptTypeRecommendation {
    <#
    .SYNOPSIS
        Gets recommendation based on script type.
    #>
    param([string]$ScriptType)
    
    return switch ($ScriptType) {
        "Audit" { "Check audit configuration and ensure all required modules are loaded." }
        "Remediation" { "Verify remediation prerequisites and ensure administrator privileges." }
        "ServiceToggle" { "Check service dependencies and ensure service exists on this system." }
        default { "Check the error details and try again." }
    }
}

function Private-CreateErrorLogEntry {
    <#
    .SYNOPSIS
        Creates error log entry object.
    #>
    param([string]$Timestamp, [string]$ErrorType, [string]$ErrorMessage, [string]$ScriptType, [string]$CIS_ID, [string]$ServiceName, [string]$CustomContext, [string]$Recommendation, [string]$StackTrace)
    
    return [PSCustomObject]@{
        Timestamp = $Timestamp
        ErrorType = $ErrorType
        ErrorMessage = $ErrorMessage
        ScriptType = $ScriptType
        CIS_ID = $CIS_ID
        ServiceName = $ServiceName
        CustomContext = $CustomContext
        ComputerName = $env:COMPUTERNAME
        UserName = $env:USERNAME
        Recommendation = $Recommendation
        StackTrace = $StackTrace
    }
}

function Private-WriteErrorLog {
    <#
    .SYNOPSIS
        Writes error log to file.
    #>
    param([PSCustomObject]$LogEntry, [string]$LogPath)
    
    $logDir = Split-Path $LogPath -Parent
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    
    $LogEntry | Export-Csv -Path $LogPath -Append -NoTypeInformation
}

function Private-BuildErrorResult {
    <#
    .SYNOPSIS
        Builds error result object.
    #>
    param([string]$ErrorType, [string]$ErrorMessage, [string]$Recommendation, [string]$Timestamp, [string]$LogPath, [string]$ScriptType, [string]$CIS_ID)
    
    return [PSCustomObject]@{
        ErrorType = $ErrorType
        ErrorMessage = $ErrorMessage
        Recommendation = $Recommendation
        Timestamp = $Timestamp
        LogPath = $LogPath
        ScriptType = $ScriptType
        CIS_ID = $CIS_ID
    }
}

function Private-CountAuditStatus {
    <#
    .SYNOPSIS
        Counts audits by status.
    #>
    param([array]$Results, [string]$Status)
    
    return ($Results | Where-Object { $_.ComplianceStatus -eq $Status }).Count
}

function Private-CalculateCompliancePercentage {
    <#
    .SYNOPSIS
        Calculates compliance percentage.
    #>
    param([int]$CompliantAudits, [int]$TotalAudits)
    
    return if ($TotalAudits -gt 0) { [math]::Round(($CompliantAudits / $TotalAudits) * 100, 2) } else { 0 }
}

function Private-DetermineOverallStatus {
    <#
    .SYNOPSIS
        Determines overall status based on percentage.
    #>
    param([double]$CompliancePercentage)
    
    return if ($CompliancePercentage -ge 90) { "Excellent" }
           elseif ($CompliancePercentage -ge 75) { "Good" }
           elseif ($CompliancePercentage -ge 50) { "Fair" }
           else { "Poor" }
}

function Private-BuildSummaryObject {
    <#
    .SYNOPSIS
        Builds summary object.
    #>
    param([int]$TotalAudits, [int]$CompliantAudits, [int]$NonCompliantAudits, [int]$ErrorAudits, [int]$NotApplicableAudits, [double]$CompliancePercentage, [string]$OverallStatus, [string]$AuditTimestamp)
    
    return [PSCustomObject]@{
        TotalAudits = $TotalAudits
        CompliantAudits = $CompliantAudits
        NonCompliantAudits = $NonCompliantAudits
        ErrorAudits = $ErrorAudits
        NotApplicableAudits = $NotApplicableAudits
        CompliancePercentage = $CompliancePercentage
        OverallStatus = $OverallStatus
        AuditTimestamp = $AuditTimestamp
        ComputerName = $env:COMPUTERNAME
    }
}

function Private-HandleAdminRightsCheck {
    <#
    .SYNOPSIS
        Handles admin rights check and elevation.
    #>
    param([switch]$AutoElevate, [switch]$VerboseOutput, [System.Management.Automation.InvocationInfo]$Invocation)
    
    $isAdmin = CommonUtilities\Test-AdminRights
    
    if (-not $isAdmin) {
        $adminAction = Private-HandleMissingAdminRights -AutoElevate:$AutoElevate -VerboseOutput:$VerboseOutput
        
        if ($adminAction -eq "Elevate") {
            $currentScript = Private-GetCurrentScriptPath -Invocation $Invocation
            Private-ElevatePrivileges -CurrentScript $currentScript
        }
        elseif ($adminAction -eq "Cancel") {
            return [PSCustomObject]@{ Status = "Cancelled"; Message = "Operation cancelled by user" }
        }
    }
    
    return $isAdmin
}

function Private-ExecuteScriptBlock {
    <#
    .SYNOPSIS
        Executes the script block with error handling.
    #>
    param([scriptblock]$ScriptBlock, [switch]$VerboseOutput, [string]$ScriptType, [string]$CIS_ID, [string]$ServiceName)
    
    try {
        $result = & $ScriptBlock
        
        if ($VerboseOutput) {
            Write-StatusMessage -Message "Script execution completed successfully" -Type Success
        }
        
        return $result
    }
    catch {
        $errorInfo = Handle-CISError -ErrorRecord $_ -ScriptType $ScriptType -CIS_ID $CIS_ID -ServiceName $ServiceName
        
        if ($VerboseOutput) {
            Private-WriteScriptErrorOutput -ErrorInfo $errorInfo
        }
        
        return [PSCustomObject]@{
            Status = "Failed"
            ErrorMessage = $errorInfo.ErrorMessage
            ErrorType = $errorInfo.ErrorType
            Recommendation = $errorInfo.Recommendation
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
    }
}

# Function to handle CIS errors with standardized error classification
function Handle-CISError {
    <#
    .SYNOPSIS
        Standardized error handling function for CIS scripts.
    .DESCRIPTION
        Provides structured error classification, logging with timestamps,
        and context-aware error recommendations.
    .PARAMETER ErrorRecord
        The PowerShell error record to handle.
    .PARAMETER ScriptType
        Type of script where the error occurred.
    .PARAMETER CIS_ID
        CIS benchmark ID related to the error.
    .PARAMETER ServiceName
        Service name related to the error.
    .PARAMETER CustomContext
        Additional context information.
    .EXAMPLE
        try {
            # Some operation
        } catch {
            $errorInfo = Handle-CISError -ErrorRecord $_ -ScriptType "Audit" -CIS_ID "1.1.1"
            Write-Error $errorInfo.ErrorMessage
        }
    .OUTPUTS
        PSCustomObject containing structured error information.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord,
        
        [string]$ScriptType = "Unknown",
        
        [string]$CIS_ID,
        
        [string]$ServiceName,
        
        [string]$CustomContext
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $errorMessage = $ErrorRecord.Exception.Message
    $stackTrace = $ErrorRecord.ScriptStackTrace
    
    $errorType, $recommendation = Private-ClassifyError -ErrorMessage $errorMessage
    
    if ($errorType -eq "Unknown") { $recommendation = Private-GetScriptTypeRecommendation -ScriptType $ScriptType }
    
    $logEntry = Private-CreateErrorLogEntry -Timestamp $timestamp -ErrorType $errorType -ErrorMessage $errorMessage -ScriptType $ScriptType -CIS_ID $CIS_ID -ServiceName $ServiceName -CustomContext $CustomContext -Recommendation $recommendation -StackTrace $stackTrace
    
    $logPath = Join-Path $PSScriptRoot "..\..\logs\cis-errors.log"
    Private-WriteErrorLog -LogEntry $logEntry -LogPath $logPath
    
    return Private-BuildErrorResult -ErrorType $errorType -ErrorMessage $errorMessage -Recommendation $recommendation -Timestamp $timestamp -LogPath $logPath -ScriptType $ScriptType -CIS_ID $CIS_ID
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
    $nonCompliantAudits = Private-CountAuditStatus -Results $Results -Status "Non-Compliant"
    $errorAudits = Private-CountAuditStatus -Results $Results -Status "Error"
    $notApplicableAudits = Private-CountAuditStatus -Results $Results -Status "Not Applicable"
    
    $compliancePercentage = Private-CalculateCompliancePercentage -CompliantAudits $compliantAudits -TotalAudits $totalAudits
    $overallStatus = Private-DetermineOverallStatus -CompliancePercentage $compliancePercentage
    $auditTimestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    return Private-BuildSummaryObject -TotalAudits $totalAudits -CompliantAudits $compliantAudits -NonCompliantAudits $nonCompliantAudits -ErrorAudits $errorAudits -NotApplicableAudits $notApplicableAudits -CompliancePercentage $compliancePercentage -OverallStatus $overallStatus -AuditTimestamp $auditTimestamp
}

# Function to centralize script execution with admin rights checking and module imports
function Invoke-CISScript {
    <#
    .SYNOPSIS
        Centralized entry point function for CIS scripts.
    .DESCRIPTION
        Combines admin rights checking, module imports, and error handling in a single function.
        Reduces boilerplate code in individual scripts.
    .PARAMETER ScriptType
        Type of script being executed (Audit, Remediation, ServiceToggle, Optimization).
    .PARAMETER CIS_ID
        CIS benchmark ID for audit/remediation scripts.
    .PARAMETER ServiceName
        Service name for service toggle operations.
    .PARAMETER ServiceDisplayName
        Display name of the service for user-friendly output.
    .PARAMETER ScriptBlock
        Script block containing the main script logic.
    .PARAMETER VerboseOutput
        Enable verbose output.
    .PARAMETER AutoElevate
        Automatically elevate privileges if admin rights are missing.
    .EXAMPLE
        Invoke-CISScript -ScriptType "Audit" -CIS_ID "1.1.1" -ScriptBlock {
            # Audit logic here
            $result = Invoke-CISAudit -CIS_ID "1.1.1" -AuditType "Registry" -RegistryPath "HKLM:\SOFTWARE\Policies\Microsoft\Windows" -RegistryValueName "PasswordHistorySize"
            return $result
        }
    .EXAMPLE
        Invoke-CISScript -ScriptType "ServiceToggle" -ServiceName "BDESVC" -ServiceDisplayName "BitLocker Drive Encryption" -ScriptBlock {
            Invoke-ServiceToggle -ServiceName "BDESVC" -ServiceDisplayName "BitLocker Drive Encryption"
        }
    .OUTPUTS
        Script execution result object.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("Audit", "Remediation", "ServiceToggle", "Optimization", "Custom")]
        [string]$ScriptType,
        
        [string]$CIS_ID,
        
        [string]$ServiceName,
        
        [string]$ServiceDisplayName,
        
        [Parameter(Mandatory=$true)]
        [scriptblock]$ScriptBlock,
        
        [switch]$VerboseOutput,
        
        [switch]$AutoElevate
    )
    
    try {
        $requiredModules = @("WindowsUtils", "RegistryUtils", "WindowsUI")
        Private-VerifyRequiredModules -RequiredModules $requiredModules -ModulePath $PSScriptRoot
        
        $isAdmin = Private-HandleAdminRightsCheck -AutoElevate:$AutoElevate -VerboseOutput:$VerboseOutput -Invocation $MyInvocation
        
        if ($VerboseOutput) { Private-WriteVerboseScriptHeader -ScriptType $ScriptType -CIS_ID $CIS_ID -ServiceName $ServiceName -IsAdmin $isAdmin }
        
        if ($isAdmin -eq $true) { return Private-ExecuteScriptBlock -ScriptBlock $ScriptBlock -VerboseOutput:$VerboseOutput -ScriptType $ScriptType -CIS_ID $CIS_ID -ServiceName $ServiceName }
        
        return $isAdmin
    }
    catch {
        $errorInfo = Handle-CISError -ErrorRecord $_ -ScriptType $ScriptType -CIS_ID $CIS_ID -ServiceName $ServiceName
        
        if ($VerboseOutput) { Private-WriteScriptErrorOutput -ErrorInfo $errorInfo }
        
        return [PSCustomObject]@{
            Status = "Failed"
            ErrorMessage = $errorInfo.ErrorMessage
            ErrorType = $errorInfo.ErrorType
            Recommendation = $errorInfo.Recommendation
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
    }
}

# Export the module members
Export-ModuleMember -Function New-CISResultObject, Get-CISRecommendation, Test-CISCompliance, Invoke-CISAudit, Test-DomainMember, Export-CISAuditResults, Get-CISAuditSummary, Invoke-CISScript -Verbose:$false
