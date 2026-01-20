#!/usr/bin/env python3
"""
Test script to validate account lockout remediation scripts
"""

import re
from pathlib import Path


def validate_remediation_script(file_path):
    """Validate a remediation script for proper structure and syntax"""
    print(f"\nValidating: {file_path}")
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Check for required components
        checks = {
            'CIS Benchmark header': r'# CIS Benchmark:.*\d+\.\d+\.\d+',
            'CmdletBinding': r'\[CmdletBinding\(\)\]',
            'Import module': r'Import-Module',
            'Admin rights check': r'Test-AdminRights',
            'Security policy template': r'\[System Access\]',
            'Invoke-CISRemediation': (
                r'Invoke-CISRemediation.*CIS_ID.*"\d+\.\d+\.\d+"'
            ),
            'Error handling': r'catch\s*{',
        }
        
        all_passed = True
        for check_name, pattern in checks.items():
            if re.search(pattern, content, re.MULTILINE | re.IGNORECASE):
                print(f"  ✓ {check_name}")
            else:
                print(f"  ✗ {check_name}")
                all_passed = False
        
        # Extract CIS ID from file name
        cis_id_match = re.search(r'(\d+\.\d+\.\d+)', str(file_path))
        if cis_id_match:
            cis_id = cis_id_match.group(1)
            # Check if CIS ID is referenced in the script
            if cis_id in content:
                print(f"  ✓ CIS ID {cis_id} referenced correctly")
            else:
                print(f"  ✗ CIS ID {cis_id} not found in script")
                all_passed = False
        
        return all_passed
        
    except Exception as e:
        print(f"  ✗ Error reading file: {e}")
        return False


def main():
    """Main function"""
    print("=== Account Lockout Remediation Script Validation ===")
    
    # Find all remediation scripts for account lockout controls
    remediation_dir = Path("windows/security/remediations")
    account_lockout_scripts = []
    
    for script_file in remediation_dir.glob("*.ps1"):
        if "1.2." in script_file.name:
            account_lockout_scripts.append(script_file)
    
    script_count = len(account_lockout_scripts)
    print(f"Found {script_count} account lockout remediation scripts")
    
    # Validate each script
    validation_results = {}
    for script_path in account_lockout_scripts:
        is_valid = validate_remediation_script(script_path)
        validation_results[script_path.name] = is_valid
    
    # Summary
    print("\n=== Validation Summary ===")
    passed_count = sum(1 for result in validation_results.values() if result)
    total_count = len(validation_results)
    
    for script_name, is_valid in validation_results.items():
        status = "PASS" if is_valid else "FAIL"
        print(f"{script_name}: {status}")
    
    print(f"\nResults: {passed_count}/{total_count} scripts passed validation")
    
    if passed_count == total_count:
        print("✓ All scripts are properly structured")
        return 0
    else:
        print("✗ Some scripts require attention")
        return 1


if __name__ == "__main__":
    exit(main())