<#
.SYNOPSIS
    CIS Remediation Framework Module for Windows security compliance remediation.
.DESCRIPTION
    Provides standardized functions for CIS benchmark remediation with common patterns,
    confirmation dialogs, result object creation, and template-based remediation.
.NOTES
    File Name      : CISRemediation.psm1
    Author         : System Administrator
    Prerequisite   : PowerShell 5.1 or later
    Dependencies   : WindowsUtils, RegistryUtils, WindowsUI, CISFramework modules
#>

# Import required modules
Import-Module "$PSScriptRoot\WindowsUtils.psm1" -Force -WarningAction SilentlyContinue
Import-Module "$PSScriptRoot\RegistryUtils.psm1" -Force -WarningAction SilentlyContinue
Import-Module "$PSScriptRoot\WindowsUI.psm1" -Force -WarningAction SilentlyContinue
Import-Module "$PSScriptRoot\CISFramework.psm1" -Force -WarningAction SilentlyContinue

# Function to create standardized CIS remediation result object
function New-CISRemediationResult {
    <#
    .SYNOPSIS
        Creates a standardized CIS remediation result object.
    .DESCRIPTION
        Returns a consistent object structure for CIS remediation results with all required properties.
    .PARAMETER CIS_ID
        The CIS benchmark ID (e.g., "1.1.1").
    .PARAMETER Title
        The title of the CIS recommendation.
    .PARAMETER PreviousValue
        The value before remediation.
    .PARAMETER NewValue
        The value after remediation.
    .PARAMETER Status
        The remediation status (Remediated, ManualActionRequired, Failed, Cancelled, Error).
    .PARAMETER Message
        Detailed message about the remediation result.
    .PARAMETER IsCompliant
        Whether the system is now compliant.
    .PARAMETER RequiresManualAction
        Whether manual action is required.
    .PARAMETER Source
        The source of the remediation (Local Policy, Domain Policy, Registry, etc.).
    .PARAMETER ErrorMessage
        Error message if the remediation failed.
    .EXAMPLE
        $result = New-CISRemediationResult -CIS_ID "1.1.1" -Title "Enforce password history" -PreviousValue "0" -NewValue "24" -Status "Remediated" -Message "Successfully updated password history" -IsCompliant $true
    .OUTPUTS
        PSCustomObject
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$CIS_ID,
        
        [Parameter(Mandatory=$true)]
        [string]$Title,
        
        [Parameter(Mandatory=$true)]
        [object]$PreviousValue,
        
        [Parameter(Mandatory=$true)]
        [object]$NewValue,
        
        [Parameter(Mandatory=$true)]
        [ValidateSet("Remediated", "ManualActionRequired", "Failed", "Cancelled", "Error", "PartiallyRemediated")]
        [string]$Status,
        
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$true)]
        [bool]$IsCompliant,
        
        [Parameter(Mandatory=$true)]
        [bool]$RequiresManualAction,
        
        [string]$Source = "Unknown",
        
        [string]$ErrorMessage = ""
    )
    
    $remediationTimestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    return [PSCustomObject]@{
        CIS_ID = $CIS_ID
        Title = $Title
        PreviousValue = $PreviousValue
        NewValue = $NewValue
        Status = $Status
        Message = $Message
        IsCompliant = $IsCompliant
        RequiresManualAction = $RequiresManualAction
        Source = $Source
        ErrorMessage = $ErrorMessage
        RemediationTimestamp = $remediationTimestamp
        ComputerName = $env:COMPUTERNAME
        UserName = $env:USERNAME
    }
}

