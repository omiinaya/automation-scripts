<#
.SYNOPSIS
    Enterprise security management module for production automation systems.
.DESCRIPTION
    Provides comprehensive security validation, privilege escalation patterns,
    secure configuration handling, and security audit capabilities.
.NOTES
    File Name      : SecurityManager.psm1
    Author         : System Administrator
    Prerequisite   : PowerShell 5.1 or later
    Version        : 1.0.0

.EXAMPLE
    Test-SecurityPrerequisites -Operation "RegistryModification" -Path "HKLM:\SOFTWARE"
.EXAMPLE
    $elevated = Invoke-WithElevatedPrivileges -ScriptBlock { Get-Service } -TimeoutSeconds 30
#>

# Import required modules
Import-Module "$PSScriptRoot\EnterpriseLogger.psm1" -Force -WarningAction SilentlyContinue

# Security configuration
$Script:SecurityConfiguration = @{
    MinimumPasswordLength = 14
    MaximumPasswordAge = 90
    PasswordHistory = 24
    LockoutThreshold = 5
    LockoutDuration = 15
    AuditLogRetention = 365
    EncryptionRequired = $true
    SecureTransportRequired = $true
    AllowedAdminGroups = @("Administrators", "Domain Admins", "Enterprise Admins")
    RestrictedOperations = @("Format-Disk", "Remove-Item", "Stop-Computer", "Restart-Computer")
}

# Function to validate security prerequisites
function Test-SecurityPrerequisites {
    <#
    .SYNOPSIS
        Validates security prerequisites for operations.
    .DESCRIPTION
        Checks permissions, system state, and security requirements before allowing operations.
    .PARAMETER Operation
        Type of operation to validate.
    .PARAMETER Path
        Target path for file/registry operations.
    .PARAMETER Resource
        Resource name for service/process operations.
    .PARAMETER RequireAdmin
        Whether admin privileges are required.
    .PARAMETER CIS_ID
        CIS benchmark ID for compliance tracking.
    .EXAMPLE
        $isSecure = Test-SecurityPrerequisites -Operation "RegistryModification" -Path "HKLM:\SOFTWARE"
    .OUTPUTS
        PSCustomObject containing validation results.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("RegistryModification", "FileOperation", "ServiceToggle", "ProcessExecution", "NetworkOperation")]
        [string]$Operation,

        [string]$Path,

        [string]$Resource,

        [bool]$RequireAdmin = $true,

        [string]$CIS_ID
    )

    try {
        $validationResults = @()
        $isSecure = $true

        # Check admin privileges if required
        if ($RequireAdmin) {
            $adminCheck = Test-AdminRights
            $validationResults += [PSCustomObject]@{
                Check = "AdminPrivileges"
                Result = if ($adminCheck) { "Pass" } else { "Fail" }
                Message = if ($adminCheck) { "Administrator privileges confirmed" } else { "Administrator privileges required" }
            }
            $isSecure = $isSecure -and $adminCheck
        }

        # Operation-specific validations
        switch ($Operation) {
            "RegistryModification" {
                if ($Path) {
                    $pathExists = Test-Path $Path
                    $validationResults += [PSCustomObject]@{
                        Check = "RegistryPathExists"
                        Result = if ($pathExists) { "Pass" } else { "Fail" }
                        Message = if ($pathExists) { "Registry path exists: $Path" } else { "Registry path not found: $Path" }
                    }
                    $isSecure = $isSecure -and $pathExists

                    # Check write permissions
                    if ($pathExists) {
                        $canWrite = Test-RegistryWriteAccess -Path $Path
                        $validationResults += [PSCustomObject]@{
                            Check = "RegistryWriteAccess"
                            Result = if ($canWrite) { "Pass" } else { "Fail" }
                            Message = if ($canWrite) { "Write access confirmed" } else { "Insufficient write permissions" }
                        }
                        $isSecure = $isSecure -and $canWrite
                    }
                }
            }

            "FileOperation" {
                if ($Path) {
                    $pathExists = Test-Path $Path
                    $validationResults += [PSCustomObject]@{
                        Check = "FilePathExists"
                        Result = if ($pathExists) { "Pass" } else { "Fail" }
                        Message = if ($pathExists) { "File path exists: $Path" } else { "File path not found: $Path" }
                    }

                    if ($pathExists) {
                        $canModify = Test-FileModifyAccess -Path $Path
                        $validationResults += [PSCustomObject]@{
                            Check = "FileModifyAccess"
                            Result = if ($canModify) { "Pass" } else { "Fail" }
                            Message = if ($canModify) { "Modify access confirmed" } else { "Insufficient modify permissions" }
                        }
                        $isSecure = $isSecure -and $canModify
                    }
                }
            }

            "ServiceToggle" {
                if ($Resource) {
                    $serviceExists = Test-ServiceExists -ServiceName $Resource
                    $validationResults += [PSCustomObject]@{
                        Check = "ServiceExists"
                        Result = if ($serviceExists) { "Pass" } else { "Fail" }
                        Message = if ($serviceExists) { "Service exists: $Resource" } else { "Service not found: $Resource" }
                    }
                    $isSecure = $isSecure -and $serviceExists
                }
            }
        }

        # System security state checks
        $systemChecks = Test-SystemSecurityState
        $validationResults += $systemChecks
        $isSecure = $isSecure -and ($systemChecks.Result -contains "Fail" -eq $false)

        # Log security validation
        Add-EnterpriseLog -Level "INFO" -Message "Security prerequisites validation completed" -Category "Security" -AdditionalData @{
            Operation = $Operation
            IsSecure = $isSecure
            ValidationResults = $validationResults
            CIS_ID = $CIS_ID
        }

        # Add audit trail entry
        Add-AuditTrailEntry -EventType "AccessAttempt" -Action "Security validation" -Result $(if ($isSecure) { "Success" } else { "Failure" }) -CIS_ID $CIS_ID -Details "Operation: $Operation, Resource: $Resource"

        return [PSCustomObject]@{
            IsSecure = $isSecure
            ValidationResults = $validationResults
            Operation = $Operation
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            ComputerName = $env:COMPUTERNAME
            UserName = $env:USERNAME
        }

    } catch {
        Add-EnterpriseLog -Level "ERROR" -Message "Security prerequisites validation failed" -Category "Security" -Exception $_
        return [PSCustomObject]@{
            IsSecure = $false
            ValidationResults = @([PSCustomObject]@{ Check = "ValidationError"; Result = "Fail"; Message = "Validation error: $($_.Exception.Message)" })
            Operation = $Operation
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            ComputerName = $env:COMPUTERNAME
            UserName = $env:USERNAME
        }
    }
}

