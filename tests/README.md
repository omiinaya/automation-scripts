# CIS Automation Scripts Test Suite

This directory contains the Pester test suite for the CIS Automation Scripts project.

## Test Structure

### Directory Organization

```
tests/
├── unit/                    # Unit tests for individual modules
│   ├── CISFramework.Tests.ps1
│   ├── CISRemediation.Tests.ps1
│   └── ModuleIndex.Tests.ps1
├── integration/             # Integration tests for scripts
│   ├── AuditScripts.Tests.ps1
│   └── RemediationScripts.Tests.ps1
├── results/                 # Test results output (auto-created)
├── logs/                   # Test logs (auto-created)
├── TestHelpers.psm1        # Test helper functions
├── PesterConfig.psd1      # Pester configuration
├── RunTests.ps1           # Test runner script
└── README.md              # This file
```

## Test Types

### Unit Tests (`tests/unit/`)

- **CISFramework.Tests.ps1**: Tests for [`CISFramework.psm1`](../windows/modules/CISFramework.psm1) functions
  - [`New-CISResultObject()`](../windows/modules/CISFramework.psm1:20) object creation
  - [`Get-CISRecommendation()`](../windows/modules/CISFramework.psm1:97) JSON parsing
  - [`Test-CISCompliance()`](../windows/modules/CISFramework.psm1:174) comparison logic
  - [`Test-DomainMember()`](../windows/modules/CISFramework.psm1:455) domain detection
  - [`Get-CISAuditSummary()`](../windows/modules/CISFramework.psm1:516) summary generation

- **CISRemediation.Tests.ps1**: Tests for [`CISRemediation.psm1`](../windows/modules/CISRemediation.psm1) functions
  - [`New-CISRemediationResult()`](../windows/modules/CISRemediation.psm1:21) object creation
  - [`Get-DomainRemediationInstructions()`](../windows/modules/CISRemediation.psm1:196) domain instructions
  - [`Get-CISRemediationSummary()`](../windows/modules/CISRemediation.psm1:461) summary generation
  - Mocked remediation scenarios

- **ModuleIndex.Tests.ps1**: Tests for [`ModuleIndex.psm1`](../windows/modules/ModuleIndex.psm1) functions
  - [`Get-WindowsModuleInfo()`](../windows/modules/ModuleIndex.psm1:53) module enumeration
  - [`Get-WindowsModuleCommands()`](../windows/modules/ModuleIndex.psm1:235) command listing
  - [`Test-WindowsModules()`](../windows/modules/ModuleIndex.psm1:173) module testing
  - [`Show-WindowsModuleHelp()`](../windows/modules/ModuleIndex.psm1:264) help display

### Integration Tests (`tests/integration/`)

- **AuditScripts.Tests.ps1**: Tests for audit script structure and behavior
  - File naming conventions
  - Module imports
  - Function usage patterns
  - Error handling
  - Output validation

- **RemediationScripts.Tests.ps1**: Tests for remediation script structure and behavior
  - File naming conventions
  - Safety features
  - Parameter validation
  - Domain environment handling
  - Output validation

## Test Helpers (`TestHelpers.psm1`)

Provides common utilities for testing:

- **Test Data Generation**:
  - [`New-TestCISResultObject()`](TestHelpers.psm1:10) - Creates test CIS result objects
  - [`New-TestCISRemediationResult()`](TestHelpers.psm1:40) - Creates test remediation result objects
  - [`Get-TestCISRecommendationData()`](TestHelpers.psm1:70) - Provides test recommendation data

- **Mock Functions**:
  - [`Initialize-TestMocks()`](TestHelpers.psm1:95) - Sets up common mock functions
  - [`Clear-TestMocks()`](TestHelpers.psm1:125) - Clears mock functions

- **Assertion Helpers**:
  - [`Assert-CISResultObject()`](TestHelpers.psm1:150) - Validates CIS result structure
  - [`Assert-CISRemediationResult()`](TestHelpers.psm1:175) - Validates remediation result structure