# Function to apply security policy template using secedit
function Set-SecurityPolicyTemplate {
    <#
    .SYNOPSIS
        Applies a security policy template using secedit.
    .DESCRIPTION
        Creates and applies a temporary security policy template for local policy remediation.
    .PARAMETER CIS_ID
        The CIS benchmark ID.
    .PARAMETER TemplateContent
        The content of the security policy template.
    .PARAMETER SettingName
        The name of the setting being remediated.
    .PARAMETER VerboseOutput
        Enable verbose output.
    .EXAMPLE
        $result = Apply-SecurityPolicyTemplate -CIS_ID "1.1.1" -TemplateContent $template -SettingName "PasswordHistorySize" -VerboseOutput
    .OUTPUTS
        PSCustomObject
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$CIS_ID,
        
        [Parameter(Mandatory=$true)]
        [string]$TemplateContent,
        
        [Parameter(Mandatory=$true)]
        [string]$SettingName,
        
        [switch]$VerboseOutput
    )
    
    try {
        # Get CIS recommendation
        $recommendation = Get-CISRecommendation -CIS_ID $CIS_ID
        
        if (-not $recommendation) {
            return New-CISRemediationResult -CIS_ID $CIS_ID -Title "Unknown" -PreviousValue "Unknown" -NewValue "Unknown" -Status "Error" -Message "CIS recommendation not found" -IsCompliant $false -RequiresManualAction $true
        }
        
        # Create temporary template file
        $templateFile = [System.IO.Path]::GetTempFileName()
        $TemplateContent | Out-File -FilePath $templateFile -Encoding Unicode
        
        if ($VerboseOutput) {
            Write-StatusMessage -Message "Applying security policy template..." -Type Info
        }
        
        # Apply the security policy
        secedit /configure /db secedit.sdb /cfg $templateFile /quiet
        
        if ($LASTEXITCODE -eq 0) {
            if ($VerboseOutput) {
                Write-StatusMessage -Message "Security policy applied successfully" -Type Success
                Write-StatusMessage -Message "Verifying remediation..." -Type Info
            }
            
            Start-Sleep -Seconds 2
            
            # Verify the change
            $verifyTempFile = [System.IO.Path]::GetTempFileName()
            secedit /export /cfg $verifyTempFile /quiet
            $verifyContent = Get-Content $verifyTempFile
            $verifyLine = $verifyContent | Where-Object { $_ -like "$SettingName*" }
            
            if ($verifyLine) {
                $newValue = [int]($verifyLine -split "=")[1].Trim()
                
                # Clean up temp files
                Remove-Item $verifyTempFile -ErrorAction SilentlyContinue
                Remove-Item $templateFile -ErrorAction SilentlyContinue
                
                return New-CISRemediationResult -CIS_ID $CIS_ID -Title $recommendation.title -PreviousValue "Unknown" -NewValue $newValue -Status "Remediated" -Message "$SettingName successfully updated to $newValue" -IsCompliant $true -RequiresManualAction $false -Source "Local Policy"
            } else {
                # Clean up temp files
                Remove-Item $verifyTempFile -ErrorAction SilentlyContinue
                Remove-Item $templateFile -ErrorAction SilentlyContinue
                
                return New-CISRemediationResult -CIS_ID $CIS_ID -Title $recommendation.title -PreviousValue "Unknown" -NewValue "Unknown" -Status "PartiallyRemediated" -Message "Unable to verify $SettingName after remediation" -IsCompliant $false -RequiresManualAction $false -Source "Local Policy"
            }
        } else {
            # Clean up temp file
            Remove-Item $templateFile -ErrorAction SilentlyContinue
            
            return New-CISRemediationResult -CIS_ID $CIS_ID -Title $recommendation.title -PreviousValue "Unknown" -NewValue "Unknown" -Status "Failed" -Message "Failed to apply security policy (exit code: $LASTEXITCODE)" -IsCompliant $false -RequiresManualAction $true -Source "Local Policy"
        }
    }
    catch {
        return New-CISRemediationResult -CIS_ID $CIS_ID -Title "Error" -PreviousValue "Unknown" -NewValue "Unknown" -Status "Error" -Message "Failed to apply security policy template: $($_.Exception.Message)" -IsCompliant $false -RequiresManualAction $true -ErrorMessage $_.Exception.Message
    }
}

# Function to get domain remediation instructions
function Get-DomainRemediationInstructions {
    <#
    .SYNOPSIS
        Returns domain-specific remediation instructions.
    .DESCRIPTION
        Provides standardized instructions for domain policy remediation.
    .PARAMETER CIS_ID
        The CIS benchmark ID.
    .PARAMETER SettingName
        The name of the setting being remediated.
    .PARAMETER RecommendedValue
        The recommended value.
    .EXAMPLE
        $instructions = Get-DomainRemediationInstructions -CIS_ID "1.1.1" -SettingName "Enforce password history" -RecommendedValue "24 or more"
    .OUTPUTS
        PSCustomObject
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$CIS_ID,
        
        [Parameter(Mandatory=$true)]
        [string]$SettingName,
        
        [Parameter(Mandatory=$true)]
        [string]$RecommendedValue
    )
    
    $instructions = @"
