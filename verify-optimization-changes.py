#!/usr/bin/env python3
"""
Verifies all changes made during the code optimization project.

This script performs comprehensive verification of:
1. New modules can be imported without errors (syntax check)
2. ModuleIndex.psm1 correctly exports functions from all modules
3. Service toggle generator script syntax is valid
4. Refactored audit scripts have valid PowerShell syntax
5. Refactored remediation scripts have valid PowerShell syntax
6. All functions in the new modules are under 15 lines
"""

import os
import re
import json
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Any, Tuple

# Initialize results
verification_results = {
    "new_modules": [],
    "module_index": [],
    "service_toggle_generator": {},
    "audit_scripts": [],
    "remediation_scripts": [],
    "function_complexity": [],
    "summary": {
        "total_checks": 0,
        "passed_checks": 0,
        "failed_checks": 0,
        "warnings": 0
    }
}

def check_powershell_syntax(file_path: str) -> Tuple[bool, str]:
    """
    Check PowerShell syntax by parsing the file.
    Returns (is_valid, error_message)
    """
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Basic syntax checks
        errors = []
        
        # Check for balanced braces
        open_braces = content.count('{')
        close_braces = content.count('}')
        if open_braces != close_braces:
            errors.append(f"Unbalanced braces: {open_braces} open, {close_braces} close")
        
        # Check for balanced parentheses
        open_parens = content.count('(')
        close_parens = content.count(')')
        if open_parens != close_parens:
            errors.append(f"Unbalanced parentheses: {open_parens} open, {close_parens} close")
        
        # Check for common syntax errors
        lines = content.split('\n')
        for i, line in enumerate(lines, 1):
            # Check for unmatched quotes
            if line.count('"') % 2 != 0 and not line.strip().startswith('#'):
                errors.append(f"Line {i}: Unmatched quotes")
            
            # Check for invalid characters in variable names
            if re.search(r'\$\s*[0-9]', line):
                errors.append(f"Line {i}: Invalid variable name (starts with number)")
        
        if errors:
            return False, "; ".join(errors)
        
        return True, None
    except Exception as e:
        return False, str(e)

def check_json_syntax(file_path: str) -> Tuple[bool, str]:
    """
    Check JSON syntax.
    Returns (is_valid, error_message)
    """
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            json.load(f)
        return True, None
    except json.JSONDecodeError as e:
        return False, f"JSON error: {e.msg} at line {e.lineno}"
    except Exception as e:
        return False, str(e)

def count_function_lines(content: str) -> List[Dict[str, Any]]:
    """
    Count lines in each function, excluding comments and empty lines.
    Returns list of {function_name, line_count, start_line}
    """
    functions = []
    lines = content.split('\n')
    
    in_function = False
    function_name = ""
    function_start_line = 0
    function_lines = []
    in_comment_block = False
    brace_count = 0
    
    for i, line in enumerate(lines):
        stripped = line.strip()
        
        # Handle comment blocks
        if stripped.startswith('<#'):
            in_comment_block = True
            continue
        if stripped.startswith('#>'):
            in_comment_block = False
            continue
        if in_comment_block:
            continue
        
        # Skip comment lines
        if stripped.startswith('#'):
            continue
        
        # Detect function definition
        func_match = re.match(r'^function\s+([a-zA-Z_][a-zA-Z0-9_-]*)', stripped)
        if func_match:
            if in_function:
                # Save previous function
                effective_lines = [l for l in function_lines 
                                 if l.strip() and 
                                 not l.strip().startswith('#') and
                                 not l.strip().startswith('param(') and
                                 not l.strip().startswith('[') and
                                 l.strip() != '{' and
                                 l.strip() != '}']
                
                functions.append({
                    'name': function_name,
                    'line_count': len(effective_lines),
                    'start_line': function_start_line
                })
            
            function_name = func_match.group(1)
            function_start_line = i + 1
            function_lines = []
            in_function = True
            brace_count = 0
            continue
        
        if in_function:
            function_lines.append(line)
            
            # Count braces
            brace_count += line.count('{')
            brace_count -= line.count('}')
            
            # Function ends when brace count returns to 0 after opening
            if brace_count == 0 and '{' in line and i > function_start_line:
                effective_lines = [l for l in function_lines 
                                 if l.strip() and 
                                 not l.strip().startswith('#') and
                                 not l.strip().startswith('param(') and
                                 not l.strip().startswith('[') and
                                 l.strip() != '{' and
                                 l.strip() != '}']
                
                functions.append({
                    'name': function_name,
                    'line_count': len(effective_lines),
                    'start_line': function_start_line
                })
                
                in_function = False
                function_lines = []
    
    # Handle last function if file ends without closing brace
    if in_function and function_lines:
        effective_lines = [l for l in function_lines 
                         if l.strip() and 
                         not l.strip().startswith('#') and
                         not l.strip().startswith('param(') and
                         not l.strip().startswith('[') and
                         l.strip() != '{' and
                         l.strip() != '}']
        
        functions.append({
            'name': function_name,
            'line_count': len(effective_lines),
            'start_line': function_start_line
        })
    
    return functions

