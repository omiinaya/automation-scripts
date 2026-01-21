#!/usr/bin/env python3
"""
Quick test of the extraction script with limited page range.
"""
import sys
sys.path.insert(0, 'helpers')

from cis_robust_extractor import CISRobustExtractor

def test():
    pdf_path = "../docs/CIS_Microsoft_Windows_11_Stand-alone_Benchmark_v4.0.0.pdf"
    output_dir = "docs/json_test_quick"
    
    # Create extractor with custom page range
    class QuickExtractor(CISRobustExtractor):
        START_PAGE = 39
        END_PAGE = 45  # Only 6 pages
    
    extractor = QuickExtractor(pdf_path, output_dir)
    
    # Extract text
    pages = extractor.extract_text_from_pdf()
    print(f"Extracted {len(pages)} pages")
    
    # Find first recommendation
    start_idx = extractor.find_next_recommendation(0)
    if start_idx is None:
        print("No recommendations found in range")
        return
    
    # Extract first recommendation block
    block_data, next_start = extractor.extract_recommendation_block(start_idx)
    print(f"Found recommendation: {block_data['cis_id']} - {block_data['title']}")
    
    # Parse sections
    sections = extractor.parse_sections(block_data)
    print(f"Sections extracted: {list(sections.keys())}")
    
    # Convert to recommendation object
    rec = extractor.extract_recommendation(block_data)
    if rec:
        print(f"Successfully extracted recommendation {rec.cis_id}")
    
    print("Test passed.")

if __name__ == "__main__":
    test()