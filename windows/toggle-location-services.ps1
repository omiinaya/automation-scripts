#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

$locationService = Get-Service -Name "lfsvc" -ErrorAction SilentlyContinue
if (-not $locationService) {
    Write-Host "Location service not found"
    exit 1
}

$registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location"
$currentValue = (Get-ItemProperty -Path $registryPath -Name "Value" -ErrorAction SilentlyContinue).Value

if ($currentValue -eq "Allow") {
    Set-ItemProperty -Path $registryPath -Name "Value" -Value "Deny"
    Stop-Service -Name "lfsvc" -Force
    Write-Host "Location services disabled"
} else {
    Set-ItemProperty -Path $registryPath -Name "Value" -Value "Allow"
    Start-Service -Name "lfsvc"
    Write-Host "Location services enabled"
}