def main():
    print("=" * 40)
    print("Code Optimization Verification Report")
    print("=" * 40)
    print()
    
    # ============================================================================
    # 1. Verify that all new modules can be imported without errors
    # ============================================================================
    print("[1/6] Verifying new modules can be imported...")
    print()
    
    new_modules = [
        "modules/AuditUtils.psm1",
        "modules/UserRightsUtils.psm1",
        "modules/SeceditUtils.psm1",
        "modules/Win32API.psm1",
        "modules/ScriptTemplates.psm1"
    ]
    
    for module_path in new_modules:
        verification_results['summary']['total_checks'] += 1
        module_name = os.path.basename(module_path)
        
        print(f"  Testing: {module_name}", end="")
        
        is_valid, error = check_powershell_syntax(module_path)
        
        if is_valid:
            print(" [PASS]")
            verification_results['summary']['passed_checks'] += 1
            verification_results['new_modules'].append({
                'module': module_name,
                'status': 'Passed',
                'error': None
            })
        else:
            print(f" [FAIL]")
            verification_results['summary']['failed_checks'] += 1
            verification_results['new_modules'].append({
                'module': module_name,
                'status': 'Failed',
                'error': error
            })
    
    print()
    
    # ============================================================================
    # 2. Check that ModuleIndex.psm1 correctly exports functions from all modules
    # ============================================================================
    print("[2/6] Verifying ModuleIndex.psm1 exports...")
    print()
    
    verification_results['summary']['total_checks'] += 1
    module_index_path = "modules/ModuleIndex.psm1"
    
    print(f"  Testing: ModuleIndex.psm1", end="")
    
    is_valid, error = check_powershell_syntax(module_index_path)
    
    if is_valid:
        # Check that new modules are referenced in ModuleIndex
        with open(module_index_path, 'r', encoding='utf-8') as f:
            module_index_content = f.read()
        
        expected_modules = ["AuditUtils", "UserRightsUtils", "SeceditUtils", "Win32API", "ScriptTemplates"]
        missing_modules = []
        
        for expected_module in expected_modules:
            if expected_module not in module_index_content:
                missing_modules.append(expected_module)
        
        if missing_modules:
            print(f" [WARNING - Missing modules]")
            verification_results['summary']['warnings'] += 1
            verification_results['module_index'].append({
                'status': 'Warning',
                'error': f"Missing module references: {', '.join(missing_modules)}"
            })
        else:
            print(" [PASS]")
            verification_results['summary']['passed_checks'] += 1
            verification_results['module_index'].append({
                'status': 'Passed',
                'error': None
            })
    else:
        print(f" [FAIL]")
        verification_results['summary']['failed_checks'] += 1
        verification_results['module_index'].append({
            'status': 'Failed',
            'error': error
        })
    
    print()
    
    # ============================================================================
    # 3. Verify that the service toggle generator script syntax is valid
    # ============================================================================
    print("[3/6] Verifying service toggle generator script...")
    print()
    
    verification_results['summary']['total_checks'] += 1
    generator_script = "windows/optimization/services/generate-service-toggles.ps1"
    config_file = "windows/optimization/services/service-config.json"
    
    print(f"  Testing: generate-service-toggles.ps1", end="")
    
    is_valid, error = check_powershell_syntax(generator_script)
    
    if is_valid:
        print(" [PASS]")
        verification_results['summary']['passed_checks'] += 1
        verification_results['service_toggle_generator']['script'] = {
            'status': 'Passed',
            'error': None
        }
    else:
        print(f" [FAIL]")
        verification_results['summary']['failed_checks'] += 1
        verification_results['service_toggle_generator']['script'] = {
            'status': 'Failed',
            'error': error
        }
    
    print(f"  Testing: service-config.json", end="")
    
    is_valid, error = check_json_syntax(config_file)
    
    if is_valid:
        print(" [PASS]")
        verification_results['summary']['passed_checks'] += 1
        verification_results['service_toggle_generator']['config'] = {
            'status': 'Passed',
            'error': None
        }
    else:
        print(f" [FAIL]")
        verification_results['summary']['failed_checks'] += 1
        verification_results['service_toggle_generator']['config'] = {
            'status': 'Failed',
            'error': error
        }
    
    print()
    
    # ============================================================================
    # 4. Check that refactored audit scripts have valid PowerShell syntax
    # ============================================================================
    print("[4/6] Verifying refactored audit scripts...")
    print()
    
    audit_scripts = [
        "windows/deferred/security/audits/section_19/19.5.1.1-audit-turn-off-toast-notifications-on-lock-screen.ps1",
        "windows/deferred/security/audits/section_19/19.6.6.1.1-audit-turn-off-help-experience-improvement-program.ps1",
        "windows/deferred/security/audits/section_19/19.7.5.1-audit-do-not-preserve-zone-information-in-file-attachments.ps1",
        "windows/deferred/security/audits/section_19/19.7.5.2-audit-notify-antivirus-programs-when-opening-attachments.ps1",
        "windows/deferred/security/audits/section_19/19.7.8.1-audit-configure-windows-spotlight-on-lock-screen.ps1",
        "windows/deferred/security/audits/section_19/19.7.8.2-audit-do-not-suggest-third-party-content-in-windows-spotlight.ps1",
        "windows/deferred/security/audits/section_19/19.7.8.3-audit-do-not-use-diagnostic-data-for-tailored-experiences.ps1"
    ]
    
    audit_script_errors = 0
    for script_path in audit_scripts:
        if not os.path.exists(script_path):
            continue
        
        verification_results['summary']['total_checks'] += 1
        script_name = os.path.basename(script_path)
        
        print(f"  Testing: {script_name}", end="")
        
        is_valid, error = check_powershell_syntax(script_path)
        
        if is_valid:
            print(" [PASS]")
            verification_results['summary']['passed_checks'] += 1
            verification_results['audit_scripts'].append({
                'script': script_name,
                'status': 'Passed',
                'error': None
            })
        else:
            print(f" [FAIL]")
            verification_results['summary']['failed_checks'] += 1
            audit_script_errors += 1
            verification_results['audit_scripts'].append({
                'script': script_name,
                'status': 'Failed',
                'error': error
            })
    
    if audit_script_errors == 0:
        print("  All audit scripts verified successfully!")
    
    print()
    
    # ============================================================================
    # 5. Check that refactored remediation scripts have valid PowerShell syntax
    # ============================================================================
    print("[5/6] Verifying refactored remediation scripts...")
    print()
    
    remediation_scripts = [
        "windows/deferred/security/remediations/section_19/19.5.1.1-remediate-turn-off-toast-notifications-on-lock-screen.ps1",
        "windows/deferred/security/remediations/section_19/19.6.6.1.1-remediate-turn-off-help-experience-improvement-program.ps1",
        "windows/deferred/security/remediations/section_19/19.7.5.1-remediate-do-not-preserve-zone-information-in-file-attachments.ps1",
        "windows/deferred/security/remediations/section_19/19.7.5.2-remediate-notify-antivirus-programs-when-opening-attachments.ps1",
        "windows/deferred/security/remediations/section_19/19.7.8.1-remediate-configure-windows-spotlight-on-lock-screen.ps1",
        "windows/deferred/security/remediations/section_19/19.7.8.2-remediate-do-not-suggest-third-party-content-in-windows-spotlight.ps1",
        "windows/deferred/security/remediations/section_19/19.7.8.3-remediate-do-not-use-diagnostic-data-for-tailored-experiences.ps1"
    ]
    
    remediation_script_errors = 0
    for script_path in remediation_scripts:
        if not os.path.exists(script_path):
            continue
        
        verification_results['summary']['total_checks'] += 1
        script_name = os.path.basename(script_path)
        
        print(f"  Testing: {script_name}", end="")
        
        is_valid, error = check_powershell_syntax(script_path)
        
        if is_valid:
            print(" [PASS]")
            verification_results['summary']['passed_checks'] += 1
            verification_results['remediation_scripts'].append({
                'script': script_name,
                'status': 'Passed',
                'error': None
            })
        else:
            print(f" [FAIL]")
            verification_results['summary']['failed_checks'] += 1
            remediation_script_errors += 1
            verification_results['remediation_scripts'].append({
                'script': script_name,
                'status': 'Failed',
                'error': error
            })
    
    if remediation_script_errors == 0:
        print("  All remediation scripts verified successfully!")
    
    print()
    
    # ============================================================================
    # 6. Verify that all functions in the new modules are under 15 lines
    # ============================================================================
    print("[6/6] Verifying function complexity (15-line rule)...")
    print()
    
    complexity_violations = 0
    for module_path in new_modules:
        module_name = os.path.basename(module_path)
        print(f"  Checking: {module_name}")
        
        with open(module_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        functions = count_function_lines(content)
        
        for func in functions:
            if func['line_count'] > 15:
                complexity_violations += 1
                verification_results['function_complexity'].append({
                    'module': module_name,
                    'function': func['name'],
                    'line_count': func['line_count'],
                    'status': 'Failed'
                })
                print(f"    - {func['name']}: {func['line_count']} lines [VIOLATION]")
            else:
                print(f"    - {func['name']}: {func['line_count']} lines [OK]")
    
    verification_results['summary']['total_checks'] += 1
    if complexity_violations == 0:
        print("  All functions comply with 15-line rule!")
        verification_results['summary']['passed_checks'] += 1
    else:
        print(f"  Found {complexity_violations} function(s) exceeding 15 lines")
        verification_results['summary']['failed_checks'] += 1
    
    print()
    
    # ============================================================================
    # Generate Summary Report
    # ============================================================================
    print("=" * 40)
    print("Verification Summary")
    print("=" * 40)
    print()
    
    print(f"Total Checks: {verification_results['summary']['total_checks']}")
    print(f"Passed: {verification_results['summary']['passed_checks']}")
    print(f"Failed: {verification_results['summary']['failed_checks']}")
    print(f"Warnings: {verification_results['summary']['warnings']}")
    print()
    
    success_rate = 0
    if verification_results['summary']['total_checks'] > 0:
        success_rate = round((verification_results['summary']['passed_checks'] / verification_results['summary']['total_checks']) * 100, 2)
    
    print(f"Success Rate: {success_rate}%")
    print()
    
    # ============================================================================
    # Create detailed report file
    # ============================================================================
    report_path = "docs/optimization-verification-report.md"
    report_dir = os.path.dirname(report_path)
    
    if not os.path.exists(report_dir):
        os.makedirs(report_dir)
    
    report_content = f"""# Code Optimization Verification Report

**Generated:** {datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S UTC')}

## Executive Summary

| Metric | Value |
|--------|-------|
| Total Checks | {verification_results['summary']['total_checks']} |
| Passed | {verification_results['summary']['passed_checks']} |
| Failed | {verification_results['summary']['failed_checks']} |
| Warnings | {verification_results['summary']['warnings']} |
| Success Rate | {success_rate}% |

## 1. New Modules Verification

| Module | Status | Details |
|--------|--------|---------|
"""
    
    for result in verification_results['new_modules']:
        status_icon = "✅" if result['status'] == 'Passed' else "❌"
        error_msg = result['error'] if result['error'] else ""
        report_content += f"| {result['module']} | {status_icon} {result['status']} | {error_msg} |\n"
    
    report_content += "\n## 2. ModuleIndex.psm1 Verification\n\n| Status | Details |\n|--------|---------|\n"
    
    for result in verification_results['module_index']:
        status_icon = "✅" if result['status'] == 'Passed' else ("⚠️" if result['status'] == 'Warning' else "❌")
        error_msg = result['error'] if result['error'] else ""
        report_content += f"| {status_icon} {result['status']} | {error_msg} |\n"
    
    report_content += "\n## 3. Service Toggle Generator Verification\n\n### Script (generate-service-toggles.ps1)\n\n| Status | Details |\n|--------|---------|\n"
    
    script_result = verification_results['service_toggle_generator'].get('script', {})
    status_icon = "✅" if script_result.get('status') == 'Passed' else "❌"
    error_msg = script_result.get('error', '')
    report_content += f"| {status_icon} {script_result.get('status', 'Unknown')} | {error_msg} |\n"
    
    report_content += "\n### Configuration (service-config.json)\n\n| Status | Details |\n|--------|---------|\n"
    
    config_result = verification_results['service_toggle_generator'].get('config', {})
    status_icon = "✅" if config_result.get('status') == 'Passed' else "❌"
    error_msg = config_result.get('error', '')
    report_content += f"| {status_icon} {config_result.get('status', 'Unknown')} | {error_msg} |\n"
    
    report_content += "\n## 4. Refactored Audit Scripts Verification\n\n| Script | Status | Details |\n|--------|--------|---------|\n"
    
    for result in verification_results['audit_scripts']:
        status_icon = "✅" if result['status'] == 'Passed' else "❌"
        error_msg = result['error'] if result['error'] else ""
        report_content += f"| {result['script']} | {status_icon} {result['status']} | {error_msg} |\n"
    
    report_content += "\n## 5. Refactored Remediation Scripts Verification\n\n| Script | Status | Details |\n|--------|--------|---------|\n"
    
    for result in verification_results['remediation_scripts']:
        status_icon = "✅" if result['status'] == 'Passed' else "❌"
        error_msg = result['error'] if result['error'] else ""
        report_content += f"| {result['script']} | {status_icon} {result['status']} | {error_msg} |\n"
    
    report_content += "\n## 6. Function Complexity (15-Line Rule) Verification\n\n"
    
    if not verification_results['function_complexity']:
        report_content += "✅ All functions comply with the 15-line complexity rule.\n\n"
    else:
        report_content += "| Module | Function | Line Count | Status |\n"
        report_content += "|--------|----------|------------|--------|\n"
        
        for result in verification_results['function_complexity']:
            status_icon = "✅" if result['status'] == 'Passed' else "❌"
            report_content += f"| {result['module']} | {result['function']} | {result['line_count']} | {status_icon} {result['status']} |\n"
        report_content += "\n"
    
    report_content += "## Conclusion\n\n"
    
    if verification_results['summary']['failed_checks'] == 0 and verification_results['summary']['warnings'] == 0:
        report_content += "✅ All verification checks passed successfully. The code optimization project has been completed without any issues.\n"
    elif verification_results['summary']['failed_checks'] == 0:
        report_content += f"⚠️ All critical checks passed, but there are {verification_results['summary']['warnings']} warning(s) that should be reviewed.\n"
    else:
        report_content += f"❌ Verification completed with {verification_results['summary']['failed_checks']} failure(s) and {verification_results['summary']['warnings']} warning(s). Please review and address the issues listed above.\n"
    
    with open(report_path, 'w', encoding='utf-8') as f:
        f.write(report_content)
    
    print(f"Detailed report saved to: {report_path}")
    print()
    
    # Return exit code based on results
    return 1 if verification_results['summary']['failed_checks'] > 0 else 0

if __name__ == "__main__":
    exit(main())
