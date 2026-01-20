<#
.SYNOPSIS
    Configuration management module for dynamic path resolution and environment support.
.DESCRIPTION
    Provides centralized configuration management with support for different deployment environments,
    dynamic path resolution, and configuration validation.
.NOTES
    File Name      : ConfigurationManager.psm1
    Author         : System Administrator
    Prerequisite   : PowerShell 5.1 or later
    
.EXAMPLE
    $config = Get-CISConfiguration
    $modulePath = Resolve-CISPath -PathType "Modules" -Environment "Development"
.EXAMPLE
    Set-CISConfiguration -Environment "Production" -BasePath "C:\CISAutomation"
#>

# Configuration data structure
$Script:CISConfiguration = @{
    # Environment settings
    Environment = "Development"
    Environments = @("Development", "Testing", "Production")
    
    # Base paths for different environments
    BasePaths = @{
        Development = "$PSScriptRoot\.."
        Testing = "C:\CISAutomation\Testing"
        Production = "C:\CISAutomation\Production"
    }
    
    # Path templates for different resource types
    PathTemplates = @{
        Modules = "{BasePath}\modules"
        Scripts = "{BasePath}\windows"
        Config = "{BasePath}\config"
        Logs = "{BasePath}\logs"
        Reports = "{BasePath}\reports"
        Templates = "{BasePath}\templates"
        Data = "{BasePath}\data"
    }
    
    # Default values
    Defaults = @{
        VerboseOutput = $false
        AutoElevate = $false
        LogLevel = "Info"
        BackupEnabled = $true
        BackupPath = "{BasePath}\backups"
    }
}

# Function to get current configuration
function Get-CISConfiguration {
    <#
    .SYNOPSIS
        Returns the current CIS configuration.
    .DESCRIPTION
        Provides access to the centralized configuration settings.
    .EXAMPLE
        $config = Get-CISConfiguration
    .OUTPUTS
        Hashtable containing configuration settings.
    #>
    return $Script:CISConfiguration
}

# Function to set configuration values
function Set-CISConfiguration {
    <#
    .SYNOPSIS
        Sets CIS configuration values.
    .DESCRIPTION
        Updates configuration settings for the current session.
    .PARAMETER Environment
        Target environment (Development, Testing, Production).
    .PARAMETER BasePath
        Custom base path for the environment.
    .PARAMETER VerboseOutput
        Enable verbose output by default.
    .PARAMETER AutoElevate
        Automatically elevate privileges.
    .PARAMETER LogLevel
        Default log level (Error, Warning, Info, Debug).
    .EXAMPLE
        Set-CISConfiguration -Environment "Production" -BasePath "D:\CISAutomation"
    #>
    param(
        [ValidateSet("Development", "Testing", "Production")]
        [string]$Environment,
        
        [string]$BasePath,
        
        [bool]$VerboseOutput,
        
        [bool]$AutoElevate,
        
        [ValidateSet("Error", "Warning", "Info", "Debug")]
        [string]$LogLevel
    )
    
    if ($Environment) {
        $Script:CISConfiguration.Environment = $Environment
    }
    
    if ($BasePath -and $Environment) {
        $Script:CISConfiguration.BasePaths[$Environment] = $BasePath
    }
    
    if ($PSBoundParameters.ContainsKey("VerboseOutput")) {
        $Script:CISConfiguration.Defaults.VerboseOutput = $VerboseOutput
    }
    
    if ($PSBoundParameters.ContainsKey("AutoElevate")) {
        $Script:CISConfiguration.Defaults.AutoElevate = $AutoElevate
    }
    
    if ($LogLevel) {
        $Script:CISConfiguration.Defaults.LogLevel = $LogLevel
    }
}

# Function to resolve paths dynamically
function Resolve-CISPath {
    <#
    .SYNOPSIS
        Resolves paths dynamically based on configuration.
    .DESCRIPTION
        Eliminates hardcoded paths by providing dynamic path resolution
        with support for different environments.
    .PARAMETER PathType
        Type of path to resolve (Modules, Scripts, Config, Logs, Reports, Templates, Data).
    .PARAMETER Environment
        Target environment. Uses current environment if not specified.
    .PARAMETER RelativePath
        Additional relative path to append.
    .PARAMETER CreateIfNotExists
        Create the directory if it doesn't exist.
    .EXAMPLE
        $modulePath = Resolve-CISPath -PathType "Modules"
    .EXAMPLE
        $logPath = Resolve-CISPath -PathType "Logs" -RelativePath "audit-logs" -CreateIfNotExists
    .OUTPUTS
        Resolved path string.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("Modules", "Scripts", "Config", "Logs", "Reports", "Templates", "Data")]
        [string]$PathType,
        
        [ValidateSet("Development", "Testing", "Production")]
        [string]$Environment,
        
        [string]$RelativePath,
        
        [switch]$CreateIfNotExists
    )
    
    # Use current environment if not specified
    if (-not $Environment) {
        $Environment = $Script:CISConfiguration.Environment
    }
    
    # Get base path for environment
    $basePath = $Script:CISConfiguration.BasePaths[$Environment]
    
    # Resolve path template
    $pathTemplate = $Script:CISConfiguration.PathTemplates[$PathType]
    $resolvedPath = $pathTemplate -replace "\{BasePath\}", $basePath
    
    # Append relative path if specified
    if ($RelativePath) {
        $resolvedPath = Join-Path $resolvedPath $RelativePath
    }
    
    # Create directory if requested and doesn't exist
    if ($CreateIfNotExists -and -not (Test-Path $resolvedPath)) {
        New-Item -ItemType Directory -Path $resolvedPath -Force | Out-Null
    }
    
    return $resolvedPath
}

