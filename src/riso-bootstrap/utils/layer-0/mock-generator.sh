#!/bin/bash

# ----------------------------------------
# utils/layer-0/mock-generator.sh - Generate mock files for testing
# ----------------------------------------

# Function to generate mock Python project for Serena testing
generate_mock_python_project() {
    local project_path="${1:-.}"

    # Create main Python file
    cat > "$project_path/main.py" << 'EOF'
#!/usr/bin/env python3
"""Mock Python application for testing Serena semantic analysis"""

from typing import List, Optional
import json

class DataProcessor:
    """Process data with various methods"""

    def __init__(self, name: str):
        self.name = name
        self.data: List[dict] = []

    def add_data(self, item: dict) -> None:
        """Add item to data collection"""
        self.data.append(item)

    def process(self) -> dict:
        """Process all data and return summary"""
        return {
            "processor": self.name,
            "count": len(self.data),
            "data": self.data
        }

def calculate_sum(numbers: List[int]) -> int:
    """Calculate sum of numbers"""
    return sum(numbers)

def find_max(numbers: List[int]) -> Optional[int]:
    """Find maximum value in list"""
    return max(numbers) if numbers else None

def main():
    """Main entry point"""
    processor = DataProcessor("TestProcessor")
    processor.add_data({"id": 1, "value": "test"})
    result = processor.process()
    print(json.dumps(result, indent=2))

    numbers = [1, 2, 3, 4, 5]
    print(f"Sum: {calculate_sum(numbers)}")
    print(f"Max: {find_max(numbers)}")

if __name__ == "__main__":
    main()
EOF

    # Create utils module
    mkdir -p "$project_path/utils"
    cat > "$project_path/utils/__init__.py" << 'EOF'
"""Utilities module for mock project"""
EOF

    cat > "$project_path/utils/helpers.py" << 'EOF'
"""Helper functions for testing"""

def format_string(text: str) -> str:
    """Format string for display"""
    return text.strip().title()

def validate_input(value: any) -> bool:
    """Validate input value"""
    return value is not None and value != ""
EOF

    # Create test file
    cat > "$project_path/test_main.py" << 'EOF'
#!/usr/bin/env python3
"""Test file for mock project"""

import unittest
from main import DataProcessor, calculate_sum, find_max

class TestDataProcessor(unittest.TestCase):
    def test_add_data(self):
        processor = DataProcessor("Test")
        processor.add_data({"test": "data"})
        self.assertEqual(len(processor.data), 1)

    def test_calculate_sum(self):
        self.assertEqual(calculate_sum([1, 2, 3]), 6)

    def test_find_max(self):
        self.assertEqual(find_max([1, 5, 3]), 5)
        self.assertIsNone(find_max([]))

if __name__ == "__main__":
    unittest.main()
EOF

    # Create README
    cat > "$project_path/README.md" << 'EOF'
# Mock Test Project

This is a mock Python project generated for testing Serena code analysis capabilities.

## Structure
- `main.py` - Main application file
- `utils/` - Utility modules
- `test_main.py` - Unit tests

## Purpose
Used for testing the riso-bootstrap devcontainer feature with Serena integration.
EOF

    # Create requirements.txt
    cat > "$project_path/requirements.txt" << 'EOF'
# Mock requirements for testing
pytest>=7.0.0
black>=22.0.0
mypy>=0.900
EOF

    return 0
}
