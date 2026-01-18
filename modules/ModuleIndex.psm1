<#
.SYNOPSIS
    Main index module for importing all Windows utility modules.
.DESCRIPTION
    Provides a centralized way to import all Windows utility modules.
    This module serves as the main entry point for using the Windows automation modules.
.NOTES
    File Name      : ModuleIndex.psm1
    Author         : System Administrator
    Prerequisite   : PowerShell 5.1 or later
    
.EXAMPLE
    Import-Module .\modules\ModuleIndex.psm1
    Get-Command -Module ModuleIndex
    
.EXAMPLE
    Import-Module .\modules\ModuleIndex.psm1
    Test-AdminRights
    Get-PowerSchemes
    Write-StatusMessage -Message "System ready" -Type Success
#>

# Get the directory where this module is located
$script:ModuleRoot = $PSScriptRoot

# Import all modules
$modulesToImport = @(
    "WindowsUtils.psm1"
    "PowerManagement.psm1"
    "RegistryUtils.psm1"
    "WindowsUI.psm1"
    "CISFramework.psm1"
    "CISRemediation.psm1"
)

foreach ($module in $modulesToImport) {
    $modulePath = Join-Path -Path $script:ModuleRoot -ChildPath $module
    
    if (Test-Path -Path $modulePath) {
        try {
            Write-Verbose "Importing module: $module"
            Import-Module -Name $modulePath -Force -ErrorAction Stop -WarningAction SilentlyContinue
        }
        catch {
            Write-Warning "Failed to import module $module : $_"
        }
    } else {
        Write-Warning "Module file not found: $modulePath"
    }
}

# Function to show module information
function Get-WindowsModuleInfo {
    <#
    .SYNOPSIS
        Displays information about the loaded Windows modules.
    .DESCRIPTION
        Shows version information and available commands for each module.
    .EXAMPLE
        Get-WindowsModuleInfo
    .OUTPUTS
        PSCustomObject[]
    #>
    
    $modules = @(
        @{
            Name = "WindowsUtils"
            Description = "Administrative privilege checks, elevation, and common utilities"
            Commands = @(
                "Test-AdminRights",
                "Invoke-Elevation",
                "Get-SystemInfo",
                "Get-CurrentUserInfo",
                "Test-ServiceExists",
                "Restart-ServiceSafely",
                "Wait-ProcessExit"
            )
        },
        @{
            Name = "PowerManagement"
            Description = "Power scheme operations and power management"
            Commands = @(
                "Get-PowerSchemes",
                "Get-ActivePowerScheme",
                "Set-PowerScheme",
                "Set-HighPerformanceScheme",
                "Set-BalancedScheme",
                "Set-PowerSaverScheme",
                "Disable-SleepMode",
                "Enable-SleepMode",
                "Disable-ScreenTimeout",
                "Enable-ScreenTimeout",
                "Set-LidCloseAction",
                "Get-BatteryInfo",
                "Get-Windows11PowerMode",
                "Set-Windows11PowerMode",
                "Switch-Windows11PowerMode"
            )
        },
        @{
            Name = "RegistryUtils"
            Description = "Registry operations and manipulation"
            Commands = @(
                "Test-RegistryKey",
                "Test-RegistryValue",
                "Get-RegistryValue",
                "Set-RegistryValue",
                "Remove-RegistryValue",
                "Remove-RegistryKey",
                "New-RegistryKey",
                "Export-RegistryKey",
                "Import-RegistryFile",
                "Find-RegistryValue"
            )
        },
        @{
            Name = "WindowsUI"
            Description = "Consistent UI output and formatting"
            Commands = @(
                "Write-StatusMessage",
                "Write-SectionHeader",
                "Write-ProgressBar",
                "Show-Menu",
                "Show-Confirmation",
                "Show-Table",
                "Show-List",
                "Show-Pause",
                "Clear-ScreenWithHeader",
                "Show-SystemBanner"
            )
        },
        @{
            Name = "CISFramework"
            Description = "CIS benchmark auditing framework for Windows security compliance"
            Commands = @(
                "New-CISResultObject",
                "Get-CISRecommendation",
                "Test-CISCompliance",
                "Invoke-CISAudit",
                "Test-DomainMember",
                "Export-CISAuditResults",
                "Get-CISAuditSummary"
            )
        },
        @{
            Name = "CISRemediation"
            Description = "CIS benchmark remediation framework for Windows security compliance"
            Commands = @(
                "New-CISRemediationResult",
                "Apply-SecurityPolicyTemplate",
                "Get-DomainRemediationInstructions",
                "Invoke-CISRemediation",
                "Export-CISRemediationResults",
                "Get-CISRemediationSummary"
            )
        }
    )
    
    $moduleInfo = foreach ($module in $modules) {
        [PSCustomObject]@{
            ModuleName = $module.Name
            Description = $module.Description
            CommandCount = $module.Commands.Count
            Commands = $module.Commands -join ", "
            Status = if (Get-Module -Name $module.Name -ErrorAction SilentlyContinue) { "Loaded" } else { "Not Loaded" }
        }
    }
    
    return $moduleInfo
}

