#!/usr/bin/env python3
"""
Replace Write-Host usages with Write-StatusMessage across all module files.
"""

import re
from pathlib import Path

# Module files to process
MODULES_DIR = Path('/root/projects/automation-scripts/modules')

# Files to process (prioritized by count)
FILES_TO_PROCESS = [
    'PowerManagement.psm1',  # 7 usages
    'RegistryUtils.psm1',    # 9 usages
    'WindowsUtils.psm1',     # 11 usages
    'CISFramework.psm1',     # 16 usages
    'CISRemediation.psm1',   # 13 usages
    'ModuleIndex.psm1',      # 17 usages
    'CommonUtilities.psm1',  # 22 usages
    'WindowsUI.psm1',        # 40 usages
]

def replace_write_host_in_file(filepath):
    """Replace Write-Host with Write-StatusMessage in a single file."""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original_content = content
    replacements = 0
    
    # Pattern 1: Write-Host "message" -ForegroundColor Color
    # Replace with: Write-StatusMessage -Message "message" -Type Type
    pattern1 = r'Write-Host\s+"([^"]+)"\s+-ForegroundColor\s+(\w+)'
    
    def replace_with_status(match):
        message = match.group(1)
        color = match.group(2)
        
        # Map colors to types
        type_map = {
            'Green': 'Success',
            'Red': 'Error',
            'Yellow': 'Warning',
            'Cyan': 'Info',
            'White': 'Info',
            'Gray': 'Info'
        }
        msg_type = type_map.get(color, 'Info')
        
        return f'Write-StatusMessage -Message "{message}" -Type {msg_type}'
    
    content, count1 = re.subn(pattern1, replace_with_status, content)
    replacements += count1
    
    # Pattern 2: Write-Host "" (empty line)
    # Keep as-is or remove
    pattern2 = r'Write-Host\s+""\s*$'
    content, count2 = re.subn(pattern2, '# Empty line for formatting', content, flags=re.MULTILINE)
    replacements += count2
    
    # Pattern 3: Write-Host "message" (no color)
    # Replace with: Write-StatusMessage -Message "message" -Type Info
    pattern3 = r'Write-Host\s+"([^"]+)"(?!\s*-ForegroundColor)'
    
    def replace_simple(match):
        message = match.group(1)
        return f'Write-StatusMessage -Message "{message}" -Type Info'
    
    content, count3 = re.subn(pattern3, replace_simple, content)
    replacements += count3
    
    if replacements > 0:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"✓ {filepath.name}: {replacements} replacements")
        return replacements
    else:
        print(f"  {filepath.name}: No replacements needed")
        return 0

def ensure_commonutilities_import(filepath):
    """Ensure file imports CommonUtilities for Write-StatusMessage."""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Check if already imports CommonUtilities or ModuleIndex
    if 'CommonUtilities' in content or 'ModuleIndex' in content:
        return
    
    # Add import after the header comment
    import_block = '''
# Import CommonUtilities for status messaging
$originalVerbosePreference = $VerbosePreference
$VerbosePreference = 'SilentlyContinue'
Import-Module "$PSScriptRoot\\CommonUtilities.psm1" -Force -WarningAction SilentlyContinue -Verbose:$false
$VerbosePreference = $originalVerbosePreference

'''
    
    # Find the end of the header comment block
    match = re.search(r'^#>\s*$', content, re.MULTILINE)
    if match:
        insert_pos = match.end()
        content = content[:insert_pos] + '\n' + import_block + content[insert_pos:]
        
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"  {filepath.name}: Added CommonUtilities import")

def main():
    print("=" * 70)
    print("Write-Host Replacement Script")
    print("=" * 70)
    print()
    
    total_replacements = 0
    
    for filename in FILES_TO_PROCESS:
        filepath = MODULES_DIR / filename
        if not filepath.exists():
            print(f"✗ {filename}: File not found")
            continue
        
        count = replace_write_host_in_file(filepath)
        if count > 0:
            ensure_commonutilities_import(filepath)
        total_replacements += count
    
    print()
    print("=" * 70)
    print(f"Total replacements: {total_replacements}")
    print("=" * 70)

if __name__ == "__main__":
    main()
