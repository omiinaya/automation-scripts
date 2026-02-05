#!/usr/bin/env python3
"""
Migrate audit and remediation scripts to use ScriptTemplates module.
This script standardizes all scripts to use the approved template patterns.
"""

import os
import re
import sys
from pathlib import Path
from datetime import datetime

class ScriptMigrator:
    def __init__(self, base_path):
        self.base_path = Path(base_path)
        self.stats = {
            'audits_migrated': 0,
            'remediations_migrated': 0,
            'skipped': 0,
            'errors': [],
            'already_good': 0
        }
    
    def is_using_script_templates(self, content):
        """Check if script already uses ScriptTemplates pattern."""
        return 'ScriptTemplates.psm1' in content or 'Invoke-CISAuditScript' in content or 'Invoke-CISRemediationScript' in content
    
    def extract_cis_info(self, filepath, content):
        """Extract CIS ID and other metadata from script."""
        # Try to extract CIS ID from filename
        filename = filepath.name
        cis_id_match = re.search(r'(\d+\.\d+(?:\.\d+)*)', filename)
        cis_id = cis_id_match.group(1) if cis_id_match else "X.X.X"
        
        # Try to extract section from path
        section_match = re.search(r'section_(\d+)', str(filepath))
        section = section_match.group(1) if section_match else cis_id.split('.')[0]
        
        return {
            'cis_id': cis_id,
            'section': section,
            'filename': filename
        }
    
    def detect_audit_type(self, content):
        """Detect the type of audit (Registry, Service, etc.)."""
        if 'AuditType "Registry"' in content or 'RegistryPath' in content:
            return 'Registry'
        elif 'AuditType "Service"' in content or 'ServiceName' in content:
            return 'Service'
        elif 'AuditType "GroupPolicy"' in content:
            return 'GroupPolicy'
        elif 'AuditType "Custom"' in content:
            return 'Custom'
        else:
            return 'Custom'
    
    def extract_audit_logic(self, content):
        """Extract the core audit logic from a script."""
        # Remove comments at the top
        lines = content.split('\n')
        
        # Find where actual logic starts (after imports and variable declarations)
        logic_start = 0
        for i, line in enumerate(lines):
            if 'Import-Module' in line:
                logic_start = i + 1
            if 'try {' in line and logic_start > 0:
                logic_start = i
                break
        
        # Extract logic between try and catch
        logic_lines = []
        in_try = False
        brace_count = 0
        
        for line in lines[logic_start:]:
            if 'try {' in line:
                in_try = True
                brace_count = 1
                continue
            
            if in_try:
                if '{' in line:
                    brace_count += line.count('{')
                if '}' in line:
                    brace_count -= line.count('}')
                
                if brace_count <= 0 and '}' in line:
                    break
                
                logic_lines.append(line)
        
        return '\n'.join(logic_lines).strip()
    
    def create_audit_script_template(self, cis_info, audit_type, audit_logic):
        """Create standardized audit script using ScriptTemplates."""
        template = f'''# Audit: {cis_info['cis_id']}
# CIS Benchmark: {cis_info['cis_id']} (L1)

[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISAuditScript -ScriptRoot $scriptRoot -AuditBlock {{
{audit_logic}
}}
'''
        return template
    
    def create_remediation_script_template(self, cis_info, remediation_logic):
        """Create standardized remediation script using ScriptTemplates."""
        template = f'''# Remediation: {cis_info['cis_id']}
# CIS Benchmark: {cis_info['cis_id']} (L1)

[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISRemediationScript -ScriptRoot $scriptRoot -RemediationBlock {{
{remediation_logic}
}}
'''
        return template
    
    def migrate_audit_script(self, filepath):
        """Migrate an audit script to use ScriptTemplates."""
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Skip if already using ScriptTemplates
            if self.is_using_script_templates(content):
                self.stats['already_good'] += 1
                return True
            
            cis_info = self.extract_cis_info(filepath, content)
            audit_type = self.detect_audit_type(content)
            audit_logic = self.extract_audit_logic(content)
            
            # Create new standardized script
            new_content = self.create_audit_script_template(cis_info, audit_type, audit_logic)
            
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(new_content)
            
            self.stats['audits_migrated'] += 1
            return True
            
        except Exception as e:
            self.stats['errors'].append(f"{filepath}: {str(e)}")
            return False
    
    def migrate_remediation_script(self, filepath):
        """Migrate a remediation script to use ScriptTemplates."""
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Skip if already using ScriptTemplates
            if self.is_using_script_templates(content):
                self.stats['already_good'] += 1
                return True
            
            cis_info = self.extract_cis_info(filepath, content)
            remediation_logic = self.extract_audit_logic(content)  # Same logic extraction
            
            # Create new standardized script
            new_content = self.create_remediation_script_template(cis_info, remediation_logic)
            
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(new_content)
            
            self.stats['remediations_migrated'] += 1
            return True
            
        except Exception as e:
            self.stats['errors'].append(f"{filepath}: {str(e)}")
            return False
    
    def migrate_all(self):
        """Migrate all audit and remediation scripts."""
        print("=" * 70)
        print("SCRIPT MIGRATION TO ScriptTemplates")
        print("=" * 70)
        print(f"Started: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print()
        
        # Migrate audit scripts
        audit_base = self.base_path / "windows" / "deferred" / "security" / "audits"
        if audit_base.exists():
            print("Processing audit scripts...")
            for section_dir in sorted(audit_base.iterdir()):
                if section_dir.is_dir() and section_dir.name.startswith('section_'):
                    for script_file in sorted(section_dir.glob('*.ps1')):
                        if 'audit' in script_file.name.lower():
                            print(f"  {script_file.name}...", end=' ')
                            if self.migrate_audit_script(script_file):
                                print("✓")
                            else:
                                print("✗")
        
        # Migrate remediation scripts
        remediation_base = self.base_path / "windows" / "deferred" / "security" / "remediations"
        if remediation_base.exists():
            print("\nProcessing remediation scripts...")
            for section_dir in sorted(remediation_base.iterdir()):
                if section_dir.is_dir() and section_dir.name.startswith('section_'):
                    for script_file in sorted(section_dir.glob('*.ps1')):
                        if 'remediate' in script_file.name.lower():
                            print(f"  {script_file.name}...", end=' ')
                            if self.migrate_remediation_script(script_file):
                                print("✓")
                            else:
                                print("✗")
        
        # Print summary
        print()
        print("=" * 70)
        print("MIGRATION SUMMARY")
        print("=" * 70)
        print(f"Audit scripts migrated: {self.stats['audits_migrated']}")
        print(f"Remediation scripts migrated: {self.stats['remediations_migrated']}")
        print(f"Already using templates: {self.stats['already_good']}")
        print(f"Total processed: {self.stats['audits_migrated'] + self.stats['remediations_migrated'] + self.stats['already_good']}")
        print(f"Errors: {len(self.stats['errors'])}")
        
        if self.stats['errors']:
            print()
            print("Errors encountered:")
            for error in self.stats['errors'][:10]:  # Show first 10
                print(f"  - {error}")
            if len(self.stats['errors']) > 10:
                print(f"  ... and {len(self.stats['errors']) - 10} more")
        
        print()
        print(f"Completed: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")

def main():
    """Main entry point."""
    base_path = Path('/root/projects/automation-scripts')
    migrator = ScriptMigrator(base_path)
    migrator.migrate_all()

if __name__ == "__main__":
    main()