DOMAIN REMEDIATION INSTRUCTIONS:
================================
1. Open Group Policy Management Console (gpmc.msc)
2. Navigate to: Default Domain Policy
3. Edit: Computer Configuration\Policies\Windows Settings\Security Settings\Account Policies\Password Policy
4. Set '$SettingName' to $RecommendedValue
5. Apply the policy and run 'gpupdate /force' on all domain computers

Note: Domain policy changes require domain administrator privileges
"@
    
    return [PSCustomObject]@{
        CIS_ID = $CIS_ID
        SettingName = $SettingName
        RecommendedValue = $RecommendedValue
        Instructions = $instructions
        ManualActionRequired = $true
    }
}

# Function to invoke CIS remediation with confirmation
function Invoke-CISRemediation {
    <#
    .SYNOPSIS
        Generic CIS remediation function with confirmation dialog.
    .DESCRIPTION
        Provides a standardized framework for CIS remediation with support for registry,
        security policy, and custom remediation patterns.
    .PARAMETER CIS_ID
        The CIS benchmark ID to remediate.
    .PARAMETER RemediationType
        The type of remediation to perform (SecurityPolicy, Registry, Custom).
    .PARAMETER SecurityPolicyTemplate
        Security policy template content for SecurityPolicy remediation.
    .PARAMETER SettingName
        The name of the setting being remediated.
    .PARAMETER RegistryPath
        Registry path for registry-based remediation.
    .PARAMETER RegistryValueName
        Registry value name for registry-based remediation.
    .PARAMETER RegistryValueData
        Registry value data for registry-based remediation.
    .PARAMETER RegistryValueType
        Registry value type for registry-based remediation.
    .PARAMETER CustomScriptBlock
        Custom script block for complex remediation.
    .PARAMETER VerboseOutput
        Enable verbose output.
    .PARAMETER AutoConfirm
        Automatically confirm remediation without user prompt.
    .PARAMETER Section
        CIS section number for recommendation lookup.
    .EXAMPLE
        $result = Invoke-CISRemediation -CIS_ID "1.1.1" -RemediationType "SecurityPolicy" -SecurityPolicyTemplate $template -SettingName "PasswordHistorySize" -VerboseOutput
    .EXAMPLE
        $result = Invoke-CISRemediation -CIS_ID "2.3.1.1" -RemediationType "Registry" -RegistryPath "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer" -RegistryValueName "Start" -RegistryValueData 4 -RegistryValueType "DWord"
    .OUTPUTS
        PSCustomObject
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$CIS_ID,
        
        [Parameter(Mandatory=$true)]
        [ValidateSet("SecurityPolicy", "Registry", "Custom")]
        [string]$RemediationType,
        
        [string]$SecurityPolicyTemplate,
        
        [string]$SettingName,
        
        [string]$RegistryPath,
        
        [string]$RegistryValueName,
        
        [object]$RegistryValueData,
        
        [ValidateSet("String", "DWord", "QWord", "Binary", "MultiString", "ExpandString")]
        [string]$RegistryValueType = "DWord",
        
        [scriptblock]$CustomScriptBlock,
        
        [switch]$VerboseOutput,
        
        [switch]$AutoConfirm,
        
        [string]$Section
    )
    
    try {
        # Get CIS recommendation
        $recommendation = Get-CISRecommendation -CIS_ID $CIS_ID -Section $Section
        
        # Use default title if recommendation not found
        if (-not $recommendation) {
            $recommendation = [PSCustomObject]@{
                title = "CIS Benchmark $CIS_ID"
            }
        }
        
        # Check if computer is domain member
        $isDomainMember = Test-DomainMember
        
        if ($isDomainMember) {
            # Domain environment requires manual action
            $domainInstructions = Get-DomainRemediationInstructions -CIS_ID $CIS_ID -SettingName $recommendation.title -RecommendedValue $recommendation.title
            
            if ($VerboseOutput) {
                Write-Host ""
                Write-SectionHeader -Title "Domain Environment Detected"
                Write-Host $domainInstructions.Instructions -ForegroundColor Yellow
            }
            
            return New-CISRemediationResult -CIS_ID $CIS_ID -Title $recommendation.title -PreviousValue "Unknown" -NewValue "Unknown" -Status "ManualActionRequired" -Message "Domain environment requires manual policy changes" -IsCompliant $false -RequiresManualAction $true -Source "Domain Policy"
        }
        
        # For standalone systems, perform remediation
        if ($VerboseOutput) {
            Write-Host ""
            Write-SectionHeader -Title "CIS Remediation: $CIS_ID"
            Write-Host "Setting: $($recommendation.title)" -ForegroundColor White
            Write-Host "Recommended: $($recommendation.title)" -ForegroundColor White
            Write-Host ""
        }
        
        # Get user confirmation (unless AutoConfirm is specified)
        if (-not $AutoConfirm -and $VerboseOutput) {
            if (-not (Show-Confirmation -Message "Do you want to proceed with remediation?" -DefaultChoice "No")) {
                return New-CISRemediationResult -CIS_ID $CIS_ID -Title $recommendation.title -PreviousValue "Unknown" -NewValue "Unknown" -Status "Cancelled" -Message "User cancelled remediation" -IsCompliant $false -RequiresManualAction $false -Source "User Cancelled"
            }
        }
        
        # Perform remediation based on type
        $result = $null
        
        switch ($RemediationType) {
            "SecurityPolicy" {
                if (-not $SecurityPolicyTemplate -or -not $SettingName) {
                    return New-CISRemediationResult -CIS_ID $CIS_ID -Title $recommendation.title -PreviousValue "Unknown" -NewValue "Unknown" -Status "Error" -Message "Security policy template and setting name required" -IsCompliant $false -RequiresManualAction $true
                }
                
                $result = Set-SecurityPolicyTemplate -CIS_ID $CIS_ID -TemplateContent $SecurityPolicyTemplate -SettingName $SettingName -VerboseOutput:$VerboseOutput
            }
            
            "Registry" {
                if (-not $RegistryPath -or -not $RegistryValueName -or -not $RegistryValueData) {
                    return New-CISRemediationResult -CIS_ID $CIS_ID -Title $recommendation.title -PreviousValue "Unknown" -NewValue "Unknown" -Status "Error" -Message "Registry path, value name, and value data required" -IsCompliant $false -RequiresManualAction $true
                }
                
                try {
                    # Set registry value
                    Set-RegistryValue -KeyPath $RegistryPath -ValueName $RegistryValueName -ValueData $RegistryValueData -ValueType $RegistryValueType
                    
                    if ($VerboseOutput) {
                        Write-StatusMessage -Message "Registry value set successfully" -Type Success
                    }
                    
                    $result = New-CISRemediationResult -CIS_ID $CIS_ID -Title $recommendation.title -PreviousValue "Unknown" -NewValue $RegistryValueData -Status "Remediated" -Message "Registry value successfully updated" -IsCompliant $true -RequiresManualAction $false -Source "Registry"
                }
                catch {
                    $result = New-CISRemediationResult -CIS_ID $CIS_ID -Title $recommendation.title -PreviousValue "Unknown" -NewValue "Unknown" -Status "Error" -Message "Failed to set registry value: $($_.Exception.Message)" -IsCompliant $false -RequiresManualAction $true -ErrorMessage $_.Exception.Message
                }
            }
            
            "Custom" {
                if (-not $CustomScriptBlock) {
                    return New-CISRemediationResult -CIS_ID $CIS_ID -Title $recommendation.title -PreviousValue "Unknown" -NewValue "Unknown" -Status "Error" -Message "Custom script block required for custom remediation" -IsCompliant $false -RequiresManualAction $true
                }
                
                try {
                    $customResult = & $CustomScriptBlock
                    $result = New-CISRemediationResult -CIS_ID $CIS_ID -Title $recommendation.title -PreviousValue $customResult.PreviousValue -NewValue $customResult.NewValue -Status "Remediated" -Message "Custom remediation completed successfully" -IsCompliant $true -RequiresManualAction $false -Source "Custom"
                }
                catch {
                    $result = New-CISRemediationResult -CIS_ID $CIS_ID -Title $recommendation.title -PreviousValue "Unknown" -NewValue "Unknown" -Status "Error" -Message "Custom remediation failed: $($_.Exception.Message)" -IsCompliant $false -RequiresManualAction $true -ErrorMessage $_.Exception.Message
                }
            }
        }
        
        # Output verbose information if requested
        if ($VerboseOutput -and $result) {
            Write-Host ""
            Write-SectionHeader -Title "Remediation Summary"
            Write-Host "Setting: $($result.Title)" -ForegroundColor White
            Write-Host "Previous Value: $($result.PreviousValue)" -ForegroundColor White
            Write-Host "New Value: $($result.NewValue)" -ForegroundColor White
            Write-Host "Status: $($result.Status)" -ForegroundColor $(if ($result.IsCompliant) { "Green" } else { "Red" })
            Write-Host "Message: $($result.Message)" -ForegroundColor White
            Write-Host "Source: $($result.Source)" -ForegroundColor White
        }
        
        return $result
    }
    catch {
        return New-CISRemediationResult -CIS_ID $CIS_ID -Title "Error" -PreviousValue "Unknown" -NewValue "Unknown" -Status "Error" -Message "Remediation failed: $_" -IsCompliant $false -RequiresManualAction $true -ErrorMessage $_
    }
}