# Function to test all modules
function Test-WindowsModules {
    <#
    .SYNOPSIS
        Tests all loaded Windows modules.
    .DESCRIPTION
        Runs basic tests to ensure all modules are loaded correctly.
    .EXAMPLE
        Test-WindowsModules
    #>
    
    Write-SectionHeader -Title "Testing Windows Modules"
    
    $tests = @(
        @{
            Name = "Admin Rights Check"
            Test = { Test-AdminRights }
            Module = "WindowsUtils"
        },
        @{
            Name = "Power Schemes"
            Test = { Get-PowerSchemes | Measure-Object | Select-Object -ExpandProperty Count }
            Module = "PowerManagement"
        },
        @{
            Name = "Registry Key Test"
            Test = { Test-RegistryKey -KeyPath "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion" }
            Module = "RegistryUtils"
        },
        @{
            Name = "Status Message"
            Test = { Write-StatusMessage -Message "Test message" -Type Info; return $true }
            Module = "WindowsUI"
        },
        @{
            Name = "CIS Framework"
            Test = { New-CISResultObject -CIS_ID "1.1.1" -Title "Test" -CurrentValue "Test" -RecommendedValue "Test" -ComplianceStatus "Compliant" }
            Module = "CISFramework"
        },
        @{
            Name = "CIS Remediation"
            Test = { New-CISRemediationResult -CIS_ID "1.1.1" -Title "Test" -PreviousValue "Test" -NewValue "Test" -Status "Remediated" -Message "Test" -IsCompliant $true -RequiresManualAction $false }
            Module = "CISRemediation"
        }
    )
    
    foreach ($test in $tests) {
        Write-Host "Testing $($test.Name)... " -NoNewline
        try {
            $result = & $test.Test
            if ($result -ne $null) {
                Write-StatusMessage -Message "PASS ($result)" -Type Success
            } else {
                Write-StatusMessage -Message "PASS" -Type Success
            }
        }
        catch {
            Write-StatusMessage -Message "FAIL - $($_.Exception.Message)" -Type Error
        }
    }
}

# Function to get all available commands
function Get-WindowsModuleCommands {
    <#
    .SYNOPSIS
        Gets all available commands from the Windows modules.
    .DESCRIPTION
        Returns a list of all commands available in the loaded modules.
    .EXAMPLE
        Get-WindowsModuleCommands
    .OUTPUTS
        PSCustomObject[]
    #>
    
    $commands = @()
    
    $moduleCommands = Get-Command -Module WindowsUtils, PowerManagement, RegistryUtils, WindowsUI, CISFramework, CISRemediation -ErrorAction SilentlyContinue
    
    foreach ($cmd in $moduleCommands) {
        $commands += [PSCustomObject]@{
            CommandName = $cmd.Name
            ModuleName = $cmd.ModuleName
            CommandType = $cmd.CommandType
            Synopsis = if ($cmd.HelpUri) { "See help documentation" } else { "No help available" }
        }
    }
    
    return $commands | Sort-Object ModuleName, CommandName
}

