# Service Toggle Generator

This directory contains a generator script that creates service toggle scripts from a configuration file. This approach eliminates code duplication and makes it easy to manage multiple Windows service toggles.

## Overview

The service toggle generator reads service configurations from `service-config.json` and generates individual PowerShell scripts for toggling Windows services. Each generated script follows the same pattern and uses the modular CISFramework system.

## Files

- **`service-config.json`** - Configuration file containing service definitions
- **`generate-service-toggles.ps1`** - Generator script that creates service toggle scripts
- **`toggle-*-service.ps1`** - Generated service toggle scripts

## Using the Generator

### Generate All Service Scripts

```powershell
.\generate-service-toggles.ps1
```

This generates scripts for all services defined in the configuration file.

### Generate a Specific Service Script

```powershell
.\generate-service-toggles.ps1 -ServiceName "bthserv"
```

Generate only the script for the Bluetooth Support Service.

### Preview What Would Be Generated (Dry Run)

```powershell
.\generate-service-toggles.ps1 -DryRun
```

Shows which scripts would be created without actually creating them.

### Force Overwrite Existing Scripts

```powershell
.\generate-service-toggles.ps1 -Force
```

Overwrites existing scripts without prompting.

### Combine Options

```powershell
.\generate-service-toggles.ps1 -ServiceName "DiagTrack" -DryRun
```

Preview the generation of a specific service script.

## Configuration File Structure

The `service-config.json` file contains an array of service objects with the following properties:

```json
{
  "services": [
    {
      "name": "ServiceName",
      "displayName": "Service Display Name",
      "description": "Service description",
      "defaultStartupType": "Manual",
      "safeToDisable": true,
      "category": "Category"
    }
  ]
}
```

### Configuration Properties

| Property | Type | Description |
|----------|------|-------------|
| `name` | string | The internal Windows service name (e.g., "bthserv") |
| `displayName` | string | The human-readable service name (e.g., "Bluetooth Support Service") |
| `description` | string | Description of what the service does |
| `defaultStartupType` | string | Default startup type (e.g., "Manual", "Disabled", "Automatic") |
| `safeToDisable` | boolean | Whether it's safe to disable this service |
| `category` | string | Service category for organization (e.g., "Bluetooth", "Telemetry", "Network") |

## Adding New Services

To add a new service to the configuration:

1. Open `service-config.json`
2. Add a new service object to the `services` array
3. Fill in all required properties
4. Run the generator to create the script

### Example: Adding a New Service

```json
{
  "name": "NewService",
  "displayName": "New Service Name",
  "description": "Description of the new service",
  "defaultStartupType": "Manual",
  "safeToDisable": true,
  "category": "System"
}
```

Then run:

```powershell
.\generate-service-toggles.ps1 -ServiceName "NewService"
```

## Generated Script Pattern

Each generated script follows this pattern:

```powershell
# Toggle Service Display Name (ServiceName) startup type on Windows
# Enable/Disable service startup instead of starting/stopping the service
# Refactored to use modular CISFramework system with automatic elevation

# Import the ModuleIndex module which includes all modules including ServiceManager
$modulePath = Join-Path $PSScriptRoot "..\..\..\modules\ModuleIndex.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

# Toggle the Service Display Name using the CISFramework with automatic elevation
Invoke-CISScript -ScriptType "ServiceToggle" -ServiceName "ServiceName" -ServiceDisplayName "Service Display Name" -AutoElevate -ScriptBlock {
    Invoke-ServiceToggle -ServiceName "ServiceName" -ServiceDisplayName "Service Display Name" -EnableStartupType "Manual" -SkipAdminCheck
}
```

## Service Categories

Services are organized into categories for easier management:

- **Bluetooth** - Bluetooth-related services
- **Telemetry** - Data collection and telemetry services
- **Network** - Network-related services
- **Privacy** - Privacy-related services
- **Security** - Security-related services
- **System** - Core system services
- **Performance** - Performance optimization services
- **Remote** - Remote access services
- **Backup** - Backup and recovery services
- **IoT** - Internet of Things services
- **Virtualization** - Virtualization services

## Safety Considerations

The `safeToDisable` property in the configuration indicates whether a service can be safely disabled. Services marked as `false` should be used with caution, as disabling them may affect system functionality.

## Troubleshooting

### Configuration File Not Found

Ensure you're running the generator from the same directory as `service-config.json`, or provide the full path using the `-ConfigPath` parameter.

### Script Already Exists

Use the `-Force` parameter to overwrite existing scripts, or use `-DryRun` to preview what would be generated.

### Invalid Configuration

Ensure the JSON file is properly formatted and contains all required properties for each service.

## Generator Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `ConfigPath` | string | service-config.json | Path to the configuration file |
| `ServiceName` | string | (empty) | Generate script for a specific service only |
| `DryRun` | switch | false | Preview without creating files |
| `Force` | switch | false | Overwrite existing scripts |

## Best Practices

1. **Always use dry-run first** when generating multiple scripts to verify the output
2. **Test generated scripts** in a safe environment before deploying
3. **Keep the configuration file updated** as services change
4. **Use descriptive display names** for better script readability
5. **Categorize services appropriately** for easier management
6. **Document any special considerations** in the service description

## Related Documentation

- [Service Management Documentation](../../../../docs/services.md)
- [Safely Disabling Services](../../../../docs/safely-disable-services.md)
- [CIS Framework Documentation](../../../../modules/README.md)
