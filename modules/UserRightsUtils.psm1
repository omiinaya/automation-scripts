<#
.SYNOPSIS
    User rights assignment utility functions for PowerShell automation scripts.
.DESCRIPTION
    Provides standardized functions for user rights assignment operations to eliminate
    code duplication across audit and remediation scripts.
.NOTES
    File Name      : UserRightsUtils.psm1
    Author         : System Administrator
    Prerequisite   : PowerShell 5.1 or later
#>

# Import all modules via ModuleIndex (single source of truth)
$originalVerbosePreference = $VerbosePreference
$VerbosePreference = 'SilentlyContinue'
Import-Module "$PSScriptRoot\ModuleIndex.psm1" -Force -WarningAction SilentlyContinue -Verbose:$false
$VerbosePreference = $originalVerbosePreference

# Function to get user rights assignment
function Get-UserRightAssignment {
    <#
    .SYNOPSIS
        Gets the current user rights assignment for a privilege.
    .DESCRIPTION
        Retrieves the list of accounts assigned to a specific user right.
    .PARAMETER PrivilegeName
        The name of the privilege (e.g., SeTrustedCredManAccessPrivilege).
    .EXAMPLE
        Get-UserRightAssignment -PrivilegeName "SeTrustedCredManAccessPrivilege"
    .OUTPUTS
        String array of assigned accounts.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$PrivilegeName
    )
    
    $tempFile = [System.IO.Path]::GetTempFileName()
    try {
        secedit /export /cfg $tempFile /quiet | Out-Null
        $policyContent = Get-Content $tempFile
        $privilegeLine = $policyContent | Where-Object { $_ -like "$PrivilegeName*" }
        
        if ($privilegeLine) {
            $assignment = ($privilegeLine -split "=")[1].Trim()
            return $assignment -split ","
        }
        
        return @()
    } finally {
        Remove-Item $tempFile -ErrorAction SilentlyContinue
    }
}

# Function to grant user right
function Grant-UserRight {
    <#
    .SYNOPSIS
        Grants a user right to specified accounts.
    .DESCRIPTION
        Assigns a user right to one or more accounts using secedit.
    .PARAMETER PrivilegeName
        The name of the privilege to grant.
    .PARAMETER Accounts
        Array of account names to grant the right to.
    .EXAMPLE
        Grant-UserRight -PrivilegeName "SeTrustedCredManAccessPrivilege" -Accounts @("Administrators")
    .OUTPUTS
        Boolean indicating success or failure.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$PrivilegeName,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Accounts
    )
    
    $accountsString = $Accounts -join ","
    $template = @"
[Unicode]
Unicode=yes
[Version]
signature="`$CHICAGO`$"
Revision=1
[Privilege Rights]
$PrivilegeName = $accountsString
"@
    
    $tempFile = [System.IO.Path]::GetTempFileName()
    try {
        $template | Out-File -FilePath $tempFile -Encoding Unicode
        $result = secedit /configure /db secedit.sdb /cfg $tempFile /quiet 2>&1
        return $LASTEXITCODE -eq 0
    } finally {
        Remove-Item $tempFile -ErrorAction SilentlyContinue
    }
}

# Function to revoke user right
function Revoke-UserRight {
    <#
    .SYNOPSIS
        Revokes a user right from all accounts.
    .DESCRIPTION
        Removes all assignments for a specific user right.
    .PARAMETER PrivilegeName
        The name of the privilege to revoke.
    .EXAMPLE
        Revoke-UserRight -PrivilegeName "SeTrustedCredManAccessPrivilege"
    .OUTPUTS
        Boolean indicating success or failure.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$PrivilegeName
    )
    
    $template = @"
[Unicode]
Unicode=yes
[Version]
signature="`$CHICAGO`$"
Revision=1
[Privilege Rights]
$PrivilegeName =
"@
    
    $tempFile = [System.IO.Path]::GetTempFileName()
    try {
        $template | Out-File -FilePath $tempFile -Encoding Unicode
        $result = secedit /configure /db secedit.sdb /cfg $tempFile /quiet 2>&1
        return $LASTEXITCODE -eq 0
    } finally {
        Remove-Item $tempFile -ErrorAction SilentlyContinue
    }
}

