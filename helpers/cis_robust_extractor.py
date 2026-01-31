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
from dataclasses import dataclass, asdict
from typing import List, Optional, Dict, Tuple, Any


@dataclass
class CISRecommendation:
    """Data class representing a CIS recommendation"""
    cis_id: str
    title: str
    profile: str
    description: str
    rationale: str
    impact: str
    audit_procedure: str
    remediation_procedure: str
    default_value: str = ""
    page_number: int = 0


class Config:
    """Configuration constants for the extractor"""
    
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
    
    # Processing limits
    MAX_LOOKAHEAD_PAGES = 10
    MAX_RETRIES = 3
    CHUNK_SIZE = 10
    
    # File paths
    DEFAULT_PDF_PATH = "docs/CIS_Microsoft_Windows_11_Stand-alone_Benchmark_v4.0.0.pdf"
    DEFAULT_OUTPUT_DIR = "docs/json"
    LOG_FILE = "cis_extraction_robust.log"


class RegexPatterns:
    """Pre-compiled regex patterns for performance"""

    def __init__(self):
        """Initialize all regex patterns"""
        self.rec_start = self._compile_rec_start_pattern()
        self.rec_start_fallback = self._compile_fallback_pattern()
        self.cis_id_pattern = self._compile_cis_id_pattern()
        self.section_patterns = self._compile_section_patterns()

    def _compile_rec_start_pattern(self):
        """Compile primary recommendation start pattern"""
        pattern = (
            r'^(\d+\.\d+(?:\.\d+)*)\s+\((L1|L2|BL)\)\s+(Ensure|Configure)\s+'
            r'(.+?)\s+\((Automated|Manual)\)'
        )
        return re.compile(pattern, re.DOTALL | re.IGNORECASE)

    def _compile_fallback_pattern(self):
        """Compile fallback recommendation start pattern"""
        pattern = r'^(\d+\.\d+(?:\.\d+)*)\s+(Ensure|Configure)\s+(.+?)\s+\((Automated|Manual)\)'
        return re.compile(pattern, re.DOTALL | re.IGNORECASE)

    def _compile_cis_id_pattern(self):
        """Compile CIS ID pattern"""
        return re.compile(r'^\s*(\d+\.\d+(?:\.\d+)*)\s+', re.MULTILINE)

    def _compile_section_patterns(self):
        """Compile all section patterns"""
        return {
            'description': self._compile_description_pattern(),
            'rationale': self._compile_rationale_pattern(),
            'impact': self._compile_impact_pattern(),
            'audit': self._compile_audit_pattern(),
            'remediation': self._compile_remediation_pattern(),
            'default_value': self._compile_default_value_pattern()
        }

    def _compile_description_pattern(self):
        """Compile description section pattern"""
        pattern = r'Description:\s*\n(.*?)(?=\n\s*(?:Rationale:|Impact:|Audit:|Remediation:|Default Value:|$))'
        return re.compile(pattern, re.DOTALL | re.IGNORECASE)

    def _compile_rationale_pattern(self):
        """Compile rationale section pattern"""
        pattern = r'Rationale:\s*\n(.*?)(?=\n\s*(?:Impact:|Audit:|Remediation:|Default Value:|$))'
        return re.compile(pattern, re.DOTALL | re.IGNORECASE)

    def _compile_impact_pattern(self):
        """Compile impact section pattern"""
        pattern = r'Impact:\s*\n(.*?)(?=\n\s*(?:Audit:|Remediation:|Default Value:|$))'
        return re.compile(pattern, re.DOTALL | re.IGNORECASE)

    def _compile_audit_pattern(self):
        """Compile audit section pattern"""
        pattern = r'Audit:\s*\n(.*?)(?=\n\s*(?:Remediation:|Default Value:|$))'
        return re.compile(pattern, re.DOTALL | re.IGNORECASE)

    def _compile_remediation_pattern(self):
        """Compile remediation section pattern"""
        pattern = r'Remediation:\s*\n(.*?)(?=\n\s*(?:Default Value:|$))'
        return re.compile(pattern, re.DOTALL | re.IGNORECASE)

    def _compile_default_value_pattern(self):
        """Compile default value section pattern"""
        pattern = r'Default Value:\s*\n(.*?)(?=\n\s*(?:References:|Additional Information:|$))'
        return re.compile(pattern, re.DOTALL | re.IGNORECASE)


