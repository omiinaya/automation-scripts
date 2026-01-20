#!/usr/bin/env python3
"""
Test script to examine complex title patterns in the CIS PDF
"""

import pdfplumber
import re


def examine_pages():
    """Examine specific pages for complex title patterns"""
    pdf_path = "docs/CIS_Microsoft_Windows_11_Stand-alone_Benchmark_v4.0.0.pdf"
    
    # Pages where complex titles might appear
    pages_to_check = [
        # Look for section 18.6.19.2.1 and similar patterns
        500, 550, 600, 650, 700
    ]
    
    with pdfplumber.open(pdf_path) as pdf:
        for page_num in pages_to_check:
            if page_num <= len(pdf.pages):
                page = pdf.pages[page_num - 1]
                text = page.extract_text()
                
                print(f"\n=== PAGE {page_num} ===")
                print("First 500 characters:")
                print(text[:500])
                
                # Look for CIS ID patterns
                cis_patterns = [
                    r'(\d+\.\d+(?:\.\d+)*)\s+',  # Standard CIS ID
                    r'(\d+\.\d+(?:\.\d+)*)\s+\((L1|L2|BL)\)',  # With profile
                ]
                
                for pattern in cis_patterns:
                    matches = re.findall(pattern, text)
                    if matches:
                        print(f"\nCIS IDs found with pattern '{pattern}':")
                        for match in matches[:5]:  # Show first 5 matches
                            print(f"  - {match}")
                
                # Look for complex title patterns
                complex_patterns = [
                    r'(Disable|Enable|Turn off|Turn on)\s+[^(]+\(Ensure',
                    r'(Disable|Enable|Turn off|Turn on)\s+[^(]+\(Configure',
                ]
                
                for pattern in complex_patterns:
                    matches = re.findall(pattern, text)
                    if matches:
                        print("\nComplex title patterns found:")
                        for match in matches[:5]:
                            print(f"  - {match}")


if __name__ == "__main__":
    examine_pages()