# Function to validate configuration
function Test-CISConfiguration {
    <#
    .SYNOPSIS
        Validates the current CIS configuration.
    .DESCRIPTION
        Checks that all required paths exist and configuration is valid.
    .PARAMETER Environment
        Specific environment to validate.
    .EXAMPLE
        $isValid = Test-CISConfiguration
    .OUTPUTS
        Boolean indicating configuration validity.
    #>
    param(
        [ValidateSet("Development", "Testing", "Production")]
        [string]$Environment
    )
    
    if (-not $Environment) {
        $Environment = $Script:CISConfiguration.Environment
    }
    
    $basePath = $Script:CISConfiguration.BasePaths[$Environment]
    
    # Check base path exists
    if (-not (Test-Path $basePath)) {
        Write-Warning "Base path does not exist: $basePath"
        return $false
    }
    
    # Check all path templates resolve correctly
    foreach ($pathType in $Script:CISConfiguration.PathTemplates.Keys) {
        $path = Resolve-CISPath -PathType $pathType -Environment $Environment
        
        # Only check existence for critical paths
        if ($pathType -in @("Modules", "Scripts")) {
            if (-not (Test-Path $path)) {
                Write-Warning "Required path does not exist: $path"
                return $false
            }
        }
    }
    
    return $true
}

# Function to get environment-specific settings
function Get-CISEnvironmentSettings {
    <#
    .SYNOPSIS
        Returns environment-specific settings.
    .DESCRIPTION
        Provides settings tailored to the current environment.
    .PARAMETER Environment
        Target environment.
    .EXAMPLE
        $settings = Get-CISEnvironmentSettings -Environment "Production"
    .OUTPUTS
        Hashtable with environment-specific settings.
    #>
    param(
        [ValidateSet("Development", "Testing", "Production")]
        [string]$Environment
    )
    
    if (-not $Environment) {
        $Environment = $Script:CISConfiguration.Environment
    }
    
    $settings = @{
        Environment = $Environment
        BasePath = $Script:CISConfiguration.BasePaths[$Environment]
        IsProduction = ($Environment -eq "Production")
        IsDevelopment = ($Environment -eq "Development")
        IsTesting = ($Environment -eq "Testing")
    }
    
    # Add environment-specific defaults
    switch ($Environment) {
        "Development" {
            $settings.Add("VerboseOutput", $true)
            $settings.Add("LogLevel", "Debug")
            $settings.Add("BackupEnabled", $false)
        }
        "Testing" {
            $settings.Add("VerboseOutput", $true)
            $settings.Add("LogLevel", "Info")
            $settings.Add("BackupEnabled", $true)
        }
        "Production" {
            $settings.Add("VerboseOutput", $false)
            $settings.Add("LogLevel", "Warning")
            $settings.Add("BackupEnabled", $true)
        }
    }
    
    return $settings
}

# Function to import modules using configuration-based paths
function Import-CISModule {
    <#
    .SYNOPSIS
        Imports modules using configuration-based paths.
    .DESCRIPTION
        Provides centralized module import with dynamic path resolution.
    .PARAMETER ModuleName
        Name of the module to import.
    .PARAMETER Environment
        Target environment.
    .PARAMETER Force
        Force module import.
    .EXAMPLE
        Import-CISModule -ModuleName "CISFramework"
    .OUTPUTS
        Boolean indicating import success.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("CISFramework", "CISRemediation", "ServiceManager", "RegistryUtils", "WindowsUtils", "WindowsUI", "ConfigurationManager")]
        [string]$ModuleName,
        
        [ValidateSet("Development", "Testing", "Production")]
        [string]$Environment,
        
        [switch]$Force
    )
    
    try {
        $modulesPath = Resolve-CISPath -PathType "Modules" -Environment $Environment
        $modulePath = Join-Path $modulesPath "$ModuleName.psm1"
        
        if (-not (Test-Path $modulePath)) {
            Write-Error "Module file not found: $modulePath"
            return $false
        }
        
        Import-Module $modulePath -Force:$Force -WarningAction SilentlyContinue
        return $true
        
    } catch {
        Write-Error "Failed to import module '$ModuleName': $_"
        return $false
    }
}

# Export the module members
Export-ModuleMember -Function Get-CISConfiguration, Set-CISConfiguration, Resolve-CISPath, Test-CISConfiguration, Get-CISEnvironmentSettings, Import-CISModule