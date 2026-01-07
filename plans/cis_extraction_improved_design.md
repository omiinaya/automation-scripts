# Improved CIS PDF Extraction Logic Design

## Overview

This document outlines a robust solution for extracting CIS recommendations from the PDF "CIS_Microsoft_Windows_11_Stand-alone_Benchmark_v4.0.0.pdf". The goal is to address identified inconsistencies: empty content fields, incorrect page numbers, malformed content, duplicate CIS IDs, inconsistent profile assignments, references extraction issues, default value inconsistency, title formatting anomalies, assessment status mismatch, section content coverage, page number accuracy, and data integrity.

## Root Causes Analysis

Based on examination of current extraction script (`scripts/cis_extractor.py`) and extracted data (`cis-data/raw-json/cis_section_1.json`), the main issues are:

1. **TOC Extraction Inaccuracy**: Page mapping from table of contents is flawed due to:
   - Incorrect page offset correction (+1 may not be appropriate)
   - Multi-line TOC entries not properly parsed
   - Missing CIS IDs in TOC (some recommendations not listed)

2. **Regex Pattern Limitations**:
   - Section headers may appear with/without colons, varying whitespace
   - Patterns assume specific ordering (Description → Rationale → Impact → Audit → Remediation → Default Value → References)
   - Content boundaries incorrectly detected due to overlapping patterns

3. **Multi-page Recommendation Handling**:
   - Continuation detection fails when next page contains new CIS ID but also continuation of previous content
   - No handling for tables or special formatting (e.g., bullet lists)

4. **Title Extraction**:
   - Titles may be truncated or include extra metadata
   - Pattern `Ensure '...' is set to '...'` may not match all variations

5. **Reference Extraction**:
   - References section may contain URLs, document IDs, or plain text
   - Extraction cuts off at spaces or newlines
   - References incorrectly parsed as CIS IDs (e.g., "5.2" mistaken for recommendation)

6. **Duplicate Detection**:
   - Same CIS ID extracted multiple times from different page ranges (TOC vs content extraction)

7. **Page Number Validation**:
   - No validation that extracted page matches actual recommendation location

8. **Table Data Loss**:
   - Default values and references often presented in tabular format; plain text extraction loses structure.

## Proposed Solution Architecture

### 1. Enhanced PDF Text Extraction with Layout Detection

Instead of relying solely on `page.extract_text()`, use pdfplumber's advanced features:

- **`page.extract_words()`**: Get words with bounding boxes to understand layout
- **`page.extract_tables()`**: Extract tabular data (for default values, references)
- **`page.chars`**: Character-level extraction for precise positioning

This allows us to:
- Identify section headers based on font size/weight (if detectable)
- Distinguish between body text and footers/headers
- Handle multi-column layouts
- Preserve table structure

### 2. Two-Pass Extraction Strategy

**First Pass: Structure Mapping**
- Extract table of contents with improved parsing (considering page number formats)
- Build a map of CIS ID → page number with confidence scores
- Validate mappings by checking if CIS ID appears on that page

**Second Pass: Content Extraction**
- For each CIS ID, locate its starting page using the map
- Extract the recommendation block using layout-aware boundaries
- Use heuristics to determine when recommendation ends (next CIS ID, page break, section header)

### 3. Improved Regex Patterns with Fallbacks

Design hierarchical pattern matching:

1. **Primary Patterns**: Exact matches for common formats (e.g., "Description:\n")
2. **Secondary Patterns**: Flexible matches (e.g., "Description\s*\n")
3. **Tertiary Patterns**: Layout-based extraction (using word positions)

Patterns will be configurable and ordered by specificity.

### 4. Section Boundary Detection Algorithm

