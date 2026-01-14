# Windows Automation Scripts

A collection of PowerShell scripts for automating common Windows 11 configuration tasks. These scripts provide quick, one-click solutions for managing system settings without navigating through multiple Windows UI menus.

## 🚀 Quick Start

1. **Prerequisites**: Windows 11 (some scripts may work on Windows 10)
2. **Run Setup**: See [SETUP.md](./SETUP.md) for PowerShell execution policy configuration
3. **Run Scripts**: Right-click any `.ps1` file and select "Run with PowerShell"

## 📁 Project Structure

```
automation-scripts/
├── README.md                    # This file
├── SETUP.md                    # Setup instructions
├── docs/                       # Documentation
│   └── windows-refactoring-summary.md
└── windows/                    # Windows automation scripts
    ├── set-high-performance.ps1    # Set power plan to high performance
    ├── toggle-lid-close.ps1        # Toggle laptop lid close action
    ├── toggle-location-services.ps1 # Toggle Windows location services
    ├── toggle-power-mode.ps1       # Toggle between power modes
    ├── toggle-screen-never.ps1     # Toggle screen timeout never/15min
    ├── toggle-sleep-never.ps1      # Toggle sleep never/15min
    ├── toggle-taskbar-alignment.ps1 # Toggle taskbar left/center alignment
    ├── toggle-theme.ps1            # Toggle Windows light/dark theme
    ├── toggle-transparency.ps1     # Toggle transparency effects
    ├── enable-powershell.bat       # Permanent PowerShell execution policy toggle
    ├── modules/                    # PowerShell modules
    │   ├── ModuleIndex.psm1        # Main module loader
    │   ├── PowerManagement.psm1    # Power management functions
    │   ├── RegistryUtils.psm1      # Registry manipulation utilities
    │   ├── WindowsUI.psm1          # Windows UI configuration functions
    │   ├── WindowsUtils.psm1       # General Windows utilities
    │   └── README.md               # Module documentation
    └── security/                  # Security audit and remediation scripts
        ├── audits/                 # Security audit scripts
        │   ├── 1.1.1-audit-password-history.ps1
        │   └── 1.1.3-audit-minimum-password-age.ps1
        └── remediations/           # Security remediation scripts
            ├── 1.1.1-remediate-password-history.ps1
            ├── 1.1.2-remediate-maximum-password-age.ps1
            └── 1.1.3-remediate-minimum-password-age.ps1
```

## 📋 Available Scripts

### System Configuration Scripts

| Script | Description | Admin Required |
|--------|-------------|----------------|
| `set-high-performance.ps1` | Sets power plan to high performance | Yes |
| `toggle-lid-close.ps1` | Toggles laptop lid close behavior | Yes |
| `toggle-location-services.ps1` | Toggle Windows location services with modular design, Windows version check, and improved error handling | Yes |
| `toggle-power-mode.ps1` | Switches between balanced/high performance | Yes |
| `toggle-screen-never.ps1` | Toggles screen timeout (never vs 15min) | Yes |
| `toggle-sleep-never.ps1` | Toggles sleep mode (never vs 15min) | Yes |
| `toggle-taskbar-alignment.ps1` | Moves taskbar icons left/center | No |
| `toggle-theme.ps1` | Switches between light/dark theme | No |
| `toggle-transparency.ps1` | Toggles transparency effects | No |

### Security Scripts

| Script | Description | CIS Benchmark | Admin Required |
|--------|-------------|---------------|----------------|
| `security/audits/1.1.1-audit-password-history.ps1` | Audits password history enforcement setting | 1.1.1 (L1) | Yes |
| `security/remediations/1.1.1-remediate-password-history.ps1` | Remediate password history enforcement setting | 1.1.1 (L1) | Yes |
| `security/audits/1.1.3-audit-minimum-password-age.ps1` | Audits minimum password age setting | 1.1.3 (L1) | Yes |
| `security/remediations/1.1.2-remediate-maximum-password-age.ps1` | Remediate maximum password age setting | 1.1.2 (L1) | Yes |
| `security/remediations/1.1.3-remediate-minimum-password-age.ps1` | Remediate minimum password age setting | 1.1.3 (L1) | Yes |

## 🔧 Features

- **Modular Design**: Reusable PowerShell modules for common operations
- **Error Handling**: Comprehensive error handling with user-friendly messages
- **Admin Detection**: Automatic elevation requests when needed
- **Status Reporting**: Clear success/failure feedback
- **No External Dependencies**: Uses only built-in Windows tools

## ⚡ Quick Examples

### System Configuration Examples

```powershell
# Enable high performance mode
.\set-high-performance.ps1

# Toggle dark theme
.\toggle-theme.ps1

# Disable sleep when plugged in
.\toggle-sleep-never.ps1
```

### Security Compliance Examples

```powershell
# Audit password policy compliance
.\windows\security\audits\1.1.1-audit-password-history.ps1

# Remediate non-compliant password settings
.\windows\security\remediations\1.1.1-remediate-password-history.ps1

# Verify remediation success
.\windows\security\audits\1.1.1-audit-password-history.ps1
```

## 🔐 Security

- All scripts are read-only (no permanent changes without user action)
- Scripts request elevation only when necessary
- No network connections or external data collection
- Open source - review code before running

## 📖 Documentation

- [Setup Guide](./SETUP.md) - PowerShell configuration and prerequisites
- [Windows Refactoring Summary](./docs/windows-refactoring-summary.md) - Technical details
- [Module Documentation](./windows/modules/README.md) - PowerShell module reference

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Test your changes on Windows 11
4. Submit a pull request with clear description

## 🐛 Troubleshooting

**"Execution policy" errors**: See [SETUP.md](./SETUP.md) (for a permanent toggle, run `windows/enable-powershell.bat` as administrator)

**"Access denied" errors**: Run PowerShell as Administrator

**Scripts won't run**: Check file execution policy with `Get-ExecutionPolicy`

## 📄 License

MIT License - see LICENSE file for details

## 🆘 Support

- Check the [troubleshooting section](#-troubleshooting)
- Review [SETUP.md](./SETUP.md) for configuration issues
- Open an issue on GitHub for bugs or feature requests