- **File Management**:
  - [`New-TestFile()`](TestHelpers.psm1:210) - Creates temporary test files
  - [`Remove-TestFile()`](TestHelpers.psm1:235) - Removes test files

- **Environment Management**:
  - [`Set-TestEnvironment()`](TestHelpers.psm1:255) - Configures test environment
  - [`Clear-TestEnvironment()`](TestHelpers.psm1:275) - Restores environment

- **Validation Functions**:
  - [`Test-ValidCISID()`](TestHelpers.psm1:295) - Validates CIS ID format
  - [`Test-ValidComplianceStatus()`](TestHelpers.psm1:315) - Validates compliance status

## Running Tests

### Using the Test Runner

```powershell
# Run all tests
.\tests\RunTests.ps1

# Run specific test types
.\tests\RunTests.ps1 -TestType Unit
.\tests\RunTests.ps1 -TestType Integration

# Run with code coverage
.\tests\RunTests.ps1 -CodeCoverage

# Run with verbose output
.\tests\RunTests.ps1 -Verbose

# Run quietly
.\tests\RunTests.ps1 -Quiet

# Specify output path
.\tests\RunTests.ps1 -OutputPath "C:\test-results.xml"
```

### Using Pester Directly

```powershell
# Run unit tests
Invoke-Pester -Path tests\unit

# Run integration tests
Invoke-Pester -Path tests\integration

# Run with configuration
Invoke-Pester -ConfigurationFile tests\PesterConfig.psd1

# Run specific test file
Invoke-Pester -Script tests\unit\CISFramework.Tests.ps1
```

### Using Configuration File

The [`PesterConfig.psd1`](PesterConfig.psd1) file provides comprehensive configuration:

- Test discovery patterns
- Code coverage settings (70% target)
- Output formatting
- Result file generation
- Debug settings

## Test Results

Test results are automatically saved to:

- **XML Results**: `tests/results/test-results.xml`
- **Detailed Results**: `tests/results/detailed-results.xml`
- **Code Coverage**: `tests/results/coverage.xml`
- **HTML Report**: `tests/results/test-results.html` (if available)

## Best Practices

### Writing New Tests

1. **Follow Naming Conventions**:
   - Test files: `ModuleName.Tests.ps1`
   - Test functions: Use `Describe` and `Context` blocks

2. **Use Test Helpers**:
   ```powershell
   Import-Module "$PSScriptRoot\TestHelpers.psm1"
   
   BeforeAll {
       Initialize-TestMocks
   }
   ```

3. **Mock External Dependencies**:
   - Registry operations
   - File system operations
   - Network calls

4. **Test Edge Cases**:
   - Invalid inputs
   - Error conditions
   - Boundary values

### Test Organization

```powershell
Describe "ModuleName Function Tests" {
    Context "FunctionName Function" {
        It "Should do something when conditions are met" {
            # Arrange
            $testData = New-TestCISResultObject -CIS_ID "1.1.1"
            
            # Act
            $result = Test-Function -Input $testData
            
            # Assert
            $result | Should -Be $true
        }
    }
}
```

## Continuous Integration

The test suite is designed for CI/CD integration:

- **Exit Codes**: Script returns 0 for success, 1 for failure
- **XML Output**: Compatible with CI systems
- **Code Coverage**: Trackable coverage metrics
- **Fast Execution**: Mocked dependencies prevent slow tests

## Troubleshooting

### Common Issues

1. **Module Import Errors**:
   - Ensure modules are in the correct relative paths
   - Check module dependencies

2. **Mock Function Conflicts**:
   - Use `Clear-TestMocks` between test contexts
   - Avoid overlapping mock scopes

3. **File Path Issues**:
   - Use relative paths from test directory
   - Test file existence before operations

### Debugging Tests

```powershell
# Enable debug output
$pesterConfig.Debug.ShowFullErrors = $true
$pesterConfig.Debug.WriteDebugMessages = $true

# Run with detailed output
.\tests\RunTests.ps1 -Verbose
```

## Future Enhancements

- Performance testing
- Security testing
- Cross-platform compatibility tests
- Automated test generation
- Test data management
- Parallel test execution