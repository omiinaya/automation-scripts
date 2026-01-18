#!/usr/bin/env python3
"""
Examine specific pages to understand complex title patterns
"""

import pdfplumber
import re


def examine_page(page_num):
    """Examine a specific page for title patterns"""
    pdf_path = "docs/CIS_Microsoft_Windows_11_Stand-alone_Benchmark_v4.0.0.pdf"
    
    with pdfplumber.open(pdf_path) as pdf:
        if page_num > len(pdf.pages):
            print(f"Page {page_num} does not exist")
            return
            
        page = pdf.pages[page_num - 1]
        text = page.extract_text()
        
        print(f"\n=== PAGE {page_num} FULL TEXT ===")
        print(text)
        
        # Look for CIS ID patterns
        cis_pattern = r'(\d+\.\d+(?:\.\d+)*)\s+\((L1|L2|BL)\)'
        matches = re.findall(cis_pattern, text)
        
        if matches:
            print("\nCIS IDs found:")
            for cis_id, profile in matches:
                print(f"  - {cis_id} ({profile})")
                
                # Extract the full title
                title_pattern = f'{re.escape(cis_id)}\s+\\({re.escape(profile)}\\)\s+(.+?)\\((Automated|Manual)\\)'
                title_match = re.search(title_pattern, text, re.DOTALL)
                if title_match:
                    title = title_match.group(3)
                    print(f"    Full title: {title}")
                    
                    # Check if it starts with Ensure/Configure or other action words
                    action_pattern = r'^(Ensure|Configure|Disable|Enable|Turn off|Turn on)'
                    action_match = re.search(action_pattern, title)
                    if action_match:
                        print(f"    Action word: {action_match.group(1)}")
                    else:
                        print("    Action word: None (complex pattern)")


if __name__ == "__main__":
    # Examine pages where section 18.6.x recommendations are found
    pages = [540, 542, 544, 546, 548, 551, 553, 555, 557, 559, 561, 563, 566, 568, 571, 574, 576, 580]
    for page_num in pages:
        examine_page(page_num)