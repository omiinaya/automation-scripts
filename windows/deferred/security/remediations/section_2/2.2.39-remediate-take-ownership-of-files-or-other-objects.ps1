<#
.SYNOPSIS
    Remediation script for CIS 2.2.39: Ensure 'Take ownership of files or other objects' is set to 'Administrators'
.DESCRIPTION
    This script remediates the User Rights Assignment policy for 'Take ownership of files or other objects' to ensure it is configured as recommended.
.PARAMETER None
    This script does not accept parameters.
.EXAMPLE
    .\2.2.39-remediate-take-ownership-of-files-or-other-objects.ps1
.NOTES
    CIS ID: 2.2.39
    Profile: L1
    Recommended: Administrators
    Default: Administrators
#> 

# Import the CIS Remediation module
Import-Module -Name "$PSScriptRoot\..\..\modules\CISRemediation.psm1" -Force

# Define the CIS ID and policy information
$CisId = "2.2.39"
$PolicyName = "SeTakeOwnershipPrivilege"
$RecommendedPrincipals = @("Administrators")
$PolicyDisplayName = "Take ownership of files or other objects"

# Create the remediation configuration
$RemediationConfig = @{
    CisId = $CisId
    PolicyName = $PolicyName
    RecommendedPrincipals = $RecommendedPrincipals
    PolicyDisplayName = $PolicyDisplayName
    PolicyPath = "Computer Configuration\Policies\Windows Settings\Security Settings\Local Policies\User Rights Assignment\Take ownership of files or other objects"
}

# Execute the remediation
$RemediationResult = Set-CISUserRightsAssignment @RemediationConfig

# Output the result
return $RemediationResult