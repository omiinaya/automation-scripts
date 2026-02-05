#requires -Version 5.1
<#
.SYNOPSIS
    Removes local Wait-OnError functions from optimization scripts.
.DESCRIPTION
    This script finds and removes local Wait-OnError function definitions
    from optimization scripts since the function is already provided by
    the CommonUtilities module.
.EXAMPLE
    .\remove-local-wait-on-error.ps1
.NOTES
    Run this script from the project root directory.
#>

param(
    [Parameter()]
    [switch]$WhatIf
)

$optimizationPath = "windows/optimization"
$scriptsModified = 0
$errors = @()

# Get all PowerShell files in the optimization directory
$files = Get-ChildItem -Path $optimizationPath -Filter "*.ps1" -Recurse

Write-Host "Found $($files.Count) PowerShell files in optimization directory" -ForegroundColor Cyan
Write-Host ""

foreach ($file in $files) {
    $content = Get-Content -Path $file.FullName -Raw
    
    # Check if file contains local Wait-OnError function
    if ($content -match 'function Wait-OnError') {
        Write-Host "Processing: $($file.FullName)" -ForegroundColor Yellow
        
        # Pattern to match the local Wait-OnError function
        # This matches: function Wait-OnError { ... } where the function is at the beginning of the file
        $pattern = '(?s)^\s*#.*?(?:pause|wait).*?error.*?\r?\nfunction Wait-OnError \{\r?\n(?:\s*param\([^)]*\)\r?\n)?(?:\s*\[string\]\$ErrorMessage\r?\n)?\s*\)\r?\n\s*Write-Host "`nERROR: \$ErrorMessage" -ForegroundColor Red\r?\n\s*Write-Host "Press Enter to close this window\.\.\." -ForegroundColor Yellow\r?\n\s*Read-Host\r?\n\}'
        
        # Try a simpler pattern - match from function declaration to the end of the function
        $simplePattern = '(?ms)^\s*#.*?Function to pause on error.*?\r?\nfunction Wait-OnError \{\r?\n(?:[^}]*\r?\n)*?\}'
        
        if ($content -match $simplePattern) {
            $newContent = $content -replace $simplePattern, ""
            
            # Clean up extra blank lines at the start
            $newContent = $newContent -replace '^\s*\r?\n\s*\r?\n', "`r`n"
            
            if (-not $WhatIf) {
                try {
                    Set-Content -Path $file.FullName -Value $newContent.TrimStart() -Encoding UTF8 -NoNewline
                    Write-Host "  Modified successfully" -ForegroundColor Green
                    $scriptsModified++
                }
                catch {
                    Write-Host "  ERROR: Failed to modify file - $($_.Exception.Message)" -ForegroundColor Red
                    $errors += "$($file.FullName): $($_.Exception.Message)"
                }
            } else {
                Write-Host "  Would modify (WhatIf mode)" -ForegroundColor Cyan
                $scriptsModified++
            }
        } else {
            # Try manual pattern matching
            $lines = Get-Content -Path $file.FullName
            $functionStart = -1
            $functionEnd = -1
            $braceCount = 0
            $inFunction = $false
            
            for ($i = 0; $i -lt $lines.Count; $i++) {
                $line = $lines[$i]
                
                if ($line -match '^\s*function Wait-OnError') {
                    $functionStart = $i
                    $inFunction = $true
                    $braceCount = 0
                }
                
                if ($inFunction) {
                    # Count braces to find function end
                    $braceCount += ($line -split '\{' ).Count - 1
                    $braceCount -= ($line -split '\}' ).Count - 1
                    
                    if ($braceCount -le 0 -and $line -match '\}') {
                        $functionEnd = $i
                        break
                    }
                }
            }
            
            # Check if there's a comment before the function
            $commentStart = $functionStart
            for ($i = $functionStart - 1; $i -ge 0; $i--) {
                if ($lines[$i] -match '^\s*#') {
                    $commentStart = $i
                } elseif ($lines[$i].Trim() -eq '') {
                    break
                } else {
                    break
                }
            }
            
            if ($functionStart -ge 0 -and $functionEnd -gt $functionStart) {
                # Remove the function and preceding comment
                $newLines = $lines[0..($commentStart - 1)] + $lines[($functionEnd + 1)..($lines.Count - 1)]
                $newContent = ($newLines -join "`r`n").TrimStart()
                
                if (-not $WhatIf) {
                    try {
                        Set-Content -Path $file.FullName -Value $newContent -Encoding UTF8
                        Write-Host "  Modified successfully (manual pattern)" -ForegroundColor Green
                        $scriptsModified++
                    }
                    catch {
                        Write-Host "  ERROR: Failed to modify file - $($_.Exception.Message)" -ForegroundColor Red
                        $errors += "$($file.FullName): $($_.Exception.Message)"
                    }
                } else {
                    Write-Host "  Would modify (manual pattern, WhatIf mode)" -ForegroundColor Cyan
                    $scriptsModified++
                }
            } else {
                Write-Host "  Could not find function boundaries" -ForegroundColor Red
            }
        }
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  Scripts modified: $scriptsModified" -ForegroundColor Green
Write-Host "  Errors: $($errors.Count)" -ForegroundColor $(if ($errors.Count -gt 0) { "Red" } else { "Green" })

if ($errors.Count -gt 0) {
    Write-Host ""
    Write-Host "Errors encountered:" -ForegroundColor Red
    foreach ($error in $errors) {
        Write-Host "  - $error" -ForegroundColor Red
    }
}
