#!/usr/bin/env python3
"""
Python script to update module import paths in Windows PowerShell scripts
This script updates all references from windows/modules/ to the new modules/ location
"""

import os
import re

# Define the patterns to search for and their replacements
patterns = {
    # Pattern 1: Direct module imports (like CISFramework.psm1)
    r'Import-Module "\$PSScriptRoot\\..\\..\\modules\\': r'Import-Module "$PSScriptRoot\\..\\..\\..\\modules\\',
    
    # Pattern 2: ModuleIndex imports with Join-Path
    r'Join-Path \$PSScriptRoot "..\\..\\..\\modules\\ModuleIndex\.psm1"': r'Join-Path $PSScriptRoot "..\\..\\..\\..\\modules\\ModuleIndex.psm1"',
    
    # Pattern 3: ModuleIndex imports with relative path (root level)
    r'Join-Path \$PSScriptRoot "modules\\ModuleIndex\.psm1"': r'Join-Path $PSScriptRoot "..\\modules\\ModuleIndex.psm1"',
    
    # Pattern 4: Direct imports with fewer levels
    r'Import-Module "\$PSScriptRoot\\..\\modules\\': r'Import-Module "$PSScriptRoot\\..\\..\\modules\\',
    
    # Pattern 5: ModuleIndex imports with fewer levels
    r'Join-Path \$PSScriptRoot "..\\..\\modules\\ModuleIndex\.psm1"': r'Join-Path $PSScriptRoot "..\\..\\..\\modules\\ModuleIndex.psm1"',
}

# Get all PowerShell scripts in the windows directory recursively
script_files = []
for root, dirs, files in os.walk("windows"):
    for file in files:
        if file.endswith(".ps1"):
            script_files.append(os.path.join(root, file))

print(f"Found {len(script_files)} PowerShell scripts to process")

updated_files = 0

for file_path in script_files:
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        file_updated = False
        
        for pattern, replacement in patterns.items():
            if re.search(pattern, content):
                print(f"Updating pattern '{pattern}' in {file_path}")
                content = re.sub(pattern, replacement, content)
                file_updated = True
        
        if file_updated and content != original_content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"Updated: {file_path}")
            updated_files += 1
            
    except Exception as e:
        print(f"Error processing {file_path}: {e}")

print(f"\nUpdate complete!")
print(f"Files processed: {len(script_files)}")
print(f"Files updated: {updated_files}")
