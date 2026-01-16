#!/usr/bin/env python3
"""
Search for specific section 18.6.19.2.1
"""

import pdfplumber
import re


def search_specific_section():
    """Search for section 18.6.19.2.1"""
    pdf_path = "docs/CIS_Microsoft_Windows_11_Stand-alone_Benchmark_v4.0.0.pdf"
    
    # Search through the entire PDF
    start_page = 39
    end_page = 1288
    
    target_section = "18.6.19.2.1"
    
    with pdfplumber.open(pdf_path) as pdf:
        for page_num in range(start_page, end_page + 1):
            if page_num > len(pdf.pages):
                break
                
            page = pdf.pages[page_num - 1]
            text = page.extract_text()
            
            # Look for the specific section
            if target_section in text:
                print(f"\n=== FOUND SECTION {target_section} ON PAGE {page_num} ===")
                
                # Extract the context around the section
                lines = text.split('\n')
                for i, line in enumerate(lines):
                    if target_section in line:
                        print(f"Line {i}: {line}")
                        # Show surrounding lines
                        start_idx = max(0, i-2)
                        end_idx = min(len(lines), i+3)
                        for j in range(start_idx, end_idx):
                            print(f"  {j}: {lines[j]}")
                        break
                
                # Extract the full title pattern
                title_pattern = f'{re.escape(target_section)}\s+\((L1|L2|BL)\)\s+(.+?)\((Automated|Manual)\)'
                title_match = re.search(title_pattern, text, re.DOTALL)
                if title_match:
                    profile = title_match.group(1)
                    title = title_match.group(2)
                    automation = title_match.group(3)
                    print("\nFull title pattern:")
                    print(f"  CIS ID: {target_section}")
                    print(f"  Profile: {profile}")
                    print(f"  Title: {title}")
                    print(f"  Automation: {automation}")
                    
                    # Check action word
                    action_pattern = r'^(Ensure|Configure|Disable|Enable|Turn off|Turn on)'
                    action_match = re.search(action_pattern, title)
                    if action_match:
                        print(f"  Action word: {action_match.group(1)}")
                    else:
                        print("  Action word: Complex pattern")


if __name__ == "__main__":
    search_specific_section()