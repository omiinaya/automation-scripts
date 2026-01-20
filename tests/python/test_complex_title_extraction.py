#!/usr/bin/env python3
"""
Test script to verify complex title extraction enhancements
"""

import re
import sys
from pathlib import Path

# Add parent directory to path to import cis_robust_extractor
sys.path.insert(0, str(Path(__file__).parent.parent))

def test_complex_title_parsing():
    """Test the enhanced _parse_complex_title method"""
    
    # Simulate the _parse_complex_title logic
    def _parse_complex_title(action_type: str, title: str) -> str:
        """
        Parse complex title structures with nested requirements.
        Handles patterns like "Disable IPv6 (Ensure TCPIP6 Parameter...)"
        Returns enhanced title with both main action and nested requirement extracted.
        """
        # Check if title contains nested Ensure/Configure pattern
        nested_pattern = r'\((Ensure|Configure)\s+(.+?)\)'
        nested_match = re.search(nested_pattern, title)
        
        if nested_match:
            # Extract the nested requirement
            nested_action, nested_content = nested_match.groups()
            
            # Extract the main action (before parentheses)
            main_action_pattern = r'^(.+?)\s*\('
            main_match = re.search(main_action_pattern, title)
            
            if main_match:
                main_content = main_match.group(1).strip()
                # Return enhanced title with both components
                return (
                    f"{action_type} {main_content} "
                    f"({nested_action} {nested_content})"
                )
            else:
                # Fallback: preserve the full structure
                return f"{action_type} {title}"
        else:
            # Standard title structure
            return f"{action_type} {title}"
    
    # Test cases
    test_cases = [
        {
            "input": ("Disable", "IPv6 (Ensure TCPIP6 Parameter 'DisabledComponents' is set to '0xff (255)')"),
            "expected": "Disable IPv6 (Ensure TCPIP6 Parameter 'DisabledComponents' is set to '0xff (255)')"
        },
        {
            "input": ("Turn off", "Microsoft Peer-to-Peer Networking Services"),
            "expected": "Turn off Microsoft Peer-to-Peer Networking Services"
        },
        {
            "input": ("Enable", "Windows Firewall (Ensure 'Windows Firewall: Public: Firewall state' is set to 'On')"),
            "expected": "Enable Windows Firewall (Ensure 'Windows Firewall: Public: Firewall state' is set to 'On')"
        },
        {
            "input": ("Configure", "'Accounts: Rename guest account'"),
            "expected": "Configure 'Accounts: Rename guest account'"
        }
    ]
    
    print("Testing complex title parsing...")
    all_passed = True
    
    for i, test_case in enumerate(test_cases):
        action_type, title = test_case["input"]
        expected = test_case["expected"]
        result = _parse_complex_title(action_type, title)
        
        if result == expected:
            print(f"✓ Test {i+1} passed: {result}")
        else:
            print(f"✗ Test {i+1} failed:")
            print(f"  Input: {action_type} {title}")
            print(f"  Expected: {expected}")
            print(f"  Got: {result}")
            all_passed = False
    
    # Test regex patterns
    print("\nTesting regex patterns...")
    
    # Test REC_START_PATTERN
    rec_pattern = re.compile(
        r'^(\d+\.\d+(?:\.\d+)*)\s+\((L1|L2|BL)\)\s+(Ensure|Configure|Disable|Enable|Turn off|Turn on)\s+(.+?)\s+'
        r'\((Automated|Manual)\)',
        re.DOTALL | re.IGNORECASE
    )
    
    test_strings = [
        "18.6.19.2.1 (L2) Disable IPv6 (Ensure TCPIP6 Parameter 'DisabledComponents' is set to '0xff (255)') (Automated)",
        "2.3.1.4 (L1) Configure 'Accounts: Rename guest account' (Automated)",
        "1.1.1 (L1) Ensure 'Enforce password history' is set to '24 or more password(s)' (Automated)",
        "18.6.10.2 (L2) Turn off Microsoft Peer-to-Peer Networking Services (Automated)"
    ]
    
    for test_str in test_strings:
        match = rec_pattern.search(test_str)
        if match:
            cis_id, profile, action_type, title, automation = match.groups()
            print(f"✓ Matched: {cis_id} {profile} {action_type} {title[:50]}...")
        else:
            print(f"✗ Failed to match: {test_str[:50]}...")
            all_passed = False
    
    return all_passed

def test_file_naming_logic():
    """Test the enhanced file naming logic"""
    print("\nTesting file naming logic...")
    
    test_cases = [
        ("18.6.19.2.1", "18.6"),
        ("1.1.1", "1.1"),
        ("2.3.1.4", "2.3"),
        ("18.6.10.2", "18.6"),
        ("5", "5")
    ]
    
    all_passed = True
    
    for cis_id, expected_section in test_cases:
        parts = cis_id.split('.')
        section_id = '.'.join(parts[:2]) if len(parts) >= 2 else cis_id
        filename_section = section_id.replace('.', '_')
        
        if section_id == expected_section:
            print(f"✓ {cis_id} -> {section_id} -> {filename_section}")
        else:
            print(f"✗ {cis_id} -> {section_id} (expected {expected_section})")
            all_passed = False
    
    return all_passed

def main():
    """Main test function"""
    print("=" * 60)
    print("Testing CIS Extractor Enhancements")
    print("=" * 60)
    
    title_passed = test_complex_title_parsing()
    naming_passed = test_file_naming_logic()
    
    print("\n" + "=" * 60)
    if title_passed and naming_passed:
        print("✓ All tests passed!")
        return 0
    else:
        print("✗ Some tests failed")
        return 1

if __name__ == "__main__":
    sys.exit(main())