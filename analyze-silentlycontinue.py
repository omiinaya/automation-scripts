#!/usr/bin/env python3
"""
Analyze and categorize ErrorAction SilentlyContinue occurrences
"""
import json
from collections import defaultdict

with open('powershell-code-smells.json') as f:
    data = json.load(f)

silentlycontinue_finds = [
    f for f in data.get('results', [])
    if f['check_id'] == 'powershell-erroraction-silentlycontinue'
]

# Group by type of operation
operations = defaultdict(list)
for finding in silentlycontinue_finds:
    path = finding['path']
    line = finding['start']['line']
    code = finding['extra'].get('lines', '').strip()

    # Categorize by command type
    if 'Get-Module' in code:
        operations['Get-Module'].append((path, line, code))
    elif 'Remove-Item' in code:
        operations['Remove-Item'].append((path, line, code))
    elif 'Get-Service' in code:
        operations['Get-Service'].append((path, line, code))
    elif 'Get-Process' in code:
        operations['Get-Process'].append((path, line, code))
    elif 'Get-ItemProperty' in code:
        operations['Get-ItemProperty'].append((path, line, code))
    else:
        operations['Other'].append((path, line, code))

print("ErrorAction SilentlyContinue Analysis:")
print("=" * 80)
for op_type, findings in sorted(operations.items()):
    print(f"\n{op_type} ({len(findings)} occurrences):")
    print("-" * 40)
    for path, line, code in findings[:5]:  # Show first 5 of each type
        print(f"  {path}:{line}")
        print(f"    {code[:80]}")
    if len(findings) > 5:
        print(f"  ... and {len(findings) - 5} more")

print("\n\nTotal: " + str(len(silentlycontinue_finds)) + " occurrences")