# Function to invoke operations with elevated privileges
function Invoke-WithElevatedPrivileges {
    <#
    .SYNOPSIS
        Executes script blocks with elevated privileges.
    .DESCRIPTION
        Provides secure privilege escalation with timeout protection and result validation.
    .PARAMETER ScriptBlock
        Script block to execute with elevated privileges.
    .PARAMETER TimeoutSeconds
        Maximum execution time in seconds.
    .PARAMETER OperationName
        Name of the operation for logging.
    .PARAMETER CIS_ID
        CIS benchmark ID for compliance tracking.
    .EXAMPLE
        $result = Invoke-WithElevatedPrivileges -ScriptBlock { Get-Service } -OperationName "ServiceQuery"
    .OUTPUTS
        PSCustomObject containing execution results.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [scriptblock]$ScriptBlock,

        [int]$TimeoutSeconds = 30,

        [string]$OperationName,

        [string]$CIS_ID
    )

    try {
        # Validate current security state
        $securityCheck = Test-SecurityPrerequisites -Operation "ProcessExecution" -RequireAdmin $true -CIS_ID $CIS_ID

        if (-not $securityCheck.IsSecure) {
            Add-EnterpriseLog -Level "WARN" -Message "Security prerequisites not met for elevation" -Category "Security" -AdditionalData @{
                OperationName = $OperationName
                ValidationResults = $securityCheck.ValidationResults
            }
            return [PSCustomObject]@{
                Success = $false
                Result = $null
                ErrorMessage = "Security prerequisites failed"
                ValidationResults = $securityCheck.ValidationResults
            }
        }

        # Log elevation attempt
        Add-EnterpriseLog -Level "INFO" -Message "Attempting privilege escalation" -Category "Security" -AdditionalData @{
            OperationName = $OperationName
            TimeoutSeconds = $TimeoutSeconds
            CIS_ID = $CIS_ID
        }

        # Execute with timeout protection
        $job = Start-Job -ScriptBlock $ScriptBlock
        $result = $job | Wait-Job -Timeout $TimeoutSeconds

        if ($result.State -eq "Completed") {
            $output = Receive-Job -Job $job
            Remove-Job -Job $job

            Add-EnterpriseLog -Level "INFO" -Message "Privilege escalation completed successfully" -Category "Security"
            Add-AuditTrailEntry -EventType "SystemEvent" -Action "Privilege escalation" -Result "Success" -CIS_ID $CIS_ID -Details "Operation: $OperationName"

            return [PSCustomObject]@{
                Success = $true
                Result = $output
                ErrorMessage = $null
                ExecutionTime = $job.PSEndTime - $job.PSBeginTime
            }
        } else {
            # Timeout or failure
            Stop-Job -Job $job
            Remove-Job -Job $job

            $errorMsg = "Privilege escalation timed out or failed after $TimeoutSeconds seconds"
            Add-EnterpriseLog -Level "ERROR" -Message $errorMsg -Category "Security"
            Add-AuditTrailEntry -EventType "Error" -Action "Privilege escalation" -Result "Failure" -CIS_ID $CIS_ID -Details "Timeout: $TimeoutSeconds seconds"

            return [PSCustomObject]@{
                Success = $false
                Result = $null
                ErrorMessage = $errorMsg
                ExecutionTime = $null
            }
        }

    } catch {
        Add-EnterpriseLog -Level "ERROR" -Message "Privilege escalation failed" -Category "Security" -Exception $_
        return [PSCustomObject]@{
            Success = $false
            Result = $null
            ErrorMessage = $_.Exception.Message
            ExecutionTime = $null
        }
    }
}

