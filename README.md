# Automation Scripts

A collection of automation scripts for Windows and other operating systems. This project provides modular, reusable scripts for system configuration, security compliance, and optimization tasks.

## 🚀 Quick Start

### Development Environment
1. **Prerequisites**: Windows 11 (for Windows scripts) or appropriate OS
2. **Run Setup**: See [SETUP.md](./SETUP.md) for PowerShell execution policy configuration
3. **Run Scripts**: Right-click any `.ps1` file and select "Run with PowerShell" (Windows) or use appropriate execution method for your OS

### Production Environment
1. **Prerequisites**: Windows Server 2016+ or Windows 11 Enterprise
2. **Security Review**: Review security implications in production environments
3. **Deployment**: Use production deployment scripts
4. **Testing**: Execute comprehensive test suite before production use

### Enterprise Deployment
```powershell
# Deploy to production environment
.\scripts\deploy-production.ps1 -Environment "Production" -DeploymentType "Full"

# Run comprehensive tests
.\scripts\test-production.ps1 -TestType "Comprehensive" -IncludePerformance -IncludeSecurity

# Monitor system health
Import-Module .\modules\HealthMonitor.psm1
$health = Get-SystemHealth -CheckType "Comprehensive"
```

## 📁 Project Structure

```
automation-scripts/
├── README.md                    # This file
├── SETUP.md                    # Setup instructions
├── config/                     # Configuration files
├── docs/                       # Documentation
├── examples/                   # Example usage scripts
├── helpers/                    # Helper utilities and analysis tools
├── modules/                    # PowerShell modules
├── scripts/                    # Cross-platform executable scripts
├── tests/                      # Test files
│   ├── integration/            # Integration tests
│   ├── python/                 # Python test files
│   └── unit/                   # Unit tests
└── windows/                    # Windows-specific automation scripts
    ├── enable-powershell.bat   # Permanent PowerShell execution policy toggle
    ├── deferred/               # Scripts requiring further development
    │   ├── toggle-power-mode.ps1
    │   └── security/           # Security audit and remediation scripts
    │       ├── audit-batch-execution.ps1
    │       ├── audits/         # Security audit scripts
    │       └── remediations/   # Security remediation scripts
    ├── optimization/           # Optimization scripts
    │   ├── toggle-game-mode.ps1
    │   ├── services/           # Service optimization scripts
    │   └── visuals/            # Visual optimization scripts
    └── modules/                # Windows-specific PowerShell modules
        ├── ModuleIndex.psm1
        ├── PowerManagement.psm1
        ├── RegistryUtils.psm1
        ├── WindowsUI.psm1
        ├── WindowsUtils.psm1
        └── README.md
```

## 📋 Available Scripts

### Cross-Platform Scripts (scripts/)

| Script | Description | Admin Required |
|--------|-------------|----------------|
| `enable-powershell.bat` | Permanent PowerShell execution policy toggle | Yes (Windows) |
| `toggle-power-mode.ps1` | Switches between balanced/high performance | Yes |
| `deploy-production.ps1` | Enterprise deployment with validation and rollback | Yes |
| `test-production.ps1` | Comprehensive testing suite for production validation | No |

### Enterprise Modules (modules/)

| Module | Description | Production Ready |
|--------|-------------|------------------|
| `EnterpriseLogger.psm1` | Structured logging with audit trail | ✅ |
| `SecurityManager.psm1` | Security validation and privilege escalation | ✅ |
| `DeploymentManager.psm1` | Environment-specific deployment management | ✅ |
| `HealthMonitor.psm1` | System health monitoring and performance tracking | ✅ |
| `TestFramework.psm1` | Comprehensive testing and validation framework | ✅ |
| `CISFramework.psm1` | CIS benchmark auditing framework | ✅ |
| `ServiceManager.psm1` | Service management with compliance tracking | ✅ |
| `ConfigurationManager.psm1` | Dynamic configuration management | ✅ |

### Windows-Specific Scripts (windows/)

#### System Configuration
| Script | Description | Admin Required |
|--------|-------------|----------------|
| `set-high-performance.ps1` | Sets power plan to high performance | Yes |
| `toggle-lid-close.ps1` | Toggles laptop lid close behavior | Yes |
| `toggle-location-services.ps1` | Toggle Windows location services | Yes |
| `toggle-screen-never.ps1` | Toggles screen timeout (never vs 15min) | Yes |
| `toggle-sleep-never.ps1` | Toggles sleep mode (never vs 15min) | Yes |
| `toggle-taskbar-alignment.ps1` | Moves taskbar icons left/center | No |
| `toggle-theme.ps1` | Switches between light/dark theme | No |
| `toggle-transparency.ps1` | Toggles transparency effects | No |

#### Optimization Scripts
| Script | Description | Admin Required |
|--------|-------------|----------------|
| `toggle-game-mode.ps1` | Toggle Windows Game Mode | No |

#### Security Scripts (Deferred - In Development)
* Comprehensive CIS benchmark audit and remediation scripts
* Organized by CIS section numbers
* Located in `windows/deferred/security/`

## 🏢 Enterprise Features

### Production-Ready Improvements

#### 1. Comprehensive Error Handling & Logging
- **Structured Logging**: Multi-level logging (DEBUG, INFO, WARN, ERROR, FATAL)
- **Audit Trail**: Compliance tracking with detailed audit entries
- **Error Recovery**: Robust error classification and recovery mechanisms
- **Log Rotation**: Automatic log rotation and retention management

