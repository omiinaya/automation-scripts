<#
.SYNOPSIS
    Audit script for CIS 2.2.38: Ensure 'Shut down the system' is set to 'Administrators, Users'
.DESCRIPTION
    This script audits the User Rights Assignment policy for 'Shut down the system' to ensure it is configured as recommended.
.PARAMETER None
    This script does not accept parameters.
.EXAMPLE
    .\2.2.38-audit-shut-down-the-system.ps1
.NOTES
    CIS ID: 2.2.38
    Profile: L1
    Recommended: Administrators, Users
    Default: Administrators, Backup Operators, Users
#> 

# Import the CIS Framework module
Import-Module -Name "$PSScriptRoot\..\..\modules\CISFramework.psm1" -Force

# Define the CIS ID and policy information
$CisId = "2.2.38"
$PolicyName = "SeShutdownPrivilege"
$RecommendedPrincipals = @("Administrators", "Users")
$PolicyDisplayName = "Shut down the system"

# Create the audit configuration
$AuditConfig = @{
    CisId = $CisId
    PolicyName = $PolicyName
    RecommendedPrincipals = $RecommendedPrincipals
    PolicyDisplayName = $PolicyDisplayName
    PolicyPath = "Computer Configuration\Policies\Windows Settings\Security Settings\Local Policies\User Rights Assignment\Shut down the system"
}

# Execute the audit
$AuditResult = Test-CISUserRightsAssignment @AuditConfig

# Output the result
return $AuditResult