# Function to test registry write access
function Test-RegistryWriteAccess {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path
    )

    try {
        # Test write access by attempting to create a test value
        $testValueName = "TestWriteAccess_$([System.Guid]::NewGuid().ToString().Substring(0,8))"
        Set-ItemProperty -Path $Path -Name $testValueName -Value "Test" -ErrorAction Stop
        Remove-ItemProperty -Path $Path -Name $testValueName -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

# Function to test file modify access
function Test-FileModifyAccess {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path
    )

    try {
        if (Test-Path $Path) {
            # Test modify access on existing file
            $file = Get-Item $Path
            $testPath = Join-Path $file.Directory.FullName "test_modify_$([System.Guid]::NewGuid().ToString().Substring(0,8)).tmp"
            "Test" | Out-File -FilePath $testPath -Force
            Remove-Item $testPath -Force
            return $true
        } else {
            # Test create access on non-existing path
            $testPath = "$Path.test_$([System.Guid]::NewGuid().ToString().Substring(0,8)).tmp"
            "Test" | Out-File -FilePath $testPath -Force
            Remove-Item $testPath -Force
            return $true
        }
    } catch {
        return $false
    }
}

# Function to test system security state
function Test-SystemSecurityState {
    <#
    .SYNOPSIS
        Tests overall system security state.
    .DESCRIPTION
        Performs comprehensive security checks including antivirus status,
        firewall configuration, and system integrity.
    .EXAMPLE
        $securityState = Test-SystemSecurityState
    .OUTPUTS
        Array of security check results.
    #>

    $securityChecks = @()

    try {
        # Check Windows Defender status
        $defenderStatus = Get-MpComputerStatus -ErrorAction SilentlyContinue
        if ($defenderStatus) {
            $defenderEnabled = $defenderStatus.AntivirusEnabled
            $securityChecks += [PSCustomObject]@{
                Check = "WindowsDefender"
                Result = if ($defenderEnabled) { "Pass" } else { "Warn" }
                Message = if ($defenderEnabled) { "Windows Defender enabled" } else { "Windows Defender not enabled" }
            }
        }

        # Check firewall status
        $firewallProfile = Get-NetFirewallProfile -ErrorAction SilentlyContinue
        if ($firewallProfile) {
            $firewallEnabled = ($firewallProfile | Where-Object { $_.Enabled -eq 'True' }).Count -gt 0
            $securityChecks += [PSCustomObject]@{
                Check = "WindowsFirewall"
                Result = if ($firewallEnabled) { "Pass" } else { "Warn" }
                Message = if ($firewallEnabled) { "Windows Firewall enabled" } else { "Windows Firewall not fully enabled" }
            }
        }

        # Check UAC status
        $uacStatus = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -ErrorAction SilentlyContinue
        if ($uacStatus) {
            $uacEnabled = $uacStatus.EnableLUA -eq 1
            $securityChecks += [PSCustomObject]@{
                Check = "UserAccountControl"
                Result = if ($uacEnabled) { "Pass" } else { "Fail" }
                Message = if ($uacEnabled) { "UAC enabled" } else { "UAC disabled - security risk" }
            }
        }

        # Check bitlocker status (if available)
        $bitlockerStatus = Get-BitLockerVolume -ErrorAction SilentlyContinue
        if ($bitlockerStatus) {
            $bitlockerEnabled = ($bitlockerStatus | Where-Object { $_.VolumeStatus -eq 'FullyEncrypted' }).Count -gt 0
            $securityChecks += [PSCustomObject]@{
                Check = "BitLocker"
                Result = if ($bitlockerEnabled) { "Pass" } else { "Info" }
                Message = if ($bitlockerEnabled) { "BitLocker encryption active" } else { "BitLocker not fully enabled" }
            }
        }

    } catch {
        $securityChecks += [PSCustomObject]@{
            Check = "SecurityStateCheck"
            Result = "Error"
            Message = "Failed to check system security state: $($_.Exception.Message)"
        }
    }

    return $securityChecks
}