#### 2. Enhanced Security & Permissions
- **Security Validation**: Comprehensive security prerequisite checks
- **Privilege Escalation**: Secure privilege escalation patterns
- **Configuration Security**: Environment-specific security baselines
- **Sensitive Data Protection**: Encryption and secure handling

#### 3. Deployment & Configuration Management
- **Environment Support**: Development, Testing, Staging, Production
- **Configuration Templates**: Environment-specific configuration templates
- **Deployment Scripts**: Full, incremental, and rolling deployments
- **Validation Framework**: Pre-flight checks and post-deployment validation

#### 4. Monitoring & Health Checks
- **System Health Monitoring**: Comprehensive health assessment
- **Performance Metrics**: Real-time performance tracking
- **Alerting System**: Health alerts with severity levels
- **Resource Monitoring**: CPU, memory, disk, and network monitoring

#### 5. Testing & Validation Framework
- **Test Suites**: Unit, integration, system, performance, and security tests
- **Automated Validation**: Automated pre-flight checks
- **Compliance Testing**: Security and compliance validation
- **Performance Testing**: Load and performance testing

#### 6. Documentation & User Experience
- **Production Documentation**: Enterprise deployment guides
- **Troubleshooting Guides**: Comprehensive troubleshooting
- **User-Friendly Messages**: Clear, actionable error messages
- **Audit-Ready**: Compliance-ready logging and reporting

## 🔧 Features

- **Modular Design**: Reusable PowerShell modules for common operations
- **Error Handling**: Comprehensive error handling with user-friendly messages
- **Admin Detection**: Automatic elevation requests when needed
- **Status Reporting**: Clear success/failure feedback
- **No External Dependencies**: Uses only built-in Windows tools
- **Enterprise-Grade**: Production-ready with security, monitoring, and testing

## ⚡ Quick Examples

### Cross-Platform Scripts

```powershell
# Enable PowerShell execution policy
.\scripts\enable-powershell.bat

# Toggle power mode (requires admin)
.\scripts\toggle-power-mode.ps1
```

### Windows-Specific Examples

```powershell
# Enable high performance mode
.\windows\set-high-performance.ps1

# Toggle dark theme
.\windows\toggle-theme.ps1

# Disable sleep when plugged in
.\windows\toggle-sleep-never.ps1

# Toggle Game Mode
.\windows\optimization\toggle-game-mode.ps1
```

### Enterprise Production Examples

```powershell
# Production deployment with validation
.\scripts\deploy-production.ps1 -Environment "Production" -DeploymentType "Full"

# Comprehensive production testing
.\scripts\test-production.ps1 -TestType "Comprehensive" -IncludePerformance -IncludeSecurity

# Enterprise logging and monitoring
Import-Module .\modules\EnterpriseLogger.psm1
Initialize-EnterpriseLogging -LogLevel "INFO" -ApplicationName "CISAutomation"
Add-EnterpriseLog -Level "INFO" -Message "Production operation started" -Category "Audit"

# Security validation
Import-Module .\modules\SecurityManager.psm1
$security = Test-SecurityPrerequisites -Operation "RegistryModification" -RequireAdmin $true

# System health monitoring
Import-Module .\modules\HealthMonitor.psm1
$health = Get-SystemHealth -CheckType "Comprehensive"

# Security audit
$audit = Invoke-SecurityAudit -AuditType "Comprehensive"
```

### Security Compliance Examples (Deferred Scripts)

```powershell
# Run security audit batch
.\windows\deferred\security\audit-batch-execution.ps1

# Individual CIS benchmark audits
.\windows\deferred\security\audits\section_2\2.2.1-audit-access-credential-manager-trusted-caller.ps1
.\windows\deferred\security\audits\section_5\5.1-audit-bluetooth-audio-gateway-service.ps1
```

## 🔐 Security

- All scripts are read-only (no permanent changes without user action)
- Scripts request elevation only when necessary
- No network connections or external data collection
- Open source - review code before running

## 📖 Documentation

- [Setup Guide](./SETUP.md) - PowerShell configuration and prerequisites
- [Project Documentation](./docs/) - Technical specifications and analysis
- [Module Documentation](./modules/README.md) - PowerShell module reference
- [Test Documentation](./tests/README.md) - Testing framework and procedures

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Test your changes on Windows 11
4. Submit a pull request with clear description

## 🐛 Troubleshooting

### Development Environment
**"Execution policy" errors**: See [SETUP.md](./SETUP.md) (for a permanent toggle, run `scripts/enable-powershell.bat` as administrator)

**"Access denied" errors**: Run PowerShell as Administrator

**Scripts won't run**: Check file execution policy with `Get-ExecutionPolicy`

**Windows-specific scripts**: Ensure you're running on Windows for Windows-specific scripts in `windows/` directory

### Production Environment
**Deployment validation failures**: Review security prerequisites and system health before deployment

**Module loading errors**: Check module dependencies and ensure all enterprise modules are properly imported

**Logging issues**: Verify log directory permissions and disk space availability

**Security validation failures**: Ensure proper administrative privileges and security configuration

**Performance issues**: Monitor system resources and adjust performance thresholds as needed

## 📄 License

MIT License - see LICENSE file for details

## 🆘 Support

- Check the [troubleshooting section](#-troubleshooting)
- Review [SETUP.md](./SETUP.md) for configuration issues
- Open an issue on GitHub for bugs or feature requests