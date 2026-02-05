#!/usr/bin/env python3
"""
Removes local Wait-OnError functions from optimization scripts.
These functions are already provided by CommonUtilities module.
"""

import os
import re
from pathlib import Path

def find_wait_on_error_functions(content):
    """Find local Wait-OnError function definitions."""
    # Pattern to match the local Wait-OnError function with preceding comment
    pattern = r'^\s*#.*?(?:pause|wait|error).*?\nfunction Wait-OnError \{[^}]*\}'
    return re.findall(pattern, content, re.MULTILINE | re.DOTALL | re.IGNORECASE)

def remove_wait_on_error(content):
    """Remove local Wait-OnError function from content."""
    # Pattern to match from comment to end of function
    patterns = [
        # Pattern 1: With comment header
        r'^\s*#.*?Function to pause on error.*?\nfunction Wait-OnError \{[^}]*\}',
        # Pattern 2: Just the function
        r'^function Wait-OnError \{[^}]*\}',
        # Pattern 3: More flexible pattern
        r'^\s*#.*?\nfunction Wait-OnError \{[\s\S]*?^\}',
    ]
    
    new_content = content
    for pattern in patterns:
        new_content = re.sub(pattern, '', new_content, flags=re.MULTILINE | re.IGNORECASE | re.DOTALL)
    
    # Clean up extra blank lines at the start
    new_content = re.sub(r'^(\s*\n){2,}', '\n', new_content)
    
    return new_content.strip()

def process_file(file_path, what_if=True):
    """Process a single file."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Check if file has local Wait-OnError
        if 'function Wait-OnError' not in content:
            return None
        
        new_content = remove_wait_on_error(content)
        
        # Check if anything was removed
        if len(new_content) >= len(content) - 10:  # Allow small differences
            return None
        
        if not what_if:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(new_content)
        
        return True
    except Exception as e:
        return f"Error: {str(e)}"

def main():
    """Main function."""
    optimization_path = Path('/root/projects/automation-scripts/windows/optimization')
    
    if not optimization_path.exists():
        print("Error: Optimization path not found")
        return
    
    ps1_files = list(optimization_path.rglob('*.ps1'))
    print(f"Found {len(ps1_files)} PowerShell files in optimization directory")
    print()
    
    modified_count = 0
    errors = []
    
    for file_path in ps1_files:
        result = process_file(file_path, what_if=False)
        if result is True:
            print(f"Modified: {file_path}")
            modified_count += 1
        elif result and result.startswith("Error"):
            print(f"Error processing {file_path}: {result}")
            errors.append(f"{file_path}: {result}")
    
    print()
    print("=" * 50)
    print(f"Summary:")
    print(f"  Scripts modified: {modified_count}")
    print(f"  Errors: {len(errors)}")
    
    if errors:
        print()
        print("Errors encountered:")
        for error in errors:
            print(f"  - {error}")

if __name__ == "__main__":
    main()
