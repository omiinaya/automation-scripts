# Setup Guide - Windows Automation Scripts

This guide will help you configure your Windows system to run the PowerShell automation scripts safely.

## 🔐 PowerShell Execution Policy

Windows has security features that prevent scripts from running by default. Follow these steps to enable script execution safely.

### Step 1: Check Current Policy

Open **PowerShell as Administrator** and run:

```powershell
Get-ExecutionPolicy
```

Common responses:
- `Restricted` (default) - No scripts allowed
- `RemoteSigned` - Local scripts allowed, remote scripts must be signed
- `Unrestricted` - All scripts allowed (not recommended)

### Step 2: Set Safe Execution Policy

For these scripts, we recommend **RemoteSigned** policy:

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**What this does:**
- ✅ Allows local scripts to run
- ✅ Requires downloaded scripts to be signed
- ✅ More secure than Unrestricted
- ✅ Only affects your user account

### Step 3: Verify Setup

Test the configuration:

```powershell
Get-ExecutionPolicy -List
```

You should see `RemoteSigned` for `CurrentUser`.

### Temporary Execution Policy Bypass

For temporary script execution without permanently changing system policies, you can use the `enable-powershell.bat` batch file included in the `windows/` folder. This method sets a **process-scoped** execution policy that only affects the current PowerShell session.

**Process-scoped vs permanent execution policies:**
- **Process-scoped**: Changes apply only to the current PowerShell window and disappear when you close it. No permanent system changes.
- **Permanent**: Changes persist across sessions and affect all future PowerShell windows (requires administrator rights).

**Instructions for running the batch file:**
1. Navigate to the `windows/` folder in File Explorer.
2. Right-click `enable-powershell.bat` and select **"Run as administrator"** (recommended) or double-click to run as a normal user.
3. The batch file will:
   - Check for administrator privileges.
   - Set the execution policy to `Bypass` for the current process.
   - Confirm success and keep the window open for verification.

**Example command and expected output:**
```batch
C:\automation-scripts\windows> enable-powershell.bat
========================================
   PowerShell Execution Policy Bypass
========================================

[INFO] Running with administrator privileges.

Setting execution policy to Bypass for the current process...
[SUCCESS] PowerShell scripts are now enabled for this session.

You can now run PowerShell scripts in this window.
```

**When to use temporary vs permanent methods:**
- Use **temporary bypass** when you need to run scripts once or in a controlled environment.
- Use **permanent policy change** (as described in Step 2) for regular script usage.

## 🛡️ Security Best Practices

### Before Running Scripts

1. **Review the code**: All scripts are open source - read them first
2. **Run in test environment**: Test on a non-production system if possible
3. **Check file origin**: Ensure scripts came from a trusted source
4. **Backup system**: Create a restore point before major changes

### Creating a Restore Point

```powershell
Checkpoint-Computer -Description "Before Automation Scripts" -RestorePointType "MODIFY_SETTINGS"
```

## 🚀 Running Scripts

### Method 1: Right-click Run
Right-click any `.ps1` file → **Run with PowerShell**

### Method 2: PowerShell Console
```powershell
cd "C:\path\to\automation-scripts\windows"
.\toggle-theme.ps1
```

### Method 3: PowerShell ISE (for debugging)
1. Open PowerShell ISE as Administrator
2. File → Open → Select script
3. Press F5 to run with debugging

## 📋 Prerequisites

### Windows Version
- **Primary**: Windows 11 (all features supported)
- **Secondary**: Windows 10 (most features work)
- **Not tested**: Windows 8.1 or earlier

### PowerShell Version
Check your version:
```powershell
$PSVersionTable.PSVersion
```

Minimum: PowerShell 5.1 (built into Windows 10/11)

### Administrator Rights
Some scripts require admin privileges:
- Power management scripts
- Registry modifications
- System configuration changes

Scripts will automatically request elevation when needed.

## 🔧 Troubleshooting

### "Execution policy" errors
```powershell
# Check all policies
Get-ExecutionPolicy -List

# Reset to default
Set-ExecutionPolicy Restricted -Scope CurrentUser

# Set recommended policy
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### "Access denied" errors
- Right-click PowerShell → **Run as Administrator**
- Scripts will prompt for elevation when needed

### "File not found" errors
- Check you're in the correct directory
- Use full path: `C:\path\to\script.ps1`
- Avoid paths with spaces in names

### Antivirus blocking scripts
- Add the script folder to antivirus exclusions
- Check Windows Defender SmartScreen settings
- Ensure scripts came from trusted source

## 📖 Advanced Configuration

### Signing Your Own Scripts
If you modify scripts and want to sign them:

```powershell
# Create self-signed certificate
$cert = New-SelfSignedCertificate -Subject "CN=PowerShell Scripts" -Type CodeSigningCert -CertStoreLocation "Cert:\CurrentUser\My"

# Sign a script
Set-AuthenticodeSignature -FilePath ".\myscript.ps1" -Certificate $cert
```

### Running Scripts Automatically
For scheduled tasks or startup scripts:
- Use Task Scheduler with "Run with highest privileges"
- Set proper execution policy for system account

## 🐍 Python Extraction Script

For CIS benchmark extraction (optional), a Python script is provided in `scripts/`.

### Dependencies
Install Python dependencies:
```bash
pip install -r scripts/requirements.txt
```

### Usage
```bash
python scripts/cis_robust_extractor.py
```

### Log Files
Extraction logs are saved to `cis_extraction_robust.log` (already excluded via `.gitignore`).

### Git Large File Storage (LFS)
Large files (e.g., PDF benchmarks) should be managed with Git LFS. If you have Git LFS installed, run:
```bash
git lfs track "*.pdf"
git add .gitattributes
```

## 🆘 Getting Help

### Common Issues
1. **Execution policy errors**: See setup steps above
2. **Access denied**: Run as administrator
3. **Scripts won't start**: Check file associations
4. **PowerShell not found**: Use Windows Terminal or search for PowerShell

### Resources
- [Microsoft PowerShell Documentation](https://docs.microsoft.com/powershell)
- [PowerShell Execution Policies](https://docs.microsoft.com/powershell/module/microsoft.powershell.core/about/about_execution_policies)
- [Windows Terminal](https://aka.ms/terminal) - Modern terminal for PowerShell

## ✅ Quick Setup Checklist

- [ ] Check PowerShell version (`$PSVersionTable.PSVersion`)
- [ ] Set execution policy (`Set-ExecutionPolicy RemoteSigned -Scope CurrentUser`)
- [ ] Test with a simple script
- [ ] Create system restore point
- [ ] Run desired automation scripts