```
Algorithm: ExtractSectionContent(text, section_header)
1. Find all occurrences of section_header in text
2. For each occurrence:
   a. Determine if it's a true section header (not part of another word)
   b. Look ahead for termination signals:
      - Next section header (from known set)
      - Next CIS ID pattern (^\d+\.\d+)
      - Page boundary (if multi-page)
   c. Extract content between header and termination
   d. Validate content length and quality
   e. If valid, return content
3. If no valid content found, try layout-based extraction
4. Return empty string as last resort
```

### 5. Multi-page Recommendation Handling

- **Continuation Detection**: Check if the recommendation text ends with incomplete sentence or section
- **Page Linking**: Use pdfplumber's `page.rects` to detect section continuations
- **Maximum Page Span**: Limit to 5 pages per recommendation to avoid over-collection
- **Heuristic**: If next page contains a new CIS ID but also continues the same section (e.g., "Description" continues), treat as continuation and split later.

### 6. Table Extraction Strategy

- **Identify Tables**: Use `page.extract_tables()` to detect tabular structures.
- **Map Tables to Sections**: Determine which table belongs to which recommendation based on proximity.
- **Parse Table Content**:
   - Default values often appear in two-column tables (Parameter, Value).
   - References may be in multi-column tables (GRID, Control, IG1, IG2, IG3).
- **Integration**: For each recommendation, scan nearby tables and associate rows with matching CIS ID.
- **Fallback**: If table extraction fails, fall back to regex patterns on flattened text.

### 7. Reference Extraction Enhancement

- **Patterns**:
   - URL pattern: `https?://[^\s]+`
   - Document ID: `[A-Z]{2,}-\d{8}` (e.g., MS-00000332)
   - CIS reference pattern: `\b\d+\.\d+\b` but must be distinguished from CIS IDs (by context: appears after "References" section)
   - Bullet points: `•\s*(.+)`
- **Context**: Look for "References" section specifically; extract all lines until next section.
- **Validation**: Remove references that are too short (<5 chars) or are obviously not references (e.g., "Page X").
- **Deduplication**: Merge duplicate references.

### 8. Default Value Extraction

- **Specific Pattern**: Look for "Default Value:" or "Default:"
- **Table Extraction**: If default value is in a table, extract the corresponding cell.
- **Fallback**: Extract text after "Default Value" until next section.

### 9. Deduplication and Validation

- **CIS ID Uniqueness**: Store each CIS ID only once, preferring the extraction with highest confidence score
- **Confidence Scoring**: Based on:
  - Page number matches TOC
  - All required fields non-empty
  - Content length thresholds met
  - Section ordering correct
- **Validation Rules**:
  - CIS ID format must match `^\d+(\.\d+)+$`
  - Profile must be one of L1, L2, BL
  - Assessment status must be Automated or Manual
  - Page number must be within PDF page range

### 10. Handling of Special Formatting

- **Bullet Lists**: Detect lines starting with `•`, `-`, or `*` and preserve as separate items within content.
- **Numbered Lists**: Preserve numbering.
- **Indentation**: Use layout detection to identify nested structures.
- **Line Breaks**: Normalize excessive whitespace and line breaks.

## Detailed Algorithm Steps

### Step 1: PDF Loading and Text Extraction
```python
def extract_pdf_with_layout(pdf_path):
    with pdfplumber.open(pdf_path) as pdf:
        pages_data = []
        for page_num, page in enumerate(pdf.pages, 1):
            # Extract text with layout information
            text = page.extract_text()
            words = page.extract_words()
            tables = page.extract_tables()
            pages_data.append({
                'page_number': page_num,
                'text': text,
                'words': words,
                'tables': tables,
                'height': page.height,
                'width': page.width
            })
    return pages_data
```

### Step 2: TOC Extraction with Validation
- Parse first 50 pages for "Table of Contents"
- Use regex to capture CIS IDs and page numbers
- Apply page offset correction based on actual PDF pagination
- Validate each mapping by checking if CIS ID appears on that page

