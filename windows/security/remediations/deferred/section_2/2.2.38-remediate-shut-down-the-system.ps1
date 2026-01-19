<#
.SYNOPSIS
    Remediation script for CIS 2.2.38: Ensure 'Shut down the system' is set to 'Administrators, Users'
.DESCRIPTION
    This script remediates the User Rights Assignment policy for 'Shut down the system' to ensure it is configured as recommended.
.PARAMETER None
    This script does not accept parameters.
.EXAMPLE
    .\2.2.38-remediate-shut-down-the-system.ps1
.NOTES
    CIS ID: 2.2.38
    Profile: L1
    Recommended: Administrators, Users
    Default: Administrators, Backup Operators, Users
#> 

# Import the CIS Remediation module
Import-Module -Name "$PSScriptRoot\..\..\modules\CISRemediation.psm1" -Force

# Define the CIS ID and policy information
$CisId = "2.2.38"
$PolicyName = "SeShutdownPrivilege"
$RecommendedPrincipals = @("Administrators", "Users")
$PolicyDisplayName = "Shut down the system"

# Create the remediation configuration
$RemediationConfig = @{
    CisId = $CisId
    PolicyName = $PolicyName
    RecommendedPrincipals = $RecommendedPrincipals
    PolicyDisplayName = $PolicyDisplayName
    PolicyPath = "Computer Configuration\Policies\Windows Settings\Security Settings\Local Policies\User Rights Assignment\Shut down the system"
}

# Execute the remediation
$RemediationResult = Set-CISUserRightsAssignment @RemediationConfig

# Output the result
return $RemediationResult