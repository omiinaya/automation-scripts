#!/usr/bin/env python3
"""
Script to analyze gaps between extracted CIS sections and existing
audit/remediation scripts.
"""

import json
import re
from pathlib import Path
from typing import Set


def extract_cis_ids_from_json(json_dir: str) -> Set[str]:
    """Extract all unique CIS IDs from JSON files."""
    cis_ids = set()
    json_dir_path = Path(json_dir)
    
    for json_file in json_dir_path.glob("cis_section_*.json"):
        try:
            with open(json_file, 'r', encoding='utf-8') as f:
                data = json.load(f)
                for item in data:
                    if 'cis_id' in item:
                        cis_ids.add(item['cis_id'])
        except (json.JSONDecodeError, KeyError) as e:
            print(f"Error reading {json_file}: {e}")
    
    return cis_ids


def extract_existing_scripts(scripts_dir: str, script_type: str) -> Set[str]:
    """Extract CIS IDs from existing script filenames."""
    script_ids = set()
    scripts_dir_path = Path(scripts_dir)
    
    # Pattern: {cis_id}-{audit|remediate}-*.ps1
    # Also handle nested section directories
    for ps1_file in scripts_dir_path.rglob("*.ps1"):
        filename = ps1_file.name
        # Extract CIS ID from filename
        # Examples: "1.1.1-audit-password-history.ps1"
        match = re.match(r'^([\d\.]+)-(audit|remediate)-', filename)
        if match:
            cis_id = match.group(1)
            script_ids.add(cis_id)
    
    return script_ids


def normalize_cis_id(cis_id: str) -> str:
    """Normalize CIS ID for comparison (remove trailing zeros if needed)."""
    # Keep as is for now
    return cis_id


def analyze_gaps():
    """Main analysis function."""
    base_dir = Path.cwd()
    json_dir = base_dir / "docs" / "json"
    audit_dir = base_dir / "windows" / "security" / "audits"
    remediation_dir = base_dir / "windows" / "security" / "remediations"
    
    print("Extracting CIS IDs from JSON files...")
    json_cis_ids = extract_cis_ids_from_json(json_dir)
    print(f"Found {len(json_cis_ids)} unique CIS IDs in JSON files")
    
    print("\nExtracting existing audit scripts...")
    audit_cis_ids = extract_existing_scripts(audit_dir, "audit")
    print(f"Found {len(audit_cis_ids)} CIS IDs with audit scripts")
    
    print("\nExtracting existing remediation scripts...")
    remediation_cis_ids = extract_existing_scripts(remediation_dir, "remediate")
    print(f"Found {len(remediation_cis_ids)} CIS IDs with remediation scripts")
    
    # Find missing audit scripts
    missing_audit = sorted(json_cis_ids - audit_cis_ids)
    # Find missing remediation scripts
    missing_remediation = sorted(json_cis_ids - remediation_cis_ids)
    
    print(f"\n{'='*60}")
    print("GAP ANALYSIS RESULTS")
    print(f"{'='*60}")
    print(f"\nTotal CIS sections extracted: {len(json_cis_ids)}")
    print(f"CIS sections with audit scripts: {len(audit_cis_ids)}")
    print(f"CIS sections with remediation scripts: {len(remediation_cis_ids)}")
    print(f"\nMissing audit scripts: {len(missing_audit)}")
    print(f"Missing remediation scripts: {len(missing_remediation)}")
    
    # Group missing sections by major section
    def get_major_section(cis_id: str) -> str:
        parts = cis_id.split('.')
        return parts[0] if len(parts) > 0 else "0"
    
    missing_audit_by_section = {}
    missing_remediation_by_section = {}
    
    for cis_id in missing_audit:
        major = get_major_section(cis_id)
        missing_audit_by_section.setdefault(major, []).append(cis_id)
    
    for cis_id in missing_remediation:
        major = get_major_section(cis_id)
        missing_remediation_by_section.setdefault(major, []).append(cis_id)
    
    print("\nMissing Audit Scripts by Section:")
    for major in sorted(missing_audit_by_section.keys()):
        count = len(missing_audit_by_section[major])
        print(f"  Section {major}: {count} missing")
    
    print("\nMissing Remediation Scripts by Section:")
    for major in sorted(missing_remediation_by_section.keys()):
        count = len(missing_remediation_by_section[major])
        print(f"  Section {major}: {count} missing")
    
    # Write detailed reports
    with open("missing_audit_report.txt", "w") as f:
        f.write("Missing Audit Scripts Report\n")
        f.write("=" * 40 + "\n")
        f.write(f"Total missing: {len(missing_audit)}\n\n")
        for cis_id in sorted(missing_audit):
            f.write(f"{cis_id}\n")
    
    with open("missing_remediation_report.txt", "w") as f:
        f.write("Missing Remediation Scripts Report\n")
        f.write("=" * 40 + "\n")
        f.write(f"Total missing: {len(missing_remediation)}\n\n")
        for cis_id in sorted(missing_remediation):
            f.write(f"{cis_id}\n")
    
    # Also write combined report
    with open("gap_analysis_summary.txt", "w") as f:
        f.write("CIS Script Gap Analysis Summary\n")
        f.write("=" * 40 + "\n")
        f.write(f"Total CIS sections extracted: {len(json_cis_ids)}\n")
        f.write(f"CIS sections with audit scripts: {len(audit_cis_ids)}\n")
        f.write(f"CIS sections with remediation scripts: "
                f"{len(remediation_cis_ids)}\n")
        f.write(f"Missing audit scripts: {len(missing_audit)}\n")
        f.write(f"Missing remediation scripts: {len(missing_remediation)}\n\n")
        
        f.write("\nMissing Audit Scripts:\n")
        f.write("-" * 20 + "\n")
        for cis_id in sorted(missing_audit):
            f.write(f"{cis_id}\n")
        
        f.write("\nMissing Remediation Scripts:\n")
        f.write("-" * 20 + "\n")
        for cis_id in sorted(missing_remediation):
            f.write(f"{cis_id}\n")
    
    print("\nDetailed reports written to:")
    print("  - missing_audit_report.txt")
    print("  - missing_remediation_report.txt")
    print("  - gap_analysis_summary.txt")
    
    return json_cis_ids, missing_audit, missing_remediation


if __name__ == "__main__":
    analyze_gaps()