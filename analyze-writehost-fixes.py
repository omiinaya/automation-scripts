#!/usr/bin/env python3
"""
Fix Write-Host code smells by replacing with Write-Output where appropriate

Strategy:
1. Keep Write-Host in user-facing scripts (windows/, verify-optimization-changes.ps1)
2. Keep Write-Host in WindowsUI.psm1 (it's a UI module)
3. Replace simple Write-Host calls in other modules with Write-Output
"""
import json
import re
import sys
from pathlib import Path

with open('powershell-code-smells.json') as f:
    data = json.load(f)

writehost_finds = [
    f for f in data.get('results', [])
    if f['check_id'] == 'powershell-write-host'
]

# Filter for fixable cases:
# 1. Exclude user-facing scripts
# 2. Exclude WindowsUI.psm1
# 3. Include only modules with simple Write-Host calls (no -ForegroundColor, -NoNewline)

fixable_writes = []
for f in writehost_finds:
    path = f['path']

    if path.startswith('windows/'):
        continue  # User-facing scripts - keep Write-Host
    if path == 'verify-optimization-changes.ps1':
        continue  # Verification script - keep Write-Host
    if 'WindowsUI.psm1' in path:
        continue  # UI module - keep Write-Host

    code = f['extra'].get('lines', '').strip()

    # Check if it's a simple Write-Host (no formatting params)
    if '-ForegroundColor' in code or '-NoNewline' in code or '-BackgroundColor' in code:
        continue  # Formatting needed - keep Write-Host

    fixable_writes.append(f)

print(f"Analysis:")
print(f"Total Write-Host occurrences: {len(writehost_finds)}")
print(f"Fixable (simple calls in modules): {len(fixable_writes)}")
print(f"Not fixable (user-facing or formatted): {len(writehost_finds) - len(fixable_writes)}")
print()

if len(fixable_writes) == 0:
    print("No fixable Write-Host calls found.")
    print("\nAll Write-Host uses are:")
    print("  - In user-facing scripts (appropriate for colored interactive output)")
    print("  - In WindowsUI module (appropriate for UI display)")
    print("  - Using color/formatting parameters")
    sys.exit(0)

print("Fixable Write-Host calls:")
print("=" * 80)
for f in fixable_writes[:20]:
    print(f"\n{f['path']}:{f['start']['line']}")
    print(f"  {f['extra'].get('lines', '').strip()}")

if len(fixable_writes) > 20:
    print(f"\n... and {len(fixable_writes) - 20} more")