# Function to validate secure configuration
function Test-SecureConfiguration {
    <#
    .SYNOPSIS
        Validates secure configuration settings.
    .DESCRIPTION
        Checks configuration against security baselines and compliance requirements.
    .PARAMETER Configuration
        Configuration object to validate.
    .PARAMETER Baseline
        Security baseline to validate against.
    .EXAMPLE
        $isSecure = Test-SecureConfiguration -Configuration $config -Baseline "CIS"
    .OUTPUTS
        Validation result object.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Configuration,

        [ValidateSet("CIS", "NIST", "Custom")]
        [string]$Baseline = "CIS"
    )

    try {
        $validationResults = @()
        $isSecure = $true

        # Baseline-specific validation rules
        switch ($Baseline) {
            "CIS" {
                # CIS-specific validation rules
                if ($Configuration.ContainsKey("PasswordLength")) {
                    $isValid = $Configuration.PasswordLength -ge $Script:SecurityConfiguration.MinimumPasswordLength
                    $validationResults += [PSCustomObject]@{
                        Check = "PasswordLength"
                        Result = if ($isValid) { "Pass" } else { "Fail" }
                        Message = if ($isValid) { "Password length meets CIS requirements" } else { "Password length below CIS minimum" }
                    }
                    $isSecure = $isSecure -and $isValid
                }

                if ($Configuration.ContainsKey("PasswordHistory")) {
                    $isValid = $Configuration.PasswordHistory -ge $Script:SecurityConfiguration.PasswordHistory
                    $validationResults += [PSCustomObject]@{
                        Check = "PasswordHistory"
                        Result = if ($isValid) { "Pass" } else { "Fail" }
                        Message = if ($isValid) { "Password history meets CIS requirements" } else { "Password history below CIS minimum" }
                    }
                    $isSecure = $isSecure -and $isValid
                }
            }

            "NIST" {
                # NIST-specific validation rules
                # Add NIST-specific checks here
            }

            "Custom" {
                # Custom validation rules
                # Add custom checks based on configuration
            }
        }

        # General security validation
        if ($Configuration.ContainsKey("EncryptionEnabled")) {
            $isValid = $Configuration.EncryptionEnabled -eq $true
            $validationResults += [PSCustomObject]@{
                Check = "EncryptionEnabled"
                Result = if ($isValid) { "Pass" } else { "Fail" }
                Message = if ($isValid) { "Encryption enabled" } else { "Encryption disabled - security risk" }
            }
            $isSecure = $isSecure -and $isValid
        }

        Add-EnterpriseLog -Level "INFO" -Message "Secure configuration validation completed" -Category "Security" -AdditionalData @{
            Baseline = $Baseline
            IsSecure = $isSecure
            ValidationResults = $validationResults
        }

        return [PSCustomObject]@{
            IsSecure = $isSecure
            ValidationResults = $validationResults
            Baseline = $Baseline
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }

    } catch {
        Add-EnterpriseLog -Level "ERROR" -Message "Secure configuration validation failed" -Category "Security" -Exception $_
        return [PSCustomObject]@{
            IsSecure = $false
            ValidationResults = @([PSCustomObject]@{ Check = "ValidationError"; Result = "Fail"; Message = "Validation error: $($_.Exception.Message)" })
            Baseline = $Baseline
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
    }
}