# Function to export remediation results to CSV
function Export-CISRemediationResults {
    <#
    .SYNOPSIS
        Exports CIS remediation results to CSV file.
    .DESCRIPTION
        Creates a CSV file containing remediation results for reporting and analysis.
    .PARAMETER Results
        Array of CIS remediation result objects.
    .PARAMETER OutputPath
        Path where the CSV file will be saved.
    .EXAMPLE
        Export-CISRemediationResults -Results $remediationResults -OutputPath "C:\remediation\results.csv"
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
        
        Write-StatusMessage -Message "Remediation results exported to: $OutputPath" -Type Success
    }
    catch {
        Write-Error "Failed to export remediation results: $_"
    }
}

# Function to generate remediation summary report
function Get-CISRemediationSummary {
    <#
    .SYNOPSIS
        Generates a summary report from CIS remediation results.
    .DESCRIPTION
        Creates a summary object with remediation statistics and overall status.
    .PARAMETER Results
        Array of CIS remediation result objects.
    .EXAMPLE
        $summary = Get-CISRemediationSummary -Results $remediationResults
    .OUTPUTS
        PSCustomObject
    #>
    param(
        [Parameter(Mandatory=$true)]
        [array]$Results
    )
    
    $totalRemediations = $Results.Count
    $successfulRemediations = ($Results | Where-Object { $_.Status -eq "Remediated" }).Count
    $manualActionRequired = ($Results | Where-Object { $_.RequiresManualAction }).Count
    $failedRemediations = ($Results | Where-Object { $_.Status -eq "Failed" -or $_.Status -eq "Error" }).Count
    $cancelledRemediations = ($Results | Where-Object { $_.Status -eq "Cancelled" }).Count
    $partiallyRemediated = ($Results | Where-Object { $_.Status -eq "PartiallyRemediated" }).Count
    
    $successPercentage = if ($totalRemediations -gt 0) { [math]::Round(($successfulRemediations / $totalRemediations) * 100, 2) } else { 0 }
    
    $overallStatus = if ($successPercentage -ge 90) { "Excellent" }
                     elseif ($successPercentage -ge 75) { "Good" }
                     elseif ($successPercentage -ge 50) { "Fair" }
                     else { "Poor" }
    
    return [PSCustomObject]@{
        TotalRemediations = $totalRemediations
        SuccessfulRemediations = $successfulRemediations
        ManualActionRequired = $manualActionRequired
        FailedRemediations = $failedRemediations
        CancelledRemediations = $cancelledRemediations
        PartiallyRemediated = $partiallyRemediated
        SuccessPercentage = $successPercentage
        OverallStatus = $overallStatus
        RemediationTimestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        ComputerName = $env:COMPUTERNAME
    }
}

# Export the module members
Export-ModuleMember -Function New-CISRemediationResult, Set-SecurityPolicyTemplate, Get-DomainRemediationInstructions, Invoke-CISRemediation, Export-CISRemediationResults, Get-CISRemediationSummary