class LoggerSetup:
    """Handles logging configuration"""

    @staticmethod
    def setup() -> logging.Logger:
        """Setup and configure logger"""
        LoggerSetup._suppress_pdf_logging()
        logger = LoggerSetup._create_logger()
        LoggerSetup._add_file_handler(logger)
        LoggerSetup._add_console_handler(logger)
        logger.propagate = False
        return logger

    @staticmethod
    def _suppress_pdf_logging():
        """Suppress verbose PDF library logging"""
        logging.getLogger('pdfminer').setLevel(logging.WARNING)
        logging.getLogger('pdfplumber').setLevel(logging.WARNING)

    @staticmethod
    def _create_logger() -> logging.Logger:
        """Create and configure main logger"""
        logger = logging.getLogger(__name__)
        logger.setLevel(logging.INFO)
        logger.handlers.clear()
        return logger

    @staticmethod
    def _add_file_handler(logger: logging.Logger):
        """Add file handler for warnings and errors"""
        file_handler = logging.FileHandler(Config.LOG_FILE)
        file_handler.setLevel(logging.WARNING)
        formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
        file_handler.setFormatter(formatter)
        logger.addHandler(file_handler)

    @staticmethod
    def _add_console_handler(logger: logging.Logger):
        """Add console handler for info messages"""
        console_handler = logging.StreamHandler()
        console_handler.setLevel(logging.INFO)
        formatter = logging.Formatter('%(levelname)s - %(message)s')
        console_handler.setFormatter(formatter)
        logger.addHandler(console_handler)


class PDFExtractor:
    """Handles PDF text extraction with retry logic"""
    
    def __init__(self, logger: logging.Logger, patterns: RegexPatterns):
        """Initialize PDF extractor"""
        self.logger = logger
        self.patterns = patterns
        self.pages_text: List[Dict] = []
    
    def validate_pdf_path(self, pdf_path: str) -> bool:
        """Validate that PDF file exists and is readable"""
        path = Path(pdf_path)
        if not path.exists():
            self.logger.error(f"PDF file not found: {pdf_path}")
            return False
        if not path.is_file():
            self.logger.error(f"Path is not a file: {pdf_path}")
            return False
        return True
    
    def extract_page_text(self, page: pdfplumber.Page, page_num: int) -> Dict:
        """Extract text from a single page"""
        text = page.extract_text() or ''
        return {
            'page_number': page_num,
            'text': text,
            'lines': text.split('\n') if text else []
        }
    
    def extract_text_from_pdf(self, pdf_path: str) -> List[Dict]:
        """Extract text from PDF within the remediation range with retry logic"""
        if not self.validate_pdf_path(pdf_path):
            raise FileNotFoundError(f"PDF not found: {pdf_path}")

        self.logger.info(f"Extracting text from PDF: {pdf_path}")
        return self._retry_extraction(pdf_path)

    def _retry_extraction(self, pdf_path: str) -> List[Dict]:
        """Retry PDF extraction with error handling"""
        for attempt in range(Config.MAX_RETRIES):
            try:
                return self._attempt_extraction(pdf_path)
            except Exception as e:
                if attempt == Config.MAX_RETRIES - 1:
                    self.logger.error(f"Failed after {Config.MAX_RETRIES} attempts: {e}")
                    raise
                self.logger.warning(f"Attempt {attempt + 1} failed, retrying...")
        return []
    
    def _attempt_extraction(self, pdf_path: str) -> List[Dict]:
        """Attempt PDF extraction"""
        pages_data = []
        
        with pdfplumber.open(pdf_path) as pdf:
            for page_num in range(1, len(pdf.pages) + 1):
                if not self._is_page_in_range(page_num):
                    continue
                
                page = pdf.pages[page_num - 1]
                page_data = self.extract_page_text(page, page_num)
                pages_data.append(page_data)
        
        self.pages_text = pages_data
        self.logger.info(
            f"Extracted {len(pages_data)} pages (range {Config.START_PAGE}-{Config.END_PAGE})"
        )
        return pages_data
    
    def _is_page_in_range(self, page_num: int) -> bool:
        """Check if page is within remediation range"""
        return Config.START_PAGE <= page_num <= Config.END_PAGE