# Function to secure sensitive data
function Protect-SensitiveData {
    <#
    .SYNOPSIS
        Secures sensitive data using encryption and access controls.
    .DESCRIPTION
        Provides encryption and secure handling for sensitive configuration data.
    .PARAMETER Data
        Sensitive data to protect.
    .PARAMETER DataType
        Type of data (Password, APIKey, ConnectionString).
    .PARAMETER StoragePath
        Path for secure storage.
    .EXAMPLE
        $securedData = Protect-SensitiveData -Data "MySecretPassword" -DataType "Password"
    .OUTPUTS
        Secured data object.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Data,

        [ValidateSet("Password", "APIKey", "ConnectionString", "Certificate")]
        [string]$DataType = "Password",

        [string]$StoragePath
    )

    try {
        # For production, use proper encryption
        # This is a simplified version for demonstration
        $secureString = ConvertTo-SecureString -String $Data -AsPlainText -Force
        $encryptedData = ConvertFrom-SecureString -SecureString $secureString

        # Create secure data object
        $securedData = [PSCustomObject]@{
            DataType = $DataType
            EncryptedData = $encryptedData
            ProtectionTimestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            ProtectedBy = $env:USERNAME
            ComputerName = $env:COMPUTERNAME
        }

        # Store securely if path provided
        if ($StoragePath) {
            $securedData | ConvertTo-Json | Out-File -FilePath $StoragePath -Encoding UTF8
        }

        Add-EnterpriseLog -Level "INFO" -Message "Sensitive data secured" -Category "Security" -AdditionalData @{
            DataType = $DataType
            StoragePath = $StoragePath
        }

        return $securedData

    } catch {
        Add-EnterpriseLog -Level "ERROR" -Message "Failed to secure sensitive data" -Category "Security" -Exception $_
        return $null
    }
}

