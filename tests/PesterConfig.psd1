@{
    # Pester configuration file for CIS Automation Scripts test suite
    
    # Test discovery settings
    Run = @{
        # Test script discovery patterns
        Path = @(
            'tests/unit/*.Tests.ps1',
            'tests/integration/*.Tests.ps1'
        )
        
        # Exclude patterns
        ExcludePath = @(
            'tests/results/*',
            'tests/logs/*'
        )
        
        # Test execution order
        TestExtension = @('.Tests.ps1')
    }
    
    # Test result output settings
    Output = @{
        # Output verbosity
        Verbosity = 'Detailed'
        
        # Output format
        # Options: 'NUnitXml', 'JUnitXml', 'NUnit2.5', 'NUnit3'
        # Default: Console output
        # Uncomment to enable XML output for CI/CD
        # Format = 'NUnitXml'
        # OutputPath = 'tests/results/pester-results.xml'
    }
    
    # Code coverage settings
    CodeCoverage = @{
        # Enable code coverage
        Enabled = $true
        
        # Files to include in coverage analysis
        Include = @(
            'windows/modules/*.psm1',
            'windows/modules/*.ps1'
        )
        
        # Files to exclude from coverage analysis
        Exclude = @(
            'windows/modules/Test-*.ps1',
            'windows/modules/Example-*.ps1'
        )
        
        # Coverage output settings
        OutputPath = 'tests/results/coverage.xml'
        OutputFormat = 'CoverageGutters'
        
        # Minimum coverage threshold (percentage)
        CoveragePercentTarget = 70
    }
    
    # Test execution settings
    TestResult = @{
        # Enable test result output
        Enabled = $true
        
        # Test result file path
        OutputPath = 'tests/results/test-results.xml'
        
        # Test result format
        OutputFormat = 'NUnitXml'
    }
    
    # Filter settings
    Filter = @{
        # Tag-based filtering
        Tag = @()
        
        # Exclude tags
        ExcludeTag = @('Slow', 'Integration')
        
        # Test name filtering
        TestName = @()
    }
    
    # Debug settings
    Debug = @{
        # Show full error messages
        ShowFullErrors = $false
        
        # Write debug information
        WriteDebugMessages = $false
        
        # Write diagnostic messages
        WriteDiagnosticMessages = $false
    }
    
    # Should settings
    Should = @{
        # Error action for Should assertions
        ErrorAction = 'Stop'
    }
    
    # Code signing settings (if applicable)
    CodeSigning = @{
        # Require signed scripts
        RequireSigned = $false
        
        # Public key for signature validation
        PublicKey = ''
    }
}