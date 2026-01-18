#!/usr/bin/env python3
"""
Find missing sections with complex title patterns
"""

import pdfplumber
import re


def find_complex_titles():
    """Search for complex title patterns in the PDF"""
    pdf_path = "docs/CIS_Microsoft_Windows_11_Stand-alone_Benchmark_v4.0.0.pdf"
    
    # Search range for section 18.6
    start_page = 540
    end_page = 580
    
    complex_patterns = [
        # Pattern for "Disable IPv6 (Ensure TCPIP6 Parameter...)"
        r'(\d+\.\d+(?:\.\d+)*)\s+\((L1|L2|BL)\)\s+(Disable|Enable|Turn off|Turn on)\s+([^(]+)\(Ensure',
        # Pattern for "Turn off Microsoft Peer-to-Peer Networking Services"
        r'(\d+\.\d+(?:\.\d+)*)\s+\((L1|L2|BL)\)\s+(Disable|Enable|Turn off|Turn on)\s+([^(]+)\((Automated|Manual)\)',
    ]
    
    found_matches = []
    
    with pdfplumber.open(pdf_path) as pdf:
        for page_num in range(start_page, end_page + 1):
            if page_num > len(pdf.pages):
                break
                
            page = pdf.pages[page_num - 1]
            text = page.extract_text()
            
            # Look for CIS IDs starting with 18.6
            cis_pattern = r'(18\.6\.\d+(?:\.\d+)*)\s+\((L1|L2|BL)\)'
            cis_matches = re.findall(cis_pattern, text)
            
            if cis_matches:
                print(f"\n=== PAGE {page_num} - CIS IDs found ===")
                for cis_id, profile in cis_matches:
                    print(f"  - {cis_id} ({profile})")
                    
                    # Extract the title that follows
                    title_pattern = f'{re.escape(cis_id)}\s+\\({re.escape(profile)}\\)\s+(.+?)\\((Automated|Manual)\\)'
                    title_match = re.search(title_pattern, text)
                    if title_match:
                        title = title_match.group(3)
                        print(f"    Title: {title}")
            
            # Look for complex patterns
            for pattern in complex_patterns:
                matches = re.findall(pattern, text)
                if matches:
                    for match in matches:
                        cis_id, profile, action, title_part, _ = match
                        print(f"\nComplex pattern found on page {page_num}:")
                        print(f"  CIS ID: {cis_id}")
                        print(f"  Profile: {profile}")
                        print(f"  Action: {action}")
                        print(f"  Title: {title_part}")
                        found_matches.append({
                            'page': page_num,
                            'cis_id': cis_id,
                            'profile': profile,
                            'action': action,
                            'title': title_part
                        })
    
    return found_matches


if __name__ == "__main__":
    matches = find_complex_titles()
    print("\n=== SUMMARY ===")
    print(f"Found {len(matches)} complex title patterns")
    for match in matches:
        print(f"Page {match['page']}: {match['cis_id']} - {match['action']} {match['title']}")