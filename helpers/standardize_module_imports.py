#!/usr/bin/env python3
"""
Standardize module imports across all .psm1 files.
Replaces the verbose suppression + CommonUtilities import pattern with ModuleIndex import.
"""

import re
from pathlib import Path

MODULES_DIR = Path('/root/projects/automation-scripts/modules')

# Files to skip (these are special cases)
SKIP_FILES = {
    'CommonUtilities.psm1',  # Base module, doesn't import anything
    'ModuleIndex.psm1',      # The hub module, imports everything else
    'CISFramework.psm1',     # Already uses ModuleIndex
    'CISRemediation.psm1',   # Already uses ModuleIndex
}

def standardize_imports(filepath):
    """Standardize imports in a single file."""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original_content = content
    changes = 0
    
    # Pattern 1: Verbose suppression + CommonUtilities import (4-line pattern)
    old_pattern1 = '''# Import CommonUtilities for error handling patterns
$originalVerbosePreference = $VerbosePreference
$VerbosePreference = 'SilentlyContinue'
Import-Module "$PSScriptRoot\\CommonUtilities.psm1" -Force -WarningAction SilentlyContinue -Verbose:$false
$VerbosePreference = $originalVerbosePreference'''
    
    new_pattern1 = '''# Import all modules via ModuleIndex (single source of truth)
$originalVerbosePreference = $VerbosePreference
$VerbosePreference = 'SilentlyContinue'
Import-Module "$PSScriptRoot\\ModuleIndex.psm1" -Force -WarningAction SilentlyContinue -Verbose:$false
$VerbosePreference = $originalVerbosePreference'''
    
    if old_pattern1 in content:
        content = content.replace(old_pattern1, new_pattern1)
        changes += 1
    
    # Pattern 2: Simple CommonUtilities import (single line)
    old_pattern2 = 'Import-Module "$PSScriptRoot\\CommonUtilities.psm1" -Force -WarningAction SilentlyContinue -Verbose:$false'
    new_pattern2 = '''# Import all modules via ModuleIndex (single source of truth)
$originalVerbosePreference = $VerbosePreference
$VerbosePreference = 'SilentlyContinue'
Import-Module "$PSScriptRoot\\ModuleIndex.psm1" -Force -WarningAction SilentlyContinue -Verbose:$false
$VerbosePreference = $originalVerbosePreference'''
    
    if old_pattern2 in content:
        content = content.replace(old_pattern2, new_pattern2)
        changes += 1
    
    # Pattern 3: Without -Verbose:$false
    old_pattern3 = 'Import-Module "$PSScriptRoot\\CommonUtilities.psm1" -Force -WarningAction SilentlyContinue'
    
    if old_pattern3 in content and old_pattern2 not in original_content:
        content = content.replace(old_pattern3, new_pattern2)
        changes += 1
    
    if changes > 0:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"✓ {filepath.name}: {changes} import pattern(s) standardized")
        return changes
    else:
        print(f"  {filepath.name}: No changes needed")
        return 0

def main():
    print("=" * 70)
    print("Module Import Standardization")
    print("=" * 70)
    print()
    
    total_changes = 0
    files_processed = 0
    
    for filepath in sorted(MODULES_DIR.glob('*.psm1')):
        if filepath.name in SKIP_FILES:
            print(f"  {filepath.name}: Skipped (special case)")
            continue
        
        count = standardize_imports(filepath)
        total_changes += count
        files_processed += 1
    
    print()
    print("=" * 70)
    print(f"Files processed: {files_processed}")
    print(f"Total changes: {total_changes}")
    print("=" * 70)
    print()
    print("Standardized modules now import via ModuleIndex.psm1")
    print("This provides:")
    print("  - Single source of truth for all dependencies")
    print("  - Consistent import pattern across all modules")
    print("  - Access to all utility functions through one import")

if __name__ == "__main__":
    main()