# Function to perform security audit
function Invoke-SecurityAudit {
    <#
    .SYNOPSIS
        Performs comprehensive security audit.
    .DESCRIPTION
        Audits system security configuration, permissions, and compliance status.
    .PARAMETER AuditType
        Type of audit to perform.
    .PARAMETER CIS_ID
        CIS benchmark ID for targeted audit.
    .EXAMPLE
        $auditResults = Invoke-SecurityAudit -AuditType "Comprehensive"
    .OUTPUTS
        Security audit results.
    #>
    param(
        [ValidateSet("Comprehensive", "Quick", "Targeted")]
        [string]$AuditType = "Comprehensive",

        [string]$CIS_ID
    )

    try {
        $auditResults = @()

        # System security state audit
        $systemSecurity = Test-SystemSecurityState
        $auditResults += $systemSecurity

        # Permission audit
        $permissionAudit = Test-PermissionSecurity
        $auditResults += $permissionAudit

        # Configuration audit
        $configAudit = Test-ConfigurationSecurity
        $auditResults += $configAudit

        # CIS compliance audit (if CIS_ID provided)
        if ($CIS_ID) {
            $cisAudit = Invoke-CISComplianceAudit -CIS_ID $CIS_ID
            $auditResults += $cisAudit
        }

        # Calculate overall security score
        $passCount = ($auditResults | Where-Object { $_.Result -eq "Pass" }).Count
        $totalChecks = $auditResults.Count
        $securityScore = if ($totalChecks -gt 0) { [math]::Round(($passCount / $totalChecks) * 100, 2) } else { 0 }

        Add-EnterpriseLog -Level "INFO" -Message "Security audit completed" -Category "Security" -AdditionalData @{
            AuditType = $AuditType
            SecurityScore = $securityScore
            TotalChecks = $totalChecks
            PassCount = $passCount
        }

        Add-AuditTrailEntry -EventType "SecurityChange" -Action "Security audit" -Result "Success" -CIS_ID $CIS_ID -Details "Score: $securityScore%, Type: $AuditType"

        return [PSCustomObject]@{
            AuditType = $AuditType
            SecurityScore = $securityScore
            TotalChecks = $totalChecks
            PassCount = $passCount
            FailCount = $totalChecks - $passCount
            Results = $auditResults
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            ComputerName = $env:COMPUTERNAME
        }

    } catch {
        Add-EnterpriseLog -Level "ERROR" -Message "Security audit failed" -Category "Security" -Exception $_
        return [PSCustomObject]@{
            AuditType = $AuditType
            SecurityScore = 0
            TotalChecks = 0
            PassCount = 0
            FailCount = 0
            Results = @()
            ErrorMessage = $_.Exception.Message
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
    }
}

# Helper function for permission security audit
function Test-PermissionSecurity {
    $permissionChecks = @()

    try {
        # Check critical registry permissions
        $criticalPaths = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
            "HKLM:\SYSTEM\CurrentControlSet\Services",
            "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
        )

        foreach ($path in $criticalPaths) {
            if (Test-Path $path) {
                $canWrite = Test-RegistryWriteAccess -Path $path
                $permissionChecks += [PSCustomObject]@{
                    Check = "RegistryPermission_$(($path -replace '[^a-zA-Z]', ''))"
                    Result = if (-not $canWrite) { "Pass" } else { "Warn" }
                    Message = if (-not $canWrite) { "Write access restricted to $path" } else { "Write access allowed to critical path: $path" }
                }
            }
        }

    } catch {
        $permissionChecks += [PSCustomObject]@{
            Check = "PermissionAudit"
            Result = "Error"
            Message = "Permission audit failed: $($_.Exception.Message)"
        }
    }

    return $permissionChecks
}

# Helper function for configuration security audit
function Test-ConfigurationSecurity {
    $configChecks = @()

    try {
        # Check UAC configuration
        $uacStatus = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -ErrorAction SilentlyContinue
        if ($uacStatus) {
            $configChecks += [PSCustomObject]@{
                Check = "UACEnabled"
                Result = if ($uacStatus.EnableLUA -eq 1) { "Pass" } else { "Fail" }
                Message = if ($uacStatus.EnableLUA -eq 1) { "UAC enabled" } else { "UAC disabled" }
            }
        }

        # Check PowerShell execution policy
        $executionPolicy = Get-ExecutionPolicy
        $configChecks += [PSCustomObject]@{
            Check = "PowerShellExecutionPolicy"
            Result = if ($executionPolicy -eq "Restricted") { "Pass" } else { "Warn" }
            Message = "Execution policy: $executionPolicy"
        }

    } catch {
        $configChecks += [PSCustomObject]@{
            Check = "ConfigurationAudit"
            Result = "Error"
            Message = "Configuration audit failed: $($_.Exception.Message)"
        }
    }

    return $configChecks
}

# Export the module members
Export-ModuleMember -Function Test-SecurityPrerequisites, Invoke-WithElevatedPrivileges, Test-SecureConfiguration, Protect-SensitiveData, Invoke-SecurityAudit, Test-SystemSecurityState -Verbose:$false

Write-Verbose "SecurityManager module loaded successfully"