# Function to test user right assignment
function Test-UserRightAssignment {
    <#
    .SYNOPSIS
        Tests if a user right is assigned to specified accounts.
    .DESCRIPTION
        Checks if the specified accounts have the given user right.
    .PARAMETER PrivilegeName
        The name of the privilege to test.
    .PARAMETER ExpectedAccounts
        Array of account names expected to have the right.
    .EXAMPLE
        Test-UserRightAssignment -PrivilegeName "SeTrustedCredManAccessPrivilege" -ExpectedAccounts @("Administrators")
    .OUTPUTS
        Boolean indicating compliance.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$PrivilegeName,
        [Parameter(Mandatory=$true)]
        [string[]]$ExpectedAccounts
    )
    
    $currentAssignments = Get-UserRightAssignment -PrivilegeName $PrivilegeName
    
    foreach ($account in $ExpectedAccounts) {
        if ($currentAssignments -notcontains $account) {
            return $false
        }
    }
    
    return $true
}

# Function to add account to user right
function Add-UserRightAssignment {
    <#
    .SYNOPSIS
        Adds an account to an existing user right assignment.
    .DESCRIPTION
        Appends an account to the list of accounts with the specified right.
    .PARAMETER PrivilegeName
        The name of the privilege.
    .PARAMETER Account
        The account name to add.
    .EXAMPLE
        Add-UserRightAssignment -PrivilegeName "SeTrustedCredManAccessPrivilege" -Account "Administrators"
    .OUTPUTS
        Boolean indicating success.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$PrivilegeName,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Account
    )
    
    $currentAssignments = Get-UserRightAssignment -PrivilegeName $PrivilegeName
    
    if ($currentAssignments -contains $Account) {
        return $true
    }
    
    $newAssignments = $currentAssignments + $Account
    return Grant-UserRight -PrivilegeName $PrivilegeName -Accounts $newAssignments
}

# Function to remove account from user right
function Remove-UserRightAssignment {
    <#
    .SYNOPSIS
        Removes an account from a user right assignment.
    .DESCRIPTION
        Removes a specific account from the list of accounts with the specified right.
    .PARAMETER PrivilegeName
        The name of the privilege.
    .PARAMETER Account
        The account name to remove.
    .EXAMPLE
        Remove-UserRightAssignment -PrivilegeName "SeTrustedCredManAccessPrivilege" -Account "Administrators"
    .OUTPUTS
        Boolean indicating success.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$PrivilegeName,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Account
    )
    
    $currentAssignments = Get-UserRightAssignment -PrivilegeName $PrivilegeName
    
    if ($currentAssignments -notcontains $Account) {
        return $true
    }
    
    $newAssignments = $currentAssignments | Where-Object { $_ -ne $Account }
    
    if ($newAssignments.Count -eq 0) {
        return Revoke-UserRight -PrivilegeName $PrivilegeName
    }
    
    return Grant-UserRight -PrivilegeName $PrivilegeName -Accounts $newAssignments
}

# Function to get all user rights assignments
function Get-AllUserRightsAssignments {
    <#
    .SYNOPSIS
        Gets all user rights assignments from security policy.
    .DESCRIPTION
        Retrieves a complete list of all user rights and their assigned accounts.
    .EXAMPLE
        Get-AllUserRightsAssignments
    .OUTPUTS
        Hashtable of privilege names to account arrays.
    #>
    param()
    
    $tempFile = [System.IO.Path]::GetTempFileName()
    try {
        secedit /export /cfg $tempFile /quiet | Out-Null
        $policyContent = Get-Content $tempFile
        $assignments = @{}
        $inPrivilegeSection = $false
        
        foreach ($line in $policyContent) {
            if ($line -match "^\[Privilege Rights\]") {
                $inPrivilegeSection = $true; continue
            }
            if ($inPrivilegeSection -and $line -match "^\[") {
                break
            }
            if ($inPrivilegeSection -and $line -match "^(\w+)\s*=\s*(.*)$") {
                $privilege = $matches[1]
                $accounts = if ($matches[2].Trim()) { $matches[2].Trim() -split "," } else { @() }
                $assignments[$privilege] = $accounts
            }
        }
        
        return $assignments
    } finally {
        Remove-Item $tempFile -ErrorAction SilentlyContinue
    }
}

# Export the module members
Export-ModuleMember -Function Get-UserRightAssignment, Grant-UserRight, Revoke-UserRight, Test-UserRightAssignment, Add-UserRightAssignment, Remove-UserRightAssignment, Get-AllUserRightsAssignments -Verbose:$false
