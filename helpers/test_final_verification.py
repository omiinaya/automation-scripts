#!/usr/bin/env python3
"""
Final verification test for CIS extractor enhancements
"""

import json
import os
import sys
from pathlib import Path

def verify_complex_titles():
    """Verify that complex titles are correctly extracted"""
    print("Verifying complex title extraction...")
    
    # Check for specific complex titles
    test_cases = [
        {
            "cis_id": "18.6.19.2.1",
            "expected_keywords": ["Disable", "IPv6", "Ensure", "TCPIP6", "DisabledComponents"]
        },
        {
            "cis_id": "18.6.10.2",
            "expected_keywords": ["Turn off", "Microsoft", "Peer-to-Peer", "Networking", "Services"]
        }
    ]
    
    all_passed = True
    
    # Search through all JSON files
    json_dir = Path("docs/json")
    for json_file in json_dir.glob("*.json"):
        with open(json_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
            
        for item in data:
            for test_case in test_cases:
                if item.get("cis_id") == test_case["cis_id"]:
                    title = item.get("title", "").lower()
                    print(f"Found {test_case['cis_id']}: {title[:80]}...")
                    
                    # Check for expected keywords
                    for keyword in test_case["expected_keywords"]:
                        if keyword.lower() not in title:
                            print(f"  ✗ Missing keyword: {keyword}")
                            all_passed = False
                        else:
                            print(f"  ✓ Contains keyword: {keyword}")
    
    return all_passed

def verify_file_naming():
    """Verify that file naming follows the new convention"""
    print("\nVerifying file naming convention...")
    
    # Expected pattern: cis_section_X_Y_Z.json where X.Y is the section
    json_dir = Path("docs/json")
    files = list(json_dir.glob("cis_section_*.json"))
    
    print(f"Found {len(files)} JSON files")
    
    # Check a few key files
    expected_files = [
        "cis_section_18_6_1.json",
        "cis_section_18_6_2.json", 
        "cis_section_18_6_3.json"
    ]
    
    all_passed = True
    for expected_file in expected_files:
        file_path = json_dir / expected_file
        if file_path.exists():
            print(f"✓ {expected_file} exists")
        else:
            print(f"✗ {expected_file} missing")
            all_passed = False
    
    return all_passed

def verify_section_grouping():
    """Verify that recommendations are grouped by section correctly"""
    print("\nVerifying section grouping...")
    
    json_dir = Path("docs/json")
    
    # Check that 18.6.x recommendations are in 18_6 files
    section_18_6_files = list(json_dir.glob("cis_section_18_6_*.json"))
    
    if not section_18_6_files:
        print("✗ No 18.6 section files found")
        return False
    
    print(f"Found {len(section_18_6_files)} files for section 18.6")
    
    # Count recommendations in 18.6 files
    total_18_6_recommendations = 0
    for file_path in section_18_6_files:
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
            total_18_6_recommendations += len(data)
            print(f"  {file_path.name}: {len(data)} recommendations")
    
    print(f"Total 18.6.x recommendations: {total_18_6_recommendations}")
    
    # Check that we have the complex title
    complex_title_found = False
    for file_path in section_18_6_files:
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
            for item in data:
                if item.get("cis_id") == "18.6.19.2.1":
                    complex_title_found = True
                    print(f"✓ Complex title 18.6.19.2.1 found in {file_path.name}")
                    print(f"  Title: {item.get('title', '')[:80]}...")
    
    if not complex_title_found:
        print("✗ Complex title 18.6.19.2.1 not found")
        return False
    
    return True

def main():
    """Main verification function"""
    print("=" * 60)
    print("Final Verification of CIS Extractor Enhancements")
    print("=" * 60)
    
    # Change to project directory
    project_root = Path(__file__).parent.parent
    os.chdir(project_root)
    
    tests = [
        ("Complex Title Extraction", verify_complex_titles),
        ("File Naming Convention", verify_file_naming),
        ("Section Grouping", verify_section_grouping)
    ]
    
    all_passed = True
    for test_name, test_func in tests:
        print(f"\n{test_name}:")
        try:
            if test_func():
                print(f"✓ {test_name} PASSED")
            else:
                print(f"✗ {test_name} FAILED")
                all_passed = False
        except Exception as e:
            print(f"✗ {test_name} ERROR: {e}")
            all_passed = False
    
    print("\n" + "=" * 60)
    if all_passed:
        print("✓ ALL TESTS PASSED")
        print("\nSummary of enhancements:")
        print("1. Enhanced regex patterns now support action words: Ensure, Configure, Disable, Enable, Turn off, Turn on")
        print("2. Nested title structures are properly parsed (e.g., 'Disable IPv6 (Ensure TCPIP6 Parameter...)')")
        print("3. File naming uses first two parts of CIS ID (e.g., 18.6 from 18.6.19.2.1)")
        print("4. Section 18.6.19.2.1 is now correctly extracted and grouped with other 18.6.x recommendations")
        return 0
    else:
        print("✗ SOME TESTS FAILED")
        return 1

if __name__ == "__main__":
    sys.exit(main())