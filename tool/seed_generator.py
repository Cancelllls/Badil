#!/usr/bin/env python3
"""
Seed Database Generator for Badil (بَديل)
Delegates to `import_open_data.py` to compile `assets/database/badil_seed.db`
with SQLite FTS5 enabled, containing open boycott datasets (TechForPalestine),
GS1 country prefixes, and curated Egyptian & Arab alternatives with bilingual support.
"""

import os
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
if SCRIPT_DIR not in sys.path:
    sys.path.insert(0, SCRIPT_DIR)

from import_open_data import build_database

if __name__ == "__main__":
    build_database()
