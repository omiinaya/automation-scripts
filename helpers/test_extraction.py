#!/usr/bin/env python3
"""
Quick test of the extraction script with limited page range.

This test script validates the refactored CISRobustExtractor by:
- Testing with a limited page range for faster execution
- Verifying recommendation extraction
- Checking section parsing
- Validating JSON output
"""

import sys
from pathlib import Path

from cis_robust_extractor import CISRobustExtractor, CISRecommendation


class TestConfig:
    """Configuration for test execution"""

    # Test page range (small subset for quick testing)
    TEST_START_PAGE = 39
    TEST_END_PAGE = 45

    # Test paths
    PDF_FILENAME = "CIS_Microsoft_Windows_11_Stand-alone_Benchmark_v4.0.0.pdf"
    TEST_PDF_PATH = f"../docs/{PDF_FILENAME}"
    TEST_OUTPUT_DIR = "docs/json_test_quick"

    # Expected minimum results
    MIN_EXPECTED_RECOMMENDATIONS = 1


class ExtractionTester:
    """Test harness for CIS extraction functionality"""

    def __init__(
        self,
        pdf_path: str,
        output_dir: str,
        start_page: int,
        end_page: int
    ):
        """Initialize test harness"""
        self.pdf_path = pdf_path
        self.output_dir = output_dir
        self.start_page = start_page
        self.end_page = end_page
        self.extractor = None
        self.test_results = []

    def validate_inputs(self) -> bool:
        """Validate test inputs before execution"""
        if not Path(self.pdf_path).exists():
            print(f"Error: PDF file not found at {self.pdf_path}")
            return False

        if self.start_page >= self.end_page:
            msg = f"Error: Invalid page range ({self.start_page} >= {self.end_page})"
            print(msg)
            return False

        return True

    def create_extractor(self) -> CISRobustExtractor:
        """Create extractor with test configuration"""
        return CISRobustExtractor(
            pdf_path=self.pdf_path,
            output_dir=self.output_dir,
            start_page=self.start_page,
            end_page=self.end_page
        )

    def run_extraction(self) -> bool:
        """Run the extraction process"""
        try:
            self.extractor = self.create_extractor()
            self.extractor.process_pdf()
            return True
        except Exception as e:
            print(f"Error during extraction: {e}")
            return False

    def validate_extraction(self) -> bool:
        """Validate extraction results"""
        rec_count = len(self.extractor.recommendations)

        if rec_count < TestConfig.MIN_EXPECTED_RECOMMENDATIONS:
            msg = (f"Error: Expected at least "
                   f"{TestConfig.MIN_EXPECTED_RECOMMENDATIONS} "
                   f"recommendations, found {rec_count}")
            print(msg)
            return False

        print(f"✓ Extracted {rec_count} recommendations")
        return True

    def test_recommendation_structure(self) -> bool:
        """Test that recommendations have proper structure"""
        for rec in self.extractor.recommendations:
            if not self._validate_recommendation(rec):
                return False
        print("✓ All recommendations have valid structure")
        return True

    def _validate_recommendation(self, rec: CISRecommendation) -> bool:
        """Validate individual recommendation structure"""
        required_fields = [
            'cis_id', 'title', 'profile', 'description',
            'rationale', 'impact', 'audit_procedure',
            'remediation_procedure'
        ]

        for field in required_fields:
            if not hasattr(rec, field):
                print(f"Error: Missing field '{field}' in recommendation")
                return False

        if not rec.cis_id:
            print("Error: Empty CIS ID")
            return False

        return True

    def test_json_output(self) -> bool:
        """Test JSON output generation"""
        try:
            self.extractor.save_to_json_by_section()
            output_files = list(Path(self.output_dir).glob("*.json"))

            if not output_files:
                print("Error: No JSON files generated")
                return False

            print(f"✓ Generated {len(output_files)} JSON file(s)")
            return True
        except Exception as e:
            print(f"Error saving JSON: {e}")
            return False

    def test_summary_report(self) -> bool:
        """Test summary report generation"""
        try:
            summary = self.extractor.generate_summary_report()

            if summary['total_recommendations'] == 0:
                print("Error: Summary shows zero recommendations")
                return False

            msg = (f"✓ Summary report generated: "
                   f"{summary['total_recommendations']} recommendations")
            print(msg)
            return True
        except Exception as e:
            print(f"Error generating summary: {e}")
            return False

    def cleanup(self):
        """Clean up test output files"""
        output_path = Path(self.output_dir)
        if output_path.exists():
            for file in output_path.glob("*.json"):
                file.unlink()
            print("✓ Cleaned up test output directory")


def run_test():
    """Main test execution function"""
    print("=== CIS Extraction Test ===\n")

    # Initialize tester
    tester = ExtractionTester(
        pdf_path=TestConfig.TEST_PDF_PATH,
        output_dir=TestConfig.TEST_OUTPUT_DIR,
        start_page=TestConfig.TEST_START_PAGE,
        end_page=TestConfig.TEST_END_PAGE
    )

    # Validate inputs
    if not tester.validate_inputs():
        return False

    # Run extraction
    msg = (f"Testing pages {TestConfig.TEST_START_PAGE}-"
           f"{TestConfig.TEST_END_PAGE}...\n")
    print(msg)
    if not tester.run_extraction():
        return False

    # Validate results
    tests = [
        ("Extraction validation", tester.validate_extraction),
        ("Recommendation structure", tester.test_recommendation_structure),
        ("JSON output", tester.test_json_output),
        ("Summary report", tester.test_summary_report)
    ]

    all_passed = True
    for test_name, test_func in tests:
        print(f"\nRunning: {test_name}")
        if not test_func():
            all_passed = False

    # Cleanup
    print("\n" + "="*40)
    if all_passed:
        print("✓ All tests passed!")
        tester.cleanup()
        return True
    else:
        print("✗ Some tests failed")
        return False


if __name__ == "__main__":
    success = run_test()
    exit(0 if success else 1)
