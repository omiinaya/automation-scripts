<#
.SYNOPSIS
    Generates service toggle scripts from a configuration file.

.DESCRIPTION
    Reads service-config.json and generates PowerShell scripts for toggling
    Windows services. Supports dry-run mode, force overwrite, and selective generation.

.PARAMETER ConfigPath
    Path to the service configuration JSON file. Default: service-config.json

.PARAMETER ServiceName
    Optional. Generate script for a specific service only.

.PARAMETER DryRun
    Preview what would be generated without creating files.

.PARAMETER Force
    Overwrite existing scripts without prompting.

.EXAMPLE
    .\generate-service-toggles.ps1
    Generate all service toggle scripts.

.EXAMPLE
    .\generate-service-toggles.ps1 -ServiceName "bthserv"
    Generate only the Bluetooth Support Service script.

.EXAMPLE
    .\generate-service-toggles.ps1 -DryRun
    Preview what would be generated.

.EXAMPLE
    .\generate-service-toggles.ps1 -Force
    Generate all scripts, overwriting existing ones.
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$ConfigPath = "service-config.json",
    [string]$ServiceName = "",
    [switch]$DryRun,
    [switch]$Force
)

function Get-ScriptDirectory {
    $scriptPath = $MyInvocation.PSCommandPath
    if ($scriptPath) {
        Split-Path -Parent $scriptPath
    } else {
        $PSScriptRoot
    }
}

function Read-ServiceConfig {
    param([string]$Path)
    
    if (-not (Test-Path $Path)) {
        throw "Configuration file not found: $Path"
    }
    
    $content = Get-Content $Path -Raw
    $config = $content | ConvertFrom-Json
    
    if (-not $config.services) {
        throw "Invalid configuration: missing 'services' array"
    }
    
    return $config.services
}

function ConvertTo-KebabCase {
    param([string]$InputString)
    
    $result = $InputString -creplace '([a-z])([A-Z])', '$1-$2'
    $result = $result -creplace '([A-Z]+)([A-Z][a-z])', '$1-$2'
    $result = $result.ToLower()
    $result = $result -replace '\s+', '-'
    $result = $result -replace '[^a-z0-9-]', ''
    
    return $result
}

function Get-ScriptFileName {
    param(
        [string]$ServiceName,
        [string]$DisplayName
    )
    
    $kebabName = ConvertTo-KebabCase -InputString $DisplayName
    return "toggle-$kebabName-service.ps1"
}

function Generate-ScriptContent {
    param(
        [string]$ServiceName,
        [string]$DisplayName
    )
    
    $content = @"
# Toggle $DisplayName ($ServiceName) startup type on Windows
# Enable/Disable service startup instead of starting/stopping the service
# Refactored to use modular CISFramework system with automatic elevation

# Import the ModuleIndex module which includes all modules including ServiceManager
`$modulePath = Join-Path `$PSScriptRoot "..\..\..\modules\ModuleIndex.psm1"
Import-Module `$modulePath -Force -WarningAction SilentlyContinue

# Toggle the $DisplayName using the CISFramework with automatic elevation
Invoke-CISScript -ScriptType "ServiceToggle" -ServiceName "$ServiceName" -ServiceDisplayName "$DisplayName" -AutoElevate -ScriptBlock {
    Invoke-ServiceToggle -ServiceName "$ServiceName" -ServiceDisplayName "$DisplayName" -EnableStartupType "Manual" -SkipAdminCheck
}
"@
    
    return $content
}

function Write-ServiceScript {
    param(
        [string]$Content,
        [string]$OutputPath,
        [bool]$DryRun,
        [bool]$Force
    )
    
    $exists = Test-Path $OutputPath
    
    if ($exists -and -not $Force) {
        Write-Warning "Script already exists: $OutputPath (use -Force to overwrite)"
        return $false
    }
    
    if ($DryRun) {
        Write-Host "[DRY RUN] Would create: $OutputPath" -ForegroundColor Cyan
        return $true
    }
    
    $directory = Split-Path -Parent $OutputPath
    if (-not (Test-Path $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }
    
    Set-Content -Path $OutputPath -Value $Content -Encoding UTF8
    Write-Host "Created: $OutputPath" -ForegroundColor Green
    return $true
}

function Invoke-Generation {
    param(
        [array]$Services,
        [string]$OutputDir,
        [string]$TargetService,
        [bool]$DryRun,
        [bool]$Force
    )
    
    $count = 0
    $skipped = 0
    
    foreach ($service in $Services) {
        if ($TargetService -and $service.name -ne $TargetService) {
            continue
        }
        
        $fileName = Get-ScriptFileName -ServiceName $service.name -DisplayName $service.displayName
        $outputPath = Join-Path $OutputDir $fileName
        $content = Generate-ScriptContent -ServiceName $service.name -DisplayName $service.displayName
        
        if (Write-ServiceScript -Content $content -OutputPath $outputPath -DryRun $DryRun -Force $Force) {
            $count++
        } else {
            $skipped++
        }
    }
    
    return @{ Created = $count; Skipped = $skipped }
}

function Show-Summary {
    param(
        [hashtable]$Results,
        [bool]$DryRun
    )
    
    $action = if ($DryRun) { "Would create" } else { "Created" }
    Write-Host "`nSummary:" -ForegroundColor Cyan
    Write-Host "  $action $($Results.Created) script(s)" -ForegroundColor Green
    if ($Results.Skipped -gt 0) {
        Write-Host "  Skipped $($Results.Skipped) script(s)" -ForegroundColor Yellow
    }
}

try {
    $scriptDir = Get-ScriptDirectory
    $configPath = Join-Path $scriptDir $ConfigPath
    $outputDir = $scriptDir
    
    Write-Host "Reading configuration from: $configPath" -ForegroundColor Cyan
    $services = Read-ServiceConfig -Path $configPath
    
    Write-Host "Found $($services.Count) service(s) in configuration" -ForegroundColor Cyan
    
    if ($ServiceName) {
        Write-Host "Generating script for service: $ServiceName" -ForegroundColor Cyan
    } else {
        Write-Host "Generating scripts for all services" -ForegroundColor Cyan
    }
    
    if ($DryRun) {
        Write-Host "DRY RUN MODE - No files will be created" -ForegroundColor Yellow
    }
    
    $results = Invoke-Generation -Services $services -OutputDir $outputDir -TargetService $ServiceName -DryRun $DryRun -Force $Force
    Show-Summary -Results $results -DryRun $DryRun
    
    exit 0
}
catch {
    Write-Error "Error: $_"
    exit 1
}
