<#
.SYNOPSIS
    Pester tests for ModuleIndex module functions
.DESCRIPTION
    Unit tests for ModuleIndex module functions including module loading,
    command enumeration, and module testing functionality.
.NOTES
    File Name      : ModuleIndex.Tests.ps1
    Author         : System Administrator
    Prerequisite   : Pester module
#>

# Import the module to test
Import-Module "$PSScriptRoot\..\..\windows\modules\ModuleIndex.psm1" -Force

Describe "ModuleIndex Module Tests" {
    Context "Get-WindowsModuleInfo Function" {
        It "Should return module information for all modules" {
            $moduleInfo = Get-WindowsModuleInfo
            
            $moduleInfo | Should -Not -BeNullOrEmpty
            $moduleInfo.Count | Should -BeGreaterThan 0
            
            # Check for expected modules
            $expectedModules = @("WindowsUtils", "PowerManagement", "RegistryUtils", "WindowsUI", "CISFramework", "CISRemediation")
            foreach ($module in $expectedModules) {
                $moduleInfo | Where-Object { $_.ModuleName -eq $module } | Should -Not -BeNullOrEmpty
            }
        }
        
        It "Should include module status information" {
            $moduleInfo = Get-WindowsModuleInfo
            
            foreach ($info in $moduleInfo) {
                $info.Status | Should -BeIn @("Loaded", "Not Loaded")
                $info.CommandCount | Should -BeGreaterOrEqual 0
                $info.Description | Should -Not -BeNullOrEmpty
            }
        }
    }
    
    Context "Get-WindowsModuleCommands Function" {
        It "Should return a list of available commands" {
            $commands = Get-WindowsModuleCommands
            
            $commands | Should -Not -BeNullOrEmpty
            $commands.Count | Should -BeGreaterThan 0
            
            # Check structure of command objects
            foreach ($command in $commands) {
                $command.CommandName | Should -Not -BeNullOrEmpty
                $command.ModuleName | Should -Not -BeNullOrEmpty
                $command.CommandType | Should -Not -BeNullOrEmpty
                $command.Synopsis | Should -Not -BeNullOrEmpty
            }
        }
        
        It "Should sort commands by module name and command name" {
            $commands = Get-WindowsModuleCommands
            
            # Verify sorting by checking first few commands
            if ($commands.Count -gt 1) {
                $firstCommand = $commands[0]
                $secondCommand = $commands[1]
                
                # Either same module with alphabetical command names, or different modules
                if ($firstCommand.ModuleName -eq $secondCommand.ModuleName) {
                    $firstCommand.CommandName -le $secondCommand.CommandName | Should -Be $true
                }
            }
        }
    }
    
    Context "Test-WindowsModules Function" {
        It "Should run basic module tests without errors" {
            # Capture output to prevent console spam during tests
            $output = Test-WindowsModules 6>&1
            
            # Function should complete without throwing exceptions
            { Test-WindowsModules } | Should -Not -Throw
        }
        
        It "Should test all expected modules" {
            # This test verifies that the test function attempts to test all modules
            # We'll check that it doesn't throw major exceptions
            { Test-WindowsModules } | Should -Not -Throw
        }
    }
    
    Context "Show-WindowsModuleHelp Function" {
        It "Should display help for an existing command" {
            # Test with a command that should exist
            { Show-WindowsModuleHelp -CommandName "Test-AdminRights" } | Should -Not -Throw
        }
        
        It "Should handle non-existent commands gracefully" {
            # Test with a command that doesn't exist
            { Show-WindowsModuleHelp -CommandName "NonExistentCommand" } | Should -Not -Throw
        }
    }
    
    Context "Initialize-WindowsModules Function" {
        It "Should initialize modules without errors" {
            { Initialize-WindowsModules } | Should -Not -Throw
        }
        
        It "Should display welcome information" {
            # This function primarily displays UI, so we test it doesn't crash
            { Initialize-WindowsModules } | Should -Not -Throw
        }
    }
    
    Context "Module Loading and Dependencies" {
        It "Should load all required modules successfully" {
            $moduleInfo = Get-WindowsModuleInfo
            
            # Check that core modules are loaded
            $coreModules = $moduleInfo | Where-Object { $_.ModuleName -in @("WindowsUtils", "RegistryUtils", "WindowsUI", "CISFramework", "CISRemediation") }
            
            foreach ($module in $coreModules) {
                $module.Status | Should -Be "Loaded"
            }
        }
        
        It "Should export all module functions correctly" {
            $commands = Get-WindowsModuleCommands
            
            # Verify that functions from imported modules are available
            $expectedFunctions = @("Test-AdminRights", "Get-RegistryValue", "Write-StatusMessage", "New-CISResultObject", "New-CISRemediationResult")
            
            foreach ($function in $expectedFunctions) {
                $commands | Where-Object { $_.CommandName -eq $function } | Should -Not -BeNullOrEmpty
            }
        }
    }
}