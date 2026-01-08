#!/usr/bin/env python3
"""
Robust CIS Microsoft Windows 11 Benchmark Extractor

This script extracts audit and remediation procedures from the CIS Microsoft
Windows 11 benchmark PDF using a robust state-machine approach that directly
parses the PDF content without relying on error-prone TOC extraction.

Key improvements:
- Ignores pages outside remediation range (39-1288)
- Sequential scanning for recommendation start patterns
- State machine to parse sections using known headings
- Handles multi-page recommendations with continuation detection
- Outputs structured JSON with all expected fields
"""

import pdfplumber
import re
import json
import logging
from pathlib import Path
from dataclasses import dataclass, asdict, field
from typing import List, Optional, Dict, Tuple, Any


@dataclass
class CISRecommendation:
    """Data class representing a CIS recommendation"""
    cis_id: str
    title: str
    profile: str
    assessment_status: str
    description: str
    rationale: str
    impact: str
    audit_procedure: str
    remediation_procedure: str
    default_value: str = ""
    page_number: int = 0


class CISRobustExtractor:
    """Robust extractor that processes PDF sequentially"""
    
    # Page range for remediation sections (1-indexed)
    START_PAGE = 39
    END_PAGE = 1288
    
    # Section headers (as they appear in PDF)
    SECTION_HEADERS = [
        "Profile Applicability:",
        "Description:",
        "Rationale:",
        "Impact:",
        "Audit:",
        "Remediation:",
        "Default Value:"
    ]
    
    # Regex pattern for recommendation start
    # Matches: "1.1.1 (L1) Ensure 'Enforce password history' is set to
    # '24 or more password(s)' (Automated)"
    REC_START_PATTERN = re.compile(
        r'^(\d+\.\d+(?:\.\d+)*)\s+\((L1|L2|BL)\)\s+(Ensure\s+.+?)\s+'
        r'\((Automated|Manual)\)',
        re.DOTALL | re.IGNORECASE
    )
    
    # Fallback pattern for variations
    REC_START_FALLBACK = re.compile(
        r'^(\d+\.\d+(?:\.\d+)*)\s+(Ensure\s+.+?)\s+\((Automated|Manual)\)',
        re.DOTALL | re.IGNORECASE
    )
    
    def __init__(self, pdf_path: str, output_dir: str = "docs/json"):
        self.pdf_path = pdf_path
        self.output_dir = output_dir
        self.recommendations: List[CISRecommendation] = []
        self.pages_text: List[Dict] = []  # List of dicts with page_number and text
        
        # Create output directory
        Path(output_dir).mkdir(parents=True, exist_ok=True)
        
        # Setup logging
        self.setup_logging()
    
    def setup_logging(self):
        """Setup logging configuration"""
        # Disable pdfminer debug logging (it's extremely verbose)
        logging.getLogger('pdfminer').setLevel(logging.WARNING)
        logging.getLogger('pdfplumber').setLevel(logging.WARNING)
        
        # Configure our own logger
        self.logger = logging.getLogger(__name__)
        self.logger.setLevel(logging.INFO)
        
        # Remove any existing handlers
        self.logger.handlers.clear()
        
        # File handler only (no console)
        file_handler = logging.FileHandler('cis_extraction_robust.log')
        file_handler.setLevel(logging.INFO)
        formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
        file_handler.setFormatter(formatter)
        self.logger.addHandler(file_handler)
        
        # Ensure no propagation to root logger (to avoid console output)
        self.logger.propagate = False
    
    def extract_text_from_pdf(self) -> List[Dict]:
        """Extract text from PDF within the remediation range"""
        self.logger.info(f"Extracting text from PDF: {self.pdf_path}")
        
        try:
            pages_data = []
            with pdfplumber.open(self.pdf_path) as pdf:
                for page_num in range(1, len(pdf.pages) + 1):
                    # Skip pages outside remediation range
                    if page_num < self.START_PAGE or page_num > self.END_PAGE:
                        continue
                    
                    page = pdf.pages[page_num - 1]
                    text = page.extract_text()
                    if text:
                        pages_data.append({
                            'page_number': page_num,
                            'text': text,
                            'lines': text.split('\n')
                        })
                    else:
                        pages_data.append({
                            'page_number': page_num,
                            'text': '',
                            'lines': []
                        })
            
            self.pages_text = pages_data
            self.logger.info(
                f"Successfully extracted text from {len(pages_data)} pages "
                f"(range {self.START_PAGE}-{self.END_PAGE})"
            )
            return pages_data
        except Exception as e:
            self.logger.error(f"Error extracting PDF text: {e}")
            raise
    
    def is_recommendation_start(
        self, text: str
    ) -> Optional[Tuple[str, str, str, str]]:
        """
        Check if text starts with a recommendation pattern.
        Returns tuple (cis_id, profile, title, assessment_status) if match,
        else None.
        """
        # Try primary pattern
        match = self.REC_START_PATTERN.search(text)
        if match:
            cis_id, profile, title, assessment_status = match.groups()
            return cis_id, profile, title, assessment_status
        
        # Try fallback pattern (missing profile)
        match = self.REC_START_FALLBACK.search(text)
        if match:
            cis_id, title, assessment_status = match.groups()
            return cis_id, "L1", title, assessment_status
        
        return None
    
    def find_next_recommendation(self, start_index: int) -> Optional[int]:
        """
        Find the next page index (in self.pages_text) that contains a
        recommendation start. Returns index or None if no more recommendations.
        """
        for i in range(start_index, len(self.pages_text)):
            page_data = self.pages_text[i]
            if self.is_recommendation_start(page_data['text']):
                return i
        return None
    
    def extract_recommendation_block(
        self, start_index: int
    ) -> Tuple[Dict[str, Any], Optional[int]]:
        """
        Extract a recommendation block starting at page index start_index.
        Returns (block_data, next_start_index) where block_data contains:
        - cis_id, profile, title, assessment_status
        - pages: list of page numbers
        - full_text: concatenated text
        - start_page: starting page number
        """
        start_page_data = self.pages_text[start_index]
        start_page_num = start_page_data['page_number']
        
        # Parse the recommendation header
        rec_info = self.is_recommendation_start(start_page_data['text'])
        if not rec_info:
            raise ValueError(
                f"Page {start_page_num} does not start with a recommendation"
            )
        
        cis_id, profile, title, assessment_status = rec_info
        
        # Collect pages until next recommendation start
        pages = [start_page_num]
        full_text = start_page_data['text']
        
        # Look ahead up to 10 pages for continuation (some recommendations span many pages)
        max_lookahead = 10
        for offset in range(1, max_lookahead + 1):
            next_idx = start_index + offset
            if next_idx >= len(self.pages_text):
                break
            
            next_page_data = self.pages_text[next_idx]
            next_page_num = next_page_data['page_number']
            next_text = next_page_data['text']
            
            # Check if this page starts a new recommendation
            if self.is_recommendation_start(next_text):
                break
            
            # Check if this page contains a CIS ID that might be a reference
            # (like "5.2"). If it's a reference, we should still include it as
            # part of the current recommendation unless it's clearly a new
            # recommendation start. We'll use a heuristic: if the page contains
            # section headers (Audit, Remediation, etc.) it's likely still part
            # of the current recommendation.
            cis_id_pattern = r'^\s*(\d+\.\d+(?:\.\d+)*)\s+'
            cis_match = re.search(cis_id_pattern, next_text, re.MULTILINE)
            if cis_match and cis_match.group(1) != cis_id:
                # If the page contains section headers (Audit, Remediation, etc.)
                # it's likely still part of the current recommendation
                # (e.g., CIS Controls section)
                section_headers = ["Audit:", "Remediation:", "Default Value:", "CIS Controls:"]
                header_found = any(header in next_text for header in section_headers)
                if not header_found:
                    # Could be a new recommendation without "Ensure"? Unlikely, but we'll break
                    # to avoid merging unrelated content.
                    self.logger.warning(
                        f"Page {next_page_num} contains CIS ID {cis_match.group(1)} "
                        f"but no section headers; breaking continuation."
                    )
                    break
                else:
                    # Still part of current recommendation, do not break
                    self.logger.debug(
                        f"Page {next_page_num} contains CIS ID {cis_match.group(1)} "
                        f"but also section headers -> continuing."
                    )
            
            # Add the page to the block
            pages.append(next_page_num)
            full_text += "\n" + next_text
        
        block_data = {
            'cis_id': cis_id,
            'profile': profile,
            'title': title,
            'assessment_status': assessment_status,
            'pages': pages,
            'full_text': full_text,
            'start_page': start_page_num
        }
        
        # Find next recommendation start for return
        next_start = self.find_next_recommendation(start_index + 1)
        return block_data, next_start
    
    def parse_sections(self, block_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Parse sections from the recommendation block text using a robust
        line-by-line parser that detects section headers.
        Returns dict with extracted fields.
        """
        text = block_data['full_text']
        sections: Dict[str, Any] = {
            'description': '',
            'rationale': '',
            'impact': '',
            'audit': '',
            'remediation': '',
            'default_value': ''
        }
        
        # Map header variations to section keys
        header_map = {
            'description': ['Description:'],
            'rationale': ['Rationale:'],
            'impact': ['Impact:'],
            'audit': ['Audit:'],
            'remediation': ['Remediation:'],
            'default_value': ['Default Value:']
        }
        
        # Normalize newlines and split into lines
        lines = text.split('\n')
        current_section = None
        current_content = []
        
        for line in lines:
            line_stripped = line.strip()
            
            # Check if line contains a section header
            found = False
            for section_key, headers in header_map.items():
                for header in headers:
                    if line_stripped.startswith(header):
                        # Save previous section content
                        if current_section is not None:
                            content = '\n'.join(current_content).strip()
                            sections[current_section] = content
                        
                        # Start new section
                        current_section = section_key
                        # Remove header from line to capture inline content
                        remaining = line_stripped[len(header):].strip()
                        current_content = [remaining] if remaining else []
                        found = True
                        break
                if found:
                    break
            
            if not found and current_section is not None:
                # Continue accumulating content for current section
                current_content.append(line_stripped)
        
        # Save the last section
        if current_section is not None:
            content = '\n'.join(current_content).strip()
            sections[current_section] = content
        
        # Fallback: if regex detection missed something, try regex as backup
        # (only for sections that are still empty)
        if not sections['description'] or not sections['audit']:
            # Use regex patterns as fallback
            section_patterns = {
                'description': (
                    r'Description:\s*\n(.*?)(?=\n\s*(?:Rationale:|Impact:|Audit:|'
                    r'Remediation:|Default Value:|$))'
                ),
                'rationale': (
                    r'Rationale:\s*\n(.*?)(?=\n\s*(?:Impact:|Audit:|Remediation:|'
                    r'Default Value:|$))'
                ),
                'impact': (
                    r'Impact:\s*\n(.*?)(?=\n\s*(?:Audit:|Remediation:|Default '
                    r'Value:|$))'
                ),
                'audit': (
                    r'Audit:\s*\n(.*?)(?=\n\s*(?:Remediation:|Default Value:|$))'
                ),
                'remediation': (
                    r'Remediation:\s*\n(.*?)(?=\n\s*(?:Default Value:|$))'
                ),
                'default_value': (
                    r'Default Value:\s*\n(.*?)(?=\n\s*(?:References:|Additional Information:|$))'
                )
            }
            
            for section_name, pattern in section_patterns.items():
                if not sections[section_name]:
                    match = re.search(pattern, text, re.DOTALL | re.IGNORECASE)
                    if match:
                        content = match.group(1).strip()
                        content = re.sub(r'\s+', ' ', content)
                        sections[section_name] = content
        
        return sections
    
    def extract_recommendation(
        self, block_data: Dict[str, Any]
    ) -> Optional[CISRecommendation]:
        """Convert block data to CISRecommendation object"""
        try:
            sections = self.parse_sections(block_data)
            
            # Create recommendation object
            recommendation = CISRecommendation(
                cis_id=block_data['cis_id'],
                title=block_data['title'],
                profile=block_data['profile'],
                assessment_status=block_data['assessment_status'],
                description=sections.get('description', ''),
                rationale=sections.get('rationale', ''),
                impact=sections.get('impact', ''),
                audit_procedure=sections.get('audit', ''),
                remediation_procedure=sections.get('remediation', ''),
                default_value=sections.get('default_value', ''),
                page_number=block_data['start_page']
            )
            
            self.logger.info(
                f"Extracted recommendation {block_data['cis_id']} from page "
                f"{block_data['start_page']}"
            )
            return recommendation
            
        except Exception as e:
            self.logger.error(
                f"Error extracting recommendation "
                f"{block_data.get('cis_id', 'unknown')}: {e}"
            )
            return None
    
    def process_pdf(self):
        """Main method to process the PDF sequentially"""
        self.logger.info("Starting robust PDF processing")
        
        try:
            # Extract text from PDF
            self.extract_text_from_pdf()
            
            # Find first recommendation
            start_idx = self.find_next_recommendation(0)
            if start_idx is None:
                self.logger.error("No recommendations found in PDF")
                return
            
            # Process all recommendations sequentially
            while start_idx is not None:
                # Extract block
                block_data, next_start_idx = self.extract_recommendation_block(
                    start_idx
                )
                
                # Convert to recommendation object
                recommendation = self.extract_recommendation(block_data)
                if recommendation:
                    self.recommendations.append(recommendation)
                
                # Move to next recommendation
                start_idx = next_start_idx
            
            self.logger.info(
                f"Successfully processed {len(self.recommendations)} "
                "recommendations"
            )
            
        except Exception as e:
            self.logger.error(f"Error processing PDF: {e}")
            raise
    
    def save_to_json_by_section(self):
        """Save extracted recommendations to separate JSON files organized
        by section"""
        try:
            # Group recommendations by section (first part of CIS ID)
            sections = {}
            for rec in self.recommendations:
                # Get section number (e.g., "1" from "1.1.1")
                section_id = rec.cis_id.split('.')[0]
                if section_id not in sections:
                    sections[section_id] = []
                sections[section_id].append(asdict(rec))
            
            # Save each section to separate file
            for section_id, recommendations_data in sections.items():
                filename = f"cis_section_{section_id}.json"
                output_path = Path(self.output_dir) / filename
                
                with open(output_path, 'w', encoding='utf-8') as f:
                    json.dump(
                        recommendations_data, f, indent=2, ensure_ascii=False
                    )
                
                self.logger.info(
                    f"Saved {len(recommendations_data)} recommendations to "
                    f"{output_path}"
                )
            
            
        except Exception as e:
            self.logger.error(f"Error saving to JSON: {e}")
            raise
    
    def generate_summary_report(self):
        """Generate a summary report of the extraction process"""
        summary = {
            "total_recommendations": len(self.recommendations),
            "profiles": {},
            "assessment_status": {},
            "sections_with_content": {
                "description": 0,
                "rationale": 0,
                "impact": 0,
                "audit_procedure": 0,
                "remediation_procedure": 0
            }
        }
        
        for rec in self.recommendations:
            # Count profiles
            summary["profiles"][rec.profile] = (
                summary["profiles"].get(rec.profile, 0) + 1
            )
            
            # Count assessment status
            summary["assessment_status"][rec.assessment_status] = (
                summary["assessment_status"].get(rec.assessment_status, 0) + 1
            )
            
            # Count sections with content
            if rec.description and len(rec.description) > 10:
                summary["sections_with_content"]["description"] += 1
            if rec.rationale and len(rec.rationale) > 10:
                summary["sections_with_content"]["rationale"] += 1
            if rec.impact and len(rec.impact) > 10:
                summary["sections_with_content"]["impact"] += 1
            if rec.audit_procedure and len(rec.audit_procedure) > 10:
                summary["sections_with_content"]["audit_procedure"] += 1
            if rec.remediation_procedure and len(rec.remediation_procedure) > 10:
                summary["sections_with_content"]["remediation_procedure"] += 1
        
        return summary


def main():
    """Main function"""
    pdf_path = "docs/CIS_Microsoft_Windows_11_Stand-alone_Benchmark_v4.0.0.pdf"
    output_dir = "docs/json"
    
    if not Path(pdf_path).exists():
        print(f"Error: PDF file not found at {pdf_path}")
        return 1
    
    try:
        # Create extractor and process PDF
        extractor = CISRobustExtractor(pdf_path, output_dir)
        extractor.process_pdf()
        
        # Save results organized by section
        extractor.save_to_json_by_section()
        
        # Generate and print summary
        summary = extractor.generate_summary_report()
        print("\n=== Robust Extraction Summary ===")
        print(f"Total recommendations: {summary['total_recommendations']}")
        print(f"Profiles: {summary['profiles']}")
        print(f"Assessment status: {summary['assessment_status']}")
        print(f"Sections with content: {summary['sections_with_content']}")
        
        
    except Exception as e:
        print(f"Error during extraction: {e}")
        return 1
    
    return 0


if __name__ == "__main__":
    exit(main())