#!/usr/bin/env python3
"""
CIS Microsoft Windows 11 Benchmark Extractor

This script extracts audit and remediation procedures from the CIS Microsoft Windows 11
benchmark PDF and generates structured JSON data for use in automation scripts.

Requirements:
- pdfplumber for PDF text extraction
- regex patterns for identifying CIS recommendation structures
- JSON output following the defined schema
"""

import pdfplumber
import re
import json
import os
from pathlib import Path
from typing import Dict, List, Optional
import logging
from dataclasses import dataclass, asdict


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
    references: List[str] = None
    additional_info: str = ""
    page_number: int = 0
    
    def __post_init__(self):
        if self.references is None:
            self.references = []


class CISExtractor:
    """Main class for extracting CIS recommendations from PDF"""
    
    def __init__(self, pdf_path: str, output_dir: str = "cis-data/raw-json"):
        self.pdf_path = pdf_path
        self.output_dir = output_dir
        self.recommendations = []
        self.pages_text = []  # Store text for each page
        
        # Create output directory
        Path(output_dir).mkdir(parents=True, exist_ok=True)
        
        # Setup logging
        self.setup_logging()
        
        # Regex patterns for identifying CIS recommendation sections
        self.patterns = {
            'cis_id': r'^(\d+\.\d+(?:\.\d+)*)\s+',
            'title': r'Ensure\s+\'[^\']+\'\s+is\s+set\s+to\s+\'[^\']+\'',
            'profile': r'\((L1|L2|BL)\)',
            'assessment_status': r'\((Automated|Manual)\)',
            'page_reference': r'(\d+)$',
            'section_headers': {
                'description': r'Description',
                'rationale': r'Rationale',
                'impact': r'Impact',
                'audit': r'Audit',
                'remediation': r'Remediation',
                'default': r'Default Value',
                'references': r'References'
            }
        }
    
    def setup_logging(self):
        """Setup logging configuration"""
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler('cis_extraction.log'),
                logging.StreamHandler()
            ]
        )
        self.logger = logging.getLogger(__name__)
    
    def extract_text_from_pdf(self) -> List[Dict]:
        """Extract text from PDF using pdfplumber with page numbers"""
        self.logger.info(f"Extracting text from PDF: {self.pdf_path}")
        
        try:
            pages_data = []
            with pdfplumber.open(self.pdf_path) as pdf:
                for page_num, page in enumerate(pdf.pages, 1):
                    text = page.extract_text()
                    if text:
                        pages_data.append({
                            'page_number': page_num,
                            'text': text,
                            'lines': text.split('\n')
                        })
            
            self.pages_text = pages_data
            self.logger.info(f"Successfully extracted text from {len(pages_data)} pages")
            return pages_data
        except Exception as e:
            self.logger.error(f"Error extracting PDF text: {e}")
            raise
    
    def extract_table_of_contents(self) -> Dict[str, int]:
        """Extract CIS IDs and their page numbers from table of contents"""
        toc_mapping = {}
        
        # Look for patterns like "1.1.1 ... 39" in the first few pages
        for page_data in self.pages_text[:20]:  # TOC might span more pages
            for line in page_data['lines']:
                # Match patterns like "1.1.1 (L1) Ensure ... 39" or "1.1.1 ... 39"
                patterns = [
                    r'^(\d+\.\d+(?:\.\d+)*)\s+.*?(\d+)$',  # Standard pattern
                    r'^(\d+\.\d+(?:\.\d+)*)\s+\(L\d\).*?(\d+)$',  # With profile
                    r'^(\d+\.\d+(?:\.\d+)*)\s+Ensure.*?(\d+)$',  # With title start
                ]
                
                for pattern in patterns:
                    matches = re.findall(pattern, line)
                    for cis_id, page_num in matches:
                        if cis_id and page_num and cis_id not in toc_mapping:
                            # Apply page offset correction: TOC page numbers are often off by 1
                            # Add +1 to account for the discrepancy between TOC and actual content pages
                            corrected_page_num = int(page_num) + 1
                            toc_mapping[cis_id] = corrected_page_num
        
        self.logger.info(f"Extracted {len(toc_mapping)} CIS ID to page mappings from TOC")
        return toc_mapping
    
    def extract_recommendation_from_pages(self, start_page_data: Dict, cis_id: str) -> Optional[CISRecommendation]:
        """Extract a single recommendation spanning multiple pages"""
        try:
            # Start with the page from TOC mapping
            current_page_num = start_page_data['page_number']
            full_text = start_page_data['text']
            
            # Validate that we're on the correct page by checking for the CIS ID
            # Sometimes TOC mapping can be off, so we need to verify
            if not re.search(rf'{re.escape(cis_id)}\s+', full_text):
                # TOC mapping might be wrong - search nearby pages
                self.logger.warning(f"TOC mapping for {cis_id} may be incorrect. Searching nearby pages...")
                found_correct_page = False
                
                # Search ±2 pages around the TOC-mapped page
                for offset in [-2, -1, 1, 2]:
                    search_page_num = current_page_num + offset
                    if 1 <= search_page_num <= len(self.pages_text):
                        search_page_data = self.pages_text[search_page_num - 1]
                        if re.search(rf'{re.escape(cis_id)}\s+', search_page_data['text']):
                            current_page_num = search_page_num
                            full_text = search_page_data['text']
                            found_correct_page = True
                            self.logger.info(f"Found correct page for {cis_id} at page {current_page_num}")
                            break
                
                if not found_correct_page:
                    self.logger.warning(f"Could not find correct page for {cis_id}. Using TOC mapping page {current_page_num}")
            
            # Check if the recommendation continues on subsequent pages
            # Look for patterns that indicate continuation across multiple pages
            next_page_num = current_page_num + 1
            max_pages_to_check = 3  # Check up to 3 subsequent pages
            
            for i in range(max_pages_to_check):
                if next_page_num + i <= len(self.pages_text):
                    next_page_data = self.pages_text[next_page_num + i - 1]
                    next_text = next_page_data['text']
                    
                    # Check if next page continues the same recommendation
                    # Look for section headers or continuation patterns
                    
                    # If we find a new CIS ID, stop collecting
                    if re.search(rf'^\s*{re.escape(cis_id)}\s+',
                               next_text, re.MULTILINE):
                        break
                    
                    # If we find the next CIS recommendation, stop
                    next_cis_pattern = r'^\s*(\d+\.\d+(?:\.\d+)*)\s+'
                    next_cis_match = re.search(next_cis_pattern,
                                             next_text, re.MULTILINE)
                    if next_cis_match and next_cis_match.group(1) != cis_id:
                        break
                    
                    # Add the page content if it appears to continue
                    full_text += "\n" + next_text
            
            # Extract profile and assessment status with improved patterns
            profile_match = re.search(rf'{re.escape(cis_id)}.*?\((L1|L2|BL)\)',
                                    full_text)
            profile = profile_match.group(1) if profile_match else "L1"
            
            status_match = re.search(rf'{re.escape(cis_id)}.*?\((Automated|Manual)\)',
                                   full_text)
            assessment_status = status_match.group(1) if status_match else "Automated"
            
            # Extract title with multiple pattern attempts
            title = self.extract_title(full_text, cis_id)
            
            # Extract sections using improved patterns with fallbacks
            description = self.extract_section_content_enhanced(
                full_text, 'description')
            rationale = self.extract_section_content_enhanced(
                full_text, 'rationale')
            impact = self.extract_section_content_enhanced(
                full_text, 'impact')
            audit_procedure = self.extract_section_content_enhanced(
                full_text, 'audit')
            remediation_procedure = self.extract_section_content_enhanced(
                full_text, 'remediation')
            default_value = self.extract_section_content_enhanced(
                full_text, 'default')
            references = self.extract_references_enhanced(full_text)
            
            # Create recommendation object
            recommendation = CISRecommendation(
                cis_id=cis_id,
                title=title,
                profile=profile,
                assessment_status=assessment_status,
                description=description,
                rationale=rationale,
                impact=impact,
                audit_procedure=audit_procedure,
                remediation_procedure=remediation_procedure,
                default_value=default_value,
                references=references,
                page_number=current_page_num
            )
            
            self.logger.info(f"Successfully parsed recommendation {cis_id} from page {current_page_num}")
            return recommendation
            
        except Exception as e:
            self.logger.error(f"Error parsing recommendation {cis_id} from page {start_page_data['page_number']}: {e}")
            return None
    
    def extract_title(self, text: str, cis_id: str) -> str:
        """Extract title with multiple pattern attempts"""
        # Pattern 1: Standard CIS title format
        patterns = [
            rf'{re.escape(cis_id)}.*?\((?:L1|L2|BL)\).*?(Ensure\s+\'[^\']+\'\s+is\s+set\s+to\s+\'[^\']+\')',
            rf'{re.escape(cis_id)}.*?\((?:L1|L2|BL)\).*?(Ensure\s+[^\n]+)',
            rf'{re.escape(cis_id)}.*?(Ensure\s+[^\n]+)',
            rf'{re.escape(cis_id)}\s+(.*?)(?=\n\s*(?:Description|Rationale|Impact|Audit|Remediation|Default Value|References|\(L\d\)|\d+\.\d+))',
        ]
        
        for pattern in patterns:
            match = re.search(pattern, text, re.DOTALL | re.IGNORECASE)
            if match:
                title = match.group(1).strip()
                # Clean up the title
                title = re.sub(r'\s+', ' ', title)  # Normalize whitespace
                title = re.sub(r'\n', ' ', title)   # Remove newlines
                if len(title) > 10:  # Basic validation
                    return title
        
        # Fallback: Try to extract text after CIS ID
        fallback_pattern = rf'{re.escape(cis_id)}\s+(.*?)(?=\n|$)'
        fallback_match = re.search(fallback_pattern, text, re.DOTALL)
        if fallback_match:
            title = fallback_match.group(1).strip()
            if len(title) > 5:
                return title
        
        return f"CIS {cis_id}"
    
    def extract_section_content_enhanced(self, text: str, section_name: str) -> str:
        """Enhanced section content extraction with multiple patterns and fallbacks"""
        section_header = self.patterns['section_headers'][section_name]
        
        # Multiple patterns to handle different formatting styles
        patterns = [
            # Pattern 1: Section header followed by content until next section
            rf'{section_header}[\s:]*\n?(.*?)(?=\n\s*(?:{"|".join(self.patterns["section_headers"].values())})|\n\s*\d+\.\d+|$)',
            # Pattern 2: Section header with colon
            rf'{section_header}:\s*\n?(.*?)(?=\n\s*(?:{"|".join(self.patterns["section_headers"].values())})|\n\s*\d+\.\d+|$)',
            # Pattern 3: Section header on its own line
            rf'{section_header}\s*\n(.*?)(?=\n\s*(?:{"|".join(self.patterns["section_headers"].values())})|\n\s*\d+\.\d+|$)',
            # Pattern 4: Look for content after section header in the same paragraph
            rf'{section_header}[^\n]*(.*?)(?=\n\s*(?:{"|".join(self.patterns["section_headers"].values())})|\n\s*\d+\.\d+|$)',
            # Pattern 5: Simple pattern for sections that might span multiple pages
            rf'{section_header}[\s:]*\n(.*?)(?=\n\s*[A-Z][a-z]+:|$)',
            # Pattern 6: Fallback pattern for sections without clear boundaries
            rf'{section_header}[\s:]*\n(.*)',
        ]
        
        for pattern in patterns:
            match = re.search(pattern, text, re.DOTALL | re.IGNORECASE)
            if match:
                content = match.group(1).strip()
                if content and len(content) > 10:  # Basic validation - content should be meaningful
                    # Clean up the content
                    content = re.sub(r'\n+', ' ', content)  # Replace multiple newlines with space
                    content = re.sub(r'\s+', ' ', content)  # Normalize whitespace
                    
                    # Additional validation: content should not be just placeholder text
                    if not re.match(r'^[\.\s]*$', content) and not re.match(r'^Statement\s*$', content, re.IGNORECASE):
                        return content
        
        # Final fallback: Try to extract content using line-based approach
        lines = text.split('\n')
        for i, line in enumerate(lines):
            if section_header.lower() in line.lower():
                # Look for content in subsequent lines
                content_lines = []
                for j in range(i + 1, min(i + 20, len(lines))):  # Check next 20 lines
                    next_line = lines[j].strip()
                    if next_line and not any(header.lower() in next_line.lower() for header in self.patterns["section_headers"].values() if header != section_header):
                        content_lines.append(next_line)
                    else:
                        break
                
                if content_lines:
                    content = ' '.join(content_lines)
                    if len(content) > 10:
                        return content
        
        return ""
    
    def extract_references_enhanced(self, text: str) -> List[str]:
        """Enhanced reference extraction"""
        references = []
        
        # Pattern 1: Numbered references like "1. http://example.com"
        pattern1 = r'\d+\.\s*(https?://[^\s]+|[^\n]+?(?=\n\s*\d+\.|\n\s*[A-Z]|\n\s*$))'
        # Pattern 2: Bullet points or other reference formats
        pattern2 = r'•\s*(https?://[^\s]+|[^\n]+)'
        # Pattern 3: Lines that look like references (contain URLs or specific patterns)
        pattern3 = r'(https?://[^\s]+)'
        
        # Try each pattern
        for pattern in [pattern1, pattern2, pattern3]:
            matches = re.findall(pattern, text)
            for match in matches:
                ref = match.strip()
                # Basic validation
                if ref and len(ref) > 5 and not ref.startswith('Page'):
                    # Remove trailing punctuation and page numbers
                    ref = re.sub(r'[.,;]\s*Page\s+\d+.*$', '', ref)
                    ref = re.sub(r'[.,;]\s*$', '', ref)
                    if ref not in references:
                        references.append(ref)
        
        return references
    
    def extract_section_content(self, text: str, section_name: str) -> str:
        """Extract content for a specific section using improved patterns"""
        section_header = self.patterns['section_headers'][section_name]
        
        # Look for section header and extract content until next section
        # Handle various formats: "Description:", "Description", "Description\n"
        section_headers_list = list(self.patterns["section_headers"].values())
        patterns = [
            rf'{section_header}[\s:]*\n?(.*?)(?=\n\s*(?:{"|".join(section_headers_list)})|\n\s*\d+\.\d+|$)',
            rf'{section_header}:\s*\n?(.*?)(?=\n\s*(?:{"|".join(section_headers_list)})|\n\s*\d+\.\d+|$)',
            rf'{section_header}\s*\n?(.*?)(?=\n\s*(?:{"|".join(section_headers_list)})|\n\s*\d+\.\d+|$)'
        ]
        
        for pattern in patterns:
            match = re.search(pattern, text, re.DOTALL | re.IGNORECASE)
            if match:
                content = match.group(1).strip()
                # Clean up the content - remove extra whitespace and normalize
                content = re.sub(r'\n+', ' ', content)
                content = re.sub(r'\s+', ' ', content)
                return content
        
        return ""
    
    def extract_references(self, text: str) -> List[str]:
        """Extract references from the text"""
        references = []
        
        # Look for reference patterns like "1. http://example.com"
        pattern = r'\d+\.\s*(https?://[^\s]+|[^\n]+)'
        matches = re.findall(pattern, text)
        
        for match in matches:
            ref = match.strip()
            if ref and len(ref) > 5:  # Basic validation
                references.append(ref)
        
        return references
    
    def validate_recommendation(self, recommendation: CISRecommendation) -> bool:
        """Validate extracted recommendation data"""
        required_fields = ['cis_id', 'title', 'profile', 'assessment_status']
        
        for field in required_fields:
            if not getattr(recommendation, field):
                self.logger.warning(f"Missing required field '{field}' in recommendation {recommendation.cis_id}")
                return False
        
        # Validate CIS ID format (e.g., 1.1.1, 2.3.4.1)
        if not re.match(r'^\d+(\.\d+)+$', recommendation.cis_id):
            self.logger.warning(f"Invalid CIS ID format: {recommendation.cis_id}")
            return False
        
        return True
    
    def process_pdf(self):
        """Main method to process the PDF and extract recommendations"""
        self.logger.info("Starting PDF processing")
        
        try:
            # Extract text from PDF with page numbers
            self.extract_text_from_pdf()
            
            # Extract table of contents to get page mappings
            toc_mapping = self.extract_table_of_contents()
            
            # Process each CIS ID found in TOC
            valid_recommendations = []
            for cis_id, page_num in toc_mapping.items():
                # Find the page with the actual recommendation content
                target_page = None
                for page_data in self.pages_text:
                    if page_data['page_number'] == page_num:
                        target_page = page_data
                        break
                
                if target_page:
                    recommendation = self.extract_recommendation_from_pages(target_page, cis_id)
                    if recommendation and self.validate_recommendation(recommendation):
                        valid_recommendations.append(recommendation)
            
            self.recommendations = valid_recommendations
            self.logger.info(f"Successfully processed {len(valid_recommendations)} recommendations")
            
        except Exception as e:
            self.logger.error(f"Error processing PDF: {e}")
            raise
    
    def save_to_json_by_section(self):
        """Save extracted recommendations to separate JSON files organized by section"""
        try:
            # Group recommendations by section (first part of CIS ID)
            sections = {}
            for rec in self.recommendations:
                section_id = rec.cis_id.split('.')[0]  # Get section number (e.g., "1" from "1.1.1")
                if section_id not in sections:
                    sections[section_id] = []
                sections[section_id].append(asdict(rec))
            
            # Save each section to separate file
            for section_id, recommendations_data in sections.items():
                filename = f"cis_section_{section_id}.json"
                output_path = Path(self.output_dir) / filename
                
                with open(output_path, 'w', encoding='utf-8') as f:
                    json.dump(recommendations_data, f, indent=2, ensure_ascii=False)
                
                self.logger.info(f"Saved {len(recommendations_data)} recommendations to {output_path}")
            
            # Also save a master index file with section information
            index_data = {
                "total_recommendations": len(self.recommendations),
                "sections": {
                    section_id: len(recommendations)
                    for section_id, recommendations in sections.items()
                },
                "section_files": [
                    f"cis_section_{section_id}.json"
                    for section_id in sections.keys()
                ]
            }
            
            index_path = Path(self.output_dir) / "cis_sections_index.json"
            with open(index_path, 'w', encoding='utf-8') as f:
                json.dump(index_data, f, indent=2, ensure_ascii=False)
            
            self.logger.info(f"Saved section index to {index_path}")
            
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
            summary["profiles"][rec.profile] = summary["profiles"].get(rec.profile, 0) + 1
            
            # Count assessment status
            summary["assessment_status"][rec.assessment_status] = summary["assessment_status"].get(rec.assessment_status, 0) + 1
            
            # Count sections with content
            if rec.description and len(rec.description) > 10: summary["sections_with_content"]["description"] += 1
            if rec.rationale and len(rec.rationale) > 10: summary["sections_with_content"]["rationale"] += 1
            if rec.impact and len(rec.impact) > 10: summary["sections_with_content"]["impact"] += 1
            if rec.audit_procedure and len(rec.audit_procedure) > 10: summary["sections_with_content"]["audit_procedure"] += 1
            if rec.remediation_procedure and len(rec.remediation_procedure) > 10: summary["sections_with_content"]["remediation_procedure"] += 1
        
        return summary


def main():
    """Main function"""
    pdf_path = "docs/CIS_Microsoft_Windows_11_Stand-alone_Benchmark_v4.0.0.pdf"
    output_dir = "cis-data/raw-json"
    
    if not os.path.exists(pdf_path):
        print(f"Error: PDF file not found at {pdf_path}")
        return
    
    try:
        # Create extractor and process PDF
        extractor = CISExtractor(pdf_path, output_dir)
        extractor.process_pdf()
        
        # Save results organized by section
        extractor.save_to_json_by_section()
        
        # Generate and print summary
        summary = extractor.generate_summary_report()
        print("\n=== Extraction Summary ===")
        print(f"Total recommendations: {summary['total_recommendations']}")
        print(f"Profiles: {summary['profiles']}")
        print(f"Assessment status: {summary['assessment_status']}")
        print(f"Sections with content: {summary['sections_with_content']}")
        
        # Save summary to file
        summary_path = Path(output_dir) / "extraction_summary.json"
        with open(summary_path, 'w') as f:
            json.dump(summary, f, indent=2)
        print(f"Summary saved to: {summary_path}")
        
    except Exception as e:
        print(f"Error during extraction: {e}")
        return 1
    
    return 0


if __name__ == "__main__":
    exit(main())