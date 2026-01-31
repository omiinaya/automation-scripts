#!/usr/bin/env python3
"""
CIS JSON Configuration Consolidation Script

This script consolidates individual CIS JSON configuration files into logical groupings,
reducing file count and eliminating redundancy.

Usage:
    python helpers/consolidate_json.py

The script will:
1. Read all individual JSON files from docs/json/
2. Merge them into 8-10 logical groupings
3. Extract common CIS Controls to cis_references.json
4. Add metadata fields to each consolidated file
5. Validate the consolidated JSON structure
"""

import json
import os
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Any
import re


class CISConsolidator:
    """Consolidates CIS JSON configuration files into logical groupings."""
    
    def __init__(self, source_dir: str, output_dir: str):
        self.source_dir = Path(source_dir)
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
        # Metadata for consolidated files
        self.metadata = {
            "last_updated": datetime.utcnow().isoformat() + "Z",
            "os_version": "Windows 11",
            "benchmark_version": "4.0.0"
        }
        
        # Define consolidation mappings
        self.consolidation_map = {
            "cis_account_policies.json": {
                "description": "Password and lockout policies (Sections 1.x)",
                "sections": ["1_1", "1_2"],
                "source_files": ["cis_section_1_1.json", "cis_section_1_2.json"]
            },
            "cis_user_rights_assignment.json": {
                "description": "User rights assignment (Sections 2.2.x)",
                "sections": ["2_1", "2_2", "2_3", "2_4"],
                "source_files": [
                    "cis_section_2_1.json",
                    "cis_section_2_2.json",
                    "cis_section_2_3.json",
                    "cis_section_2_4.json"
                ]
            },
            "cis_security_options.json": {
                "description": "Security options (Sections 2.3.x)",
                "sections": ["2_6", "2_8", "2_9"],
                "source_files": [
                    "cis_section_2_6.json",
                    "cis_section_2_8.json",
                    "cis_section_2_9.json"
                ]
            },
            "cis_services.json": {
                "description": "Service configurations (Section 5.x)",
                "sections": ["5_1", "5_2", "5_3", "5_4", "5_5"],
                "source_files": [
                    "cis_section_5_1.json",
                    "cis_section_5_2.json",
                    "cis_section_5_3.json",
                    "cis_section_5_4.json",
                    "cis_section_5_5.json"
                ]
            },
            "cis_firewall.json": {
                "description": "Firewall settings (Section 9.x)",
                "sections": ["9_1", "9_2"],
                "source_files": ["cis_section_9_1.json", "cis_section_9_2.json"]
            },
            "cis_audit_policies.json": {
                "description": "Audit policies (Section 17.x)",
                "sections": ["17_1", "17_2", "17_3"],
                "source_files": [
                    "cis_section_17_1.json",
                    "cis_section_17_2.json",
                    "cis_section_17_3.json"
                ]
            },
            "cis_security_settings.json": {
                "description": "Security settings (Section 18.x)",
                "sections": [
                    "18_1", "18_2", "18_3", "18_4", "18_5", "18_6",
                    "18_7", "18_8", "18_9", "18_10", "18_11", "18_12",
                    "18_13", "18_14", "18_15", "18_16", "18_17", "18_18",
                    "18_19", "18_20", "18_21", "18_22", "18_23", "18_24",
                    "18_25", "18_26", "18_27", "18_28", "18_29", "18_30",
                    "18_31", "18_32"
                ],
                "source_files": [
                    f"cis_section_18_{i}.json" for i in range(1, 33)
                ]
            },
            "cis_user_configuration.json": {
                "description": "User configuration (Section 19.x)",
                "sections": ["19_1", "19_2"],
                "source_files": ["cis_section_19_1.json", "cis_section_19_2.json"]
            }
        }
        
        # Track all CIS Controls for references file
        self.cis_controls: Dict[str, Any] = {}
    
    def read_json_file(self, filepath: Path) -> List[Dict[str, Any]]:
        """Read and parse a JSON file."""
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                return json.load(f)
        except FileNotFoundError:
            print(f"Warning: File not found: {filepath}")
            return []
        except json.JSONDecodeError as e:
            print(f"Error parsing JSON in {filepath}: {e}")
            return []
    
    def extract_cis_controls(self, recommendations: List[Dict[str, Any]]) -> None:
        """Extract CIS Controls from recommendations and store them."""
        for rec in recommendations:
            if "default_value" in rec:
                # Parse CIS Controls from default_value field
                default_value = rec["default_value"]
                
                # Look for CIS Controls section
                if "CIS Controls:" in default_value:
                    # Extract the CIS Controls section
                    controls_section = default_value.split("CIS Controls:")[-1].strip()
                    
                    # Parse individual controls
                    control_pattern = r'(\d+\.\d+)\s+(.+?)(?=\n\d+\.\d+|\nReferences:|$)'
                    matches = re.findall(control_pattern, controls_section, re.DOTALL)
                    
                    for control_id, control_text in matches:
                        control_id = control_id.strip()
                        control_text = control_text.strip()
                        
                        # Parse IG levels
                        ig_pattern = r'v(\d+)\s+([●\s]+)'
                        ig_matches = re.findall(ig_pattern, control_text)
                        
                        ig_levels = {}
                        for version, ig_str in ig_matches:
                            # Count the bullets for IG levels
                            bullets = ig_str.count('●')
                            ig_levels[f"IG{version}"] = bullets > 0
                        
                        # Extract control name (first line)
                        control_name = control_text.split('\n')[0].strip()
                        
                        if control_id not in self.cis_controls:
                            self.cis_controls[control_id] = {
                                "id": control_id,
                                "name": control_name,
                                "ig_levels": ig_levels,
                                "recommendations": []
                            }
                        
                        # Add recommendation reference
                        self.cis_controls[control_id]["recommendations"].append({
                            "cis_id": rec.get("cis_id"),
                            "title": rec.get("title")
                        })
    
    def create_consolidated_file(self, output_filename: str, config: Dict[str, Any]) -> bool:
        """Create a consolidated JSON file from multiple source files."""
        recommendations = []
        
        # Read all source files
        for source_file in config["source_files"]:
            source_path = self.source_dir / source_file
            if source_path.exists():
                data = self.read_json_file(source_path)
                recommendations.extend(data)
                print(f"  - Read {len(data)} recommendations from {source_file}")
            else:
                print(f"  - Warning: Source file not found: {source_file}")
        
        if not recommendations:
            print(f"  - No recommendations found for {output_filename}")
            return False
        
        # Extract CIS Controls
        self.extract_cis_controls(recommendations)
        
        # Create consolidated structure
        consolidated = {
            "metadata": {
                **self.metadata,
                "description": config["description"],
                "sections_covered": config["sections"],
                "total_recommendations": len(recommendations)
            },
            "recommendations": recommendations
        }
        
        # Write consolidated file
        output_path = self.output_dir / output_filename
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(consolidated, f, indent=2, ensure_ascii=False)
        
        print(f"  - Created {output_filename} with {len(recommendations)} recommendations")
        return True
    
    def create_references_file(self) -> bool:
        """Create the CIS references file with extracted controls."""
        if not self.cis_controls:
            print("  - No CIS Controls found to create references file")
            return False
        
        # Sort controls by ID
        sorted_controls = sorted(self.cis_controls.values(), key=lambda x: x["id"])
        
        references = {
            "metadata": {
                **self.metadata,
                "description": "Shared CIS Controls references",
                "total_controls": len(sorted_controls)
            },
            "cis_controls": sorted_controls
        }
        
        output_path = self.output_dir / "cis_references.json"
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(references, f, indent=2, ensure_ascii=False)
        
        print(f"  - Created cis_references.json with {len(sorted_controls)} controls")
        return True
    
    def validate_consolidated_file(self, filepath: Path) -> bool:
        """Validate a consolidated JSON file structure."""
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            # Check required fields
            if "metadata" not in data:
                print(f"  - Error: Missing 'metadata' field in {filepath}")
                return False
            
            if "recommendations" not in data:
                print(f"  - Error: Missing 'recommendations' field in {filepath}")
                return False
            
            # Check metadata fields
            required_metadata = ["last_updated", "os_version", "benchmark_version"]
            for field in required_metadata:
                if field not in data["metadata"]:
                    print(f"  - Error: Missing metadata field '{field}' in {filepath}")
                    return False
            
            # Validate recommendations
            for i, rec in enumerate(data["recommendations"]):
                if "cis_id" not in rec:
                    print(f"  - Error: Recommendation {i} missing 'cis_id' in {filepath}")
                    return False
            
            print(f"  - Validation passed for {filepath.name}")
            return True
            
        except json.JSONDecodeError as e:
            print(f"  - Error: Invalid JSON in {filepath}: {e}")
            return False
        except Exception as e:
            print(f"  - Error validating {filepath}: {e}")
            return False
    
    def run(self) -> None:
        """Run the consolidation process."""
        print("=" * 60)
        print("CIS JSON Configuration Consolidation")
        print("=" * 60)
        print()
        
        # Create all consolidated files
        print("Creating consolidated files...")
        for filename, config in self.consolidation_map.items():
            print(f"\nProcessing {filename}:")
            self.create_consolidated_file(filename, config)
        
        # Create references file
        print("\nCreating CIS references file:")
        self.create_references_file()
        
        # Validate all consolidated files
        print("\nValidating consolidated files...")
        all_valid = True
        for filename in self.consolidation_map.keys():
            filepath = self.output_dir / filename
            if filepath.exists():
                if not self.validate_consolidated_file(filepath):
                    all_valid = False
        
        # Validate references file
        references_path = self.output_dir / "cis_references.json"
        if references_path.exists():
            if not self.validate_consolidated_file(references_path):
                all_valid = False
        
        print()
        print("=" * 60)
        if all_valid:
            print("✓ Consolidation completed successfully!")
        else:
            print("✗ Consolidation completed with validation errors")
        print("=" * 60)
        print(f"\nOutput directory: {self.output_dir.absolute()}")
        print(f"Total files created: {len(list(self.output_dir.glob('*.json')))}")


def main():
    """Main entry point."""
    # Get script directory and project root
    script_dir = Path(__file__).parent
    project_root = script_dir.parent
    
    # Define source and output directories
    source_dir = project_root / "docs" / "json"
    output_dir = project_root / "docs" / "json" / "consolidated"
    
    # Run consolidation
    consolidator = CISConsolidator(str(source_dir), str(output_dir))
    consolidator.run()


if __name__ == "__main__":
    main()