class TextParser:
    """Handles text parsing and recommendation extraction"""
    
    def __init__(self, logger: logging.Logger, patterns: RegexPatterns):
        """Initialize text parser"""
        self.logger = logger
        self.patterns = patterns
    
    def is_recommendation_start(self, text: str) -> Optional[Tuple[str, str, str]]:
        """Check if text starts with a recommendation pattern"""
        match = self.patterns.rec_start.search(text)
        if match:
            cis_id, profile, action_type, title, _ = match.groups()
            return cis_id, profile, f"{action_type} {title}"
        
        match = self.patterns.rec_start_fallback.search(text)
        if match:
            cis_id, action_type, title, _ = match.groups()
            return cis_id, "L1", f"{action_type} {title}"
        
        return None
    
    def find_next_recommendation(self, pages: List[Dict], start_index: int) -> Optional[int]:
        """Find the next page index containing a recommendation start"""
        for i in range(start_index, len(pages)):
            if self.is_recommendation_start(pages[i]['text']):
                return i
        return None
    
    def should_continue_page(self, next_text: str, current_cis_id: str) -> bool:
        """Determine if next page is continuation of current recommendation"""
        if self.is_recommendation_start(next_text):
            return False
        
        cis_match = self.patterns.cis_id_pattern.search(next_text)
        if not cis_match:
            return True
        
        if cis_match.group(1) == current_cis_id:
            return True
        
        headers = ["Audit:", "Remediation:", "Default Value:", "CIS Controls:"]
        return any(header in next_text for header in headers)
    
    def extract_recommendation_block(
        self, pages: List[Dict], start_index: int
    ) -> Tuple[Dict[str, Any], Optional[int]]:
        """Extract a recommendation block starting at page index"""
        start_page = pages[start_index]
        rec_info = self.is_recommendation_start(start_page['text'])

        if not rec_info:
            raise ValueError(f"Page {start_page['page_number']} is not a recommendation start")

        cis_id, profile, title = rec_info
        block_pages, full_text = self._collect_continuation_pages(
            pages, start_index, start_page, cis_id
        )

        block_data = self._build_block_data(
            cis_id, profile, title, block_pages, full_text, start_page['page_number']
        )
        next_start = self.find_next_recommendation(pages, start_index + 1)
        return block_data, next_start

    def _collect_continuation_pages(
        self, pages: List[Dict], start_index: int, start_page: Dict, cis_id: str
    ) -> Tuple[List[int], str]:
        """Collect continuation pages for a recommendation"""
        block_pages = [start_page['page_number']]
        full_text = start_page['text']

        for offset in range(1, Config.MAX_LOOKAHEAD_PAGES + 1):
            next_idx = start_index + offset
            if next_idx >= len(pages):
                break

            next_page = pages[next_idx]
            if not self.should_continue_page(next_page['text'], cis_id):
                break

            block_pages.append(next_page['page_number'])
            full_text += "\n" + next_page['text']

        return block_pages, full_text

    def _build_block_data(
        self, cis_id: str, profile: str, title: str,
        block_pages: List[int], full_text: str, start_page_num: int
    ) -> Dict[str, Any]:
        """Build block data dictionary"""
        return {
            'cis_id': cis_id,
            'profile': profile,
            'title': title,
            'pages': block_pages,
            'full_text': full_text,
            'start_page': start_page_num
        }
    
    def parse_sections(self, block_data: Dict[str, Any]) -> Dict[str, Any]:
        """Parse sections from recommendation block text"""
        sections = {
            'description': '',
            'rationale': '',
            'impact': '',
            'audit': '',
            'remediation': '',
            'default_value': ''
        }
        
        self._parse_sections_by_line(block_data['full_text'], sections)
        self._apply_fallback_patterns(block_data['full_text'], sections)
        
        return sections
    
    def _parse_sections_by_line(self, text: str, sections: Dict[str, Any]):
        """Parse sections using line-by-line approach"""
        header_map = {
            'description': ['Description:'],
            'rationale': ['Rationale:'],
            'impact': ['Impact:'],
            'audit': ['Audit:'],
            'remediation': ['Remediation:'],
            'default_value': ['Default Value:']
        }
        
        lines = text.split('\n')
        current_section = None
        current_content = []
        
        for line in lines:
            line_stripped = line.strip()
            found = self._check_for_header(line_stripped, header_map)
            
            if found:
                self._save_section(current_section, current_content, sections)
                current_section, current_content = found
            elif current_section is not None:
                current_content.append(line_stripped)
        
        self._save_section(current_section, current_content, sections)
    
    def _check_for_header(
        self, line: str, header_map: Dict[str, List[str]]
    ) -> Optional[Tuple[str, List[str]]]:
        """Check if line contains a section header"""
        for section_key, headers in header_map.items():
            for header in headers:
                if line.startswith(header):
                    remaining = line[len(header):].strip()
                    return section_key, [remaining] if remaining else []
        return None
    
    def _save_section(
        self, section: Optional[str], content: List[str], sections: Dict[str, Any]
    ):
        """Save section content to sections dict"""
        if section is not None:
            sections[section] = '\n'.join(content).strip()
    
    def _apply_fallback_patterns(self, text: str, sections: Dict[str, Any]):
        """Apply regex patterns as fallback for empty sections"""
        if sections['description'] and sections['audit']:
            return
        
        for section_name, pattern in self.patterns.section_patterns.items():
            if not sections[section_name]:
                match = pattern.search(text)
                if match:
                    content = re.sub(r'\s+', ' ', match.group(1).strip())
                    sections[section_name] = content