# Function to display help for a command
function Show-WindowsModuleHelp {
    <#
    .SYNOPSIS
        Displays help for a specific command.
    .DESCRIPTION
        Displays detailed help for a Windows module command.
    .PARAMETER CommandName
        The name of the command to show help for.
    .EXAMPLE
        Show-WindowsModuleHelp -CommandName "Test-AdminRights"
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$CommandName
    )
    
    try {
        $command = Get-Command -Name $CommandName -ErrorAction Stop
        
        Write-SectionHeader -Title "Help: $CommandName"
        
        # Get help information
        $help = Get-Help -Name $CommandName -ErrorAction SilentlyContinue
        
        if ($help) {
            Write-Host "Module: $($command.ModuleName)" -ForegroundColor Cyan
            Write-Host "Type: $($command.CommandType)" -ForegroundColor Cyan
            Write-Host ""
            
            if ($help.Synopsis) {
                Write-Host "SYNOPSIS:" -ForegroundColor Yellow
                Write-Host $help.Synopsis -ForegroundColor White
                Write-Host ""
            }
            
            if ($help.Description) {
                Write-Host "DESCRIPTION:" -ForegroundColor Yellow
                Write-Host $help.Description.Text -ForegroundColor White
                Write-Host ""
            }
            
            if ($help.Examples) {
                Write-Host "EXAMPLES:" -ForegroundColor Yellow
                foreach ($example in $help.Examples.Example) {
                    Write-Host $example.Code -ForegroundColor Green
                    if ($example.Remarks) {
                        Write-Host $example.Remarks.Text -ForegroundColor Gray
                    }
                    Write-Host ""
                }
            }
        } else {
            Write-StatusMessage -Message "No help available for command: $CommandName" -Type Warning
        }
    }
    catch {
        Write-StatusMessage -Message "Command not found: $CommandName" -Type Error
    }
}

# Function to initialize the Windows modules environment
function Initialize-WindowsModules {
    <#
    .SYNOPSIS
        Initializes the Windows modules environment.
    .DESCRIPTION
        Sets up the environment and displays welcome information.
    .EXAMPLE
        Initialize-WindowsModules
    #>
    
    Clear-ScreenWithHeader -Title "Windows Administration Modules"
    
    Show-SystemBanner
    
    Write-StatusMessage -Message "Windows modules loaded successfully!" -Type Success
    Write-Host ""
    
    $moduleInfo = Get-WindowsModuleInfo
    Show-Table -Data $moduleInfo -Title "Available Modules"
    
    Write-Host ""
    Write-StatusMessage -Message "Use 'Get-WindowsModuleCommands' to see all available commands" -Type Info
    Write-StatusMessage -Message "Use 'Show-WindowsModuleHelp -CommandName <Command>' for detailed help" -Type Info
    Write-Host ""
}

# Initialize on import
Write-Verbose "Windows Module Index loaded successfully"
Write-Verbose "Use Initialize-WindowsModules to display welcome information"

# Export the module members
Export-ModuleMember -Function Get-WindowsModuleInfo, Test-WindowsModules, Get-WindowsModuleCommands, Show-WindowsModuleHelp, Initialize-WindowsModules

# Export all functions from imported modules
$allCommands = Get-Command -Module WindowsUtils, PowerManagement, RegistryUtils, WindowsUI, CISFramework, CISRemediation -ErrorAction SilentlyContinue
Export-ModuleMember -Function $allCommands.Name -ErrorAction SilentlyContinue