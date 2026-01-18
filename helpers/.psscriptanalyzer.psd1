@{
    # Include rules from the following built-in rule sets
    IncludeRules = @(
        'PSUseApprovedVerbs',
        'PSAvoidUsingCmdletAliases',
        'PSUseDeclaredVarsMoreThanAssignments',
        'PSUseConsistentWhitespace',
        'PSUseConsistentIndentation',
        'PSUseCorrectCasing',
        'PSPlaceOpenBrace',
        'PSPlaceCloseBrace',
        'PSUseSupportsShouldProcess',
        'PSUseShouldProcessForStateChangingFunctions',
        'PSAvoidUsingPositionalParameters',
        'PSUseSingularNouns',
        'PSUseCmdletCorrectly',
        'PSUseOutputTypeCorrectly',
        'PSAvoidUsingEmptyCatchBlock',
        'PSUseProcessBlockForPipeline',
        'PSUseBOMForUnicodeEncodedFile',
        'PSAvoidUsingInvokeExpression',
        'PSAvoidUsingWMICmdlet',
        'PSAvoidUsingPlainTextForPassword',
        'PSAvoidUsingConvertToSecureStringWithPlainText',
        'PSAvoidUsingUserNameAndPassWordParams',
        'PSUsePSCredentialType',
        'PSDSC*'
    )

    # Exclude the following rules from the built-in rule sets
    ExcludeRules = @(
        'PSAvoidGlobalVars',
        'PSAvoidUsingWriteHost',
        'PSUseToExportFieldsInManifest',
        'PSUseShouldProcessForStateChangingFunctions',
        'PSAvoidUsingDeprecatedManifestFields'
    )

    # Custom rule settings
    Rules = @{
        PSUseApprovedVerbs = @{
            Enable = $true
        }

        PSAvoidUsingCmdletAliases = @{
            Enable = $true
            Whitelist = @('foreach', 'where', 'select')
        }

        PSUseDeclaredVarsMoreThanAssignments = @{
            Enable = $true
        }

        PSUseConsistentWhitespace = @{
            Enable = $true
            CheckParameter = $true
            CheckOperator = $true
            CheckSeparator = $true
        }

        PSUseConsistentIndentation = @{
            Enable = $true
            IndentationSize = 4
            Kind = 'space'
        }

        PSUseCorrectCasing = @{
            Enable = $true
        }

        PSPlaceOpenBrace = @{
            Enable = $true
            OnSameLine = $true
            NewLineAfter = $true
            IgnoreOneLineBlock = $true
        }

        PSPlaceCloseBrace = @{
            Enable = $true
            NewLineAfter = $true
            IgnoreOneLineBlock = $true
        }

        PSAvoidUsingPositionalParameters = @{
            Enable = $true
        }

        PSUseSingularNouns = @{
            Enable = $true
        }

        PSUseCmdletCorrectly = @{
            Enable = $true
        }

        PSUseOutputTypeCorrectly = @{
            Enable = $true
        }

        PSAvoidUsingEmptyCatchBlock = @{
            Enable = $true
        }

        PSUseProcessBlockForPipeline = @{
            Enable = $true
        }

        PSUseBOMForUnicodeEncodedFile = @{
            Enable = $true
        }

        PSAvoidUsingInvokeExpression = @{
            Enable = $true
        }

        PSAvoidUsingWMICmdlet = @{
            Enable = $true
        }

        PSAvoidUsingPlainTextForPassword = @{
            Enable = $true
        }

        PSAvoidUsingConvertToSecureStringWithPlainText = @{
            Enable = $true
        }

        PSAvoidUsingUserNameAndPassWordParams = @{
            Enable = $true
        }

        PSUsePSCredentialType = @{
            Enable = $true
        }

        # Custom rules for CIS scripts
        PSUseCISFramework = @{
            Enable = $true
            Description = 'Use CISFramework functions for consistency'
        }

        PSUseCISRemediation = @{
            Enable = $true
            Description = 'Use CISRemediation functions for consistency'
        }

        PSAvoidHardcodedPaths = @{
            Enable = $true
            Description = 'Avoid hardcoded file paths'
        }

        PSUseModuleIndex = @{
            Enable = $true
            Description = 'Use ModuleIndex for module imports'
        }

        PSUseStandardizedOutput = @{
            Enable = $true
            Description = 'Use standardized output functions from WindowsUI module'
        }

        PSAvoidDuplicateCode = @{
            Enable = $true
            Description = 'Avoid code duplication by using framework functions'
        }

        PSUseErrorHandling = @{
            Enable = $true
            Description = 'Use proper error handling with try/catch blocks'
        }

        PSUseParameterValidation = @{
            Enable = $true
            Description = 'Use parameter validation in functions'
        }

        PSUseCommentBasedHelp = @{
            Enable = $true
            Description = 'Use comment-based help for all functions'
        }

        PSUseConsistentNaming = @{
            Enable = $true
            Description = 'Use consistent naming conventions'
        }
    }

    # Severity settings
    Severity = @(
        @{
            Name = 'Error'
            Include = @('PSAvoidUsingInvokeExpression', 'PSAvoidUsingWMICmdlet', 'PSAvoidUsingPlainTextForPassword')
        }
        @{
            Name = 'Warning'
            Include = @('PSUseApprovedVerbs', 'PSAvoidUsingCmdletAliases', 'PSUseConsistentWhitespace')
        }
        @{
            Name = 'Information'
            Include = @('PSUseConsistentIndentation', 'PSUseCorrectCasing')
        }
    )

    # Script analysis settings
    ScriptAnalysis = @{
        # Analyze script files
        AnalyzeScriptFiles = $true
        
        # Analyze module files
        AnalyzeModuleFiles = $true
        
        # Analyze function files
        AnalyzeFunctionFiles = $true
        
        # Recursive analysis
        Recurse = $true
        
        # Report progress
        ReportProgress = $true
    }

    # Path settings
    Path = @{
        # Include paths
        Include = @(
            'windows/security/audits/*.ps1',
            'windows/security/remediations/*.ps1',
            'modules/*.psm1',
            'windows/*.ps1'
        )
        
        # Exclude paths
        Exclude = @(
            'modules/Test-*.ps1',
            'modules/Example-*.ps1',
            'windows/security/remediations/secedit.*'
        )
    }

    # Output settings
    Output = @{
        # Output format
        Format = 'Sarif'
        
        # Output file
        OutputFile = 'psscriptanalyzer-results.sarif'
        
        # Verbose output
        Verbose = $false
    }
}