class JSONWriter:
    """Handles JSON output operations"""
    
    def __init__(self, logger: logging.Logger, output_dir: str):
        """Initialize JSON writer"""
        self.logger = logger
        self.output_dir = output_dir
        self._ensure_output_dir()
    
    def _ensure_output_dir(self):
        """Create output directory if it doesn't exist"""
        Path(self.output_dir).mkdir(parents=True, exist_ok=True)
    
    def validate_output_dir(self, output_dir: str) -> bool:
        """Validate output directory is writable"""
        path = Path(output_dir)
        if path.exists() and not path.is_dir():
            self.logger.error(f"Output path is not a directory: {output_dir}")
            return False
        return True
    
    def save_recommendations(self, recommendations: List[CISRecommendation]):
        """Save recommendations to JSON files organized by section"""
        sections = self._group_by_section(recommendations)
        self._save_sections(sections)
    
    def _group_by_section(
        self, recommendations: List[CISRecommendation]
    ) -> Dict[str, List[Dict]]:
        """Group recommendations by section number"""
        sections = {}
        for rec in recommendations:
            section_id = rec.cis_id.split('.')[0]
            if section_id not in sections:
                sections[section_id] = []
            sections[section_id].append(asdict(rec))
        return sections
    
    def _save_sections(self, sections: Dict[str, List[Dict]]):
        """Save each section to separate JSON files"""
        for section_id, recommendations_data in sections.items():
            self._save_section_chunks(section_id, recommendations_data)
    
    def _save_section_chunks(self, section_id: str, recommendations_data: List[Dict]):
        """Save section data in chunks"""
        for i in range(0, len(recommendations_data), Config.CHUNK_SIZE):
            chunk = recommendations_data[i:i + Config.CHUNK_SIZE]
            part_number = (i // Config.CHUNK_SIZE) + 1
            self._write_chunk_file(section_id, part_number, chunk)
    
    def _write_chunk_file(
        self, section_id: str, part_number: int, chunk: List[Dict]
    ):
        """Write a single chunk to JSON file"""
        filename = f"cis_section_{section_id}_{part_number}.json"
        output_path = Path(self.output_dir) / filename
        
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(chunk, f, indent=2, ensure_ascii=False)
        
        self.logger.info(f"Saved {len(chunk)} recommendations to {output_path}")


class CISRobustExtractor:
    """Main orchestrator for CIS recommendation extraction"""
    
    def __init__(
        self,
        pdf_path: str = None,
        output_dir: str = None,
        start_page: int = None,
        end_page: int = None
    ):
        """Initialize the extractor with optional custom parameters"""
        self.pdf_path = pdf_path or Config.DEFAULT_PDF_PATH
        self.output_dir = output_dir or Config.DEFAULT_OUTPUT_DIR
        
        # Allow custom page ranges for testing
        if start_page is not None:
            Config.START_PAGE = start_page
        if end_page is not None:
            Config.END_PAGE = end_page
        
        self.recommendations: List[CISRecommendation] = []
        self.logger = LoggerSetup.setup()
        self.patterns = RegexPatterns()
        
        # Initialize components
        self.pdf_extractor = PDFExtractor(self.logger, self.patterns)
        self.text_parser = TextParser(self.logger, self.patterns)
        self.json_writer = JSONWriter(self.logger, self.output_dir)
    
    def process_pdf(self):
        """Main method to process the PDF sequentially"""
        self.logger.info("Starting robust PDF processing")
        
        try:
            pages = self.pdf_extractor.extract_text_from_pdf(self.pdf_path)
            self._extract_all_recommendations(pages)
            self.logger.info(f"Processed {len(self.recommendations)} recommendations")
        except Exception as e:
            self.logger.error(f"Error processing PDF: {e}")
            raise
    
    def _extract_all_recommendations(self, pages: List[Dict]):
        """Extract all recommendations from pages"""
        start_idx = self.text_parser.find_next_recommendation(pages, 0)
        
        if start_idx is None:
            self.logger.error("No recommendations found in PDF")
            return
        
        while start_idx is not None:
            block_data, next_start_idx = self.text_parser.extract_recommendation_block(
                pages, start_idx
            )
            recommendation = self._create_recommendation(block_data)
            
            if recommendation:
                self.recommendations.append(recommendation)
            
            start_idx = next_start_idx
    
    def _create_recommendation(
        self, block_data: Dict[str, Any]
    ) -> Optional[CISRecommendation]:
        """Create CISRecommendation from block data"""
        try:
            sections = self.text_parser.parse_sections(block_data)
            recommendation = self._build_recommendation_object(block_data, sections)
            self._log_extraction_success(block_data)
            return recommendation
        except Exception as e:
            self._log_extraction_error(block_data, e)
            return None

    def _build_recommendation_object(
        self, block_data: Dict[str, Any], sections: Dict[str, Any]
    ) -> CISRecommendation:
        """Build CISRecommendation object from block data and sections"""
        return CISRecommendation(
            cis_id=block_data['cis_id'],
            title=block_data['title'],
            profile=block_data['profile'],
            description=sections.get('description', ''),
            rationale=sections.get('rationale', ''),
            impact=sections.get('impact', ''),
            audit_procedure=sections.get('audit', ''),
            remediation_procedure=sections.get('remediation', ''),
            default_value=sections.get('default_value', ''),
            page_number=block_data['start_page']
        )

    def _log_extraction_success(self, block_data: Dict[str, Any]):
        """Log successful recommendation extraction"""
        msg = f"Extracted {block_data['cis_id']} from page {block_data['start_page']}"
        self.logger.info(msg)

    def _log_extraction_error(self, block_data: Dict[str, Any], error: Exception):
        """Log recommendation extraction error"""
        cis_id = block_data.get('cis_id', 'unknown')
        self.logger.error(f"Error extracting {cis_id}: {error}")
    
    def save_to_json_by_section(self):
        """Save extracted recommendations to JSON files"""
        try:
            self.json_writer.save_recommendations(self.recommendations)
        except Exception as e:
            self.logger.error(f"Error saving to JSON: {e}")
            raise
    
    def generate_summary_report(self) -> Dict[str, Any]:
        """Generate a summary report of the extraction process"""
        summary = {
            "total_recommendations": len(self.recommendations),
            "profiles": {},
            "sections_with_content": {
                "description": 0,
                "rationale": 0,
                "impact": 0,
                "audit_procedure": 0,
                "remediation_procedure": 0
            }
        }
        
        for rec in self.recommendations:
            summary["profiles"][rec.profile] = (
                summary["profiles"].get(rec.profile, 0) + 1
            )
            
            if len(rec.description) > 10:
                summary["sections_with_content"]["description"] += 1
            if len(rec.rationale) > 10:
                summary["sections_with_content"]["rationale"] += 1
            if len(rec.impact) > 10:
                summary["sections_with_content"]["impact"] += 1
            if len(rec.audit_procedure) > 10:
                summary["sections_with_content"]["audit_procedure"] += 1
            if len(rec.remediation_procedure) > 10:
                summary["sections_with_content"]["remediation_procedure"] += 1
        
        return summary


def main():
    """Main function"""
    pdf_path = Config.DEFAULT_PDF_PATH
    output_dir = Config.DEFAULT_OUTPUT_DIR
    
    if not Path(pdf_path).exists():
        print(f"Error: PDF file not found at {pdf_path}")
        return 1
    
    try:
        extractor = CISRobustExtractor(pdf_path, output_dir)
        extractor.process_pdf()
        extractor.save_to_json_by_section()
        
        summary = extractor.generate_summary_report()
        print("\n=== Robust Extraction Summary ===")
        print(f"Total recommendations: {summary['total_recommendations']}")
        print(f"Profiles: {summary['profiles']}")
        print(f"Sections with content: {summary['sections_with_content']}")
    except Exception as e:
        print(f"Error during extraction: {e}")
        return 1
    
    return 0


if __name__ == "__main__":
    exit(main())
