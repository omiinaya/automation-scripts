#!/usr/bin/env python3

import re

# Read the script content
with open('windows/security/remediations/1.2.1-remediate-account-lockout-duration.ps1', 'r') as f:
    content = f.read()

print("=== Debug Import Pattern ===")
print("Looking for pattern: 'Import-Module.*ModuleIndex'")

# Search for the pattern
pattern = r'Import-Module.*ModuleIndex'
matches = re.findall(pattern, content, re.MULTILINE | re.IGNORECASE)

print(f"Matches found: {len(matches)}")
for match in matches:
    print(f"Match: '{match}'")

# Also check for the exact line
import_lines = [line for line in content.split('\n') if 'Import-Module' in line]
print("\nImport lines found:")
for line in import_lines:
    print(f"'{line}'")