### Step 3: CIS Recommendation Detection
- Scan all pages for CIS ID patterns
- For each detected CIS ID, record page number and surrounding context
- Merge with TOC mappings (prioritize TOC but use content detection as fallback)

### Step 4: Recommendation Extraction
For each CIS ID:
1. **Locate Start Page**: Use mapping ±2 pages search
2. **Extract Block**: Gather text from start page and subsequent pages until termination condition
3. **Parse Sections**:
   - Split block by section headers using improved regex
   - For each section, extract content using boundary detection
4. **Extract Tables**: Identify tables within the block and map to default values/references
5. **Validate**: Check that required fields (cis_id, title, profile, assessment_status) are present
6. **Store**: Add to recommendations list if validation passes

### Step 5: Post-processing
- Remove duplicates (keep highest confidence)
- Fill missing fields with empty strings
- Trim whitespace and normalize formatting
- Generate summary statistics

### Step 6: Output Generation
- Save as JSON per section
- Generate validation report
- Log extraction metrics

## Performance Considerations

- **Caching**: Store extracted pages data to avoid re-extraction
- **Parallel Processing**: Process sections independently (since they're in different parts of PDF)
- **Memory Management**: Process PDF in chunks if memory is concern
- **Progress Tracking**: Log progress for large PDFs (~900 recommendations)
- **Optimized Regex**: Compile regex patterns once and reuse

## Maintainability Features

- **Configurable Patterns**: Store regex patterns in external configuration (YAML/JSON)
- **Modular Design**: Separate classes for TOC extraction, content extraction, validation, table parsing
- **Comprehensive Logging**: Log decisions for debugging with different log levels
- **Unit Tests**: Test each component with sample PDF pages
- **Validation Reports**: Generate detailed reports of extraction quality
- **Error Recovery**: Graceful handling of malformed pages with fallback strategies

## Validation and Quality Assurance

- **Automated Validation**:
  - Field completeness check
  - Page number accuracy (±2 pages)
  - Profile and assessment status consistency
  - Reference format validation
- **Manual Spot-Check**: Random sampling of 50 recommendations for human review
- **Comparison with Previous Extraction**: Ensure improvements by comparing key metrics (content completeness, duplicate count)
- **Regression Testing**: Ensure new changes don't break existing extractions

## Implementation Plan

1. **Phase 1**: Enhance TOC extraction and page mapping
2. **Phase 2**: Implement layout-aware text extraction
3. **Phase 3**: Develop improved regex patterns with fallbacks
4. **Phase 4**: Add multi-page recommendation handling
5. **Phase 5**: Implement table extraction and reference enhancement
6. **Phase 6**: Implement deduplication and validation
7. **Phase 7**: Create comprehensive testing suite
8. **Phase 8**: Performance optimization and integration

## Expected Outcomes

### Success Metrics
- **Content Completeness**: >90% of recommendations have non-empty description, rationale, impact
- **Page Accuracy**: >95% of page numbers correct within ±1 page
- **Duplicate Elimination**: Zero duplicate CIS IDs
- **Reference Extraction**: >80% of references correctly extracted
- **Default Value Extraction**: >70% of default values accurately captured
- **Performance**: Process entire PDF in <5 minutes

### Validation Approach
- Manual spot-check of 50 random recommendations
- Compare extracted data with PDF visual inspection
- Automated validation of field completeness and format

## Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| PDF format variations | Use multiple extraction strategies with fallbacks |
| Performance degradation | Implement caching and parallel processing |
| False positives in section detection | Add validation checks and confidence scoring |
| Memory issues with large PDF | Process in page batches |
| Table extraction failures | Fallback to regex patterns on flattened text |
| Incorrect reference parsing | Context-aware filtering (exclude CIS ID patterns) |

## Next Steps

1. Create detailed technical specification for each component
2. Implement prototype with key improvements
3. Test against current PDF and compare results
4. Iterate based on validation results

---
*This design document will be used as the blueprint for implementation in the next phase.*