#!/usr/bin/env python3
"""
Automated Changelog & Release Notes Generator for Badil (بَديل)
Parses git commits between tags, categorizes changes by Conventional Commits,
updates CHANGELOG.md, and produces RELEASE_NOTES.md for GitHub Releases.

Usage:
    python3 tool/update_changelog.py [version_tag]
"""

import os
import re
import subprocess
import sys
from datetime import datetime

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(SCRIPT_DIR)
CHANGELOG_PATH = os.path.join(PROJECT_ROOT, "CHANGELOG.md")
RELEASE_NOTES_PATH = os.path.join(PROJECT_ROOT, "RELEASE_NOTES.md")


def get_git_tags() -> list[str]:
    """Return all git tags sorted from newest to oldest."""
    try:
        output = subprocess.check_output(
            ["git", "tag", "--sort=-creatordate"],
            cwd=PROJECT_ROOT,
            stderr=subprocess.DEVNULL,
        ).decode().strip()
        return [t.strip() for t in output.splitlines() if t.strip()]
    except Exception:
        return []


def get_commits_between(start_tag: str | None, end_ref: str = "HEAD") -> list[tuple[str, str]]:
    """Return list of (subject, hash) between start_tag and end_ref."""
    rev_range = f"{start_tag}..{end_ref}" if start_tag else end_ref
    try:
        output = subprocess.check_output(
            ["git", "log", rev_range, "--pretty=format:%s|%h"],
            cwd=PROJECT_ROOT,
            stderr=subprocess.DEVNULL,
        ).decode().strip()
        commits = []
        for line in output.splitlines():
            if not line.strip() or "|" not in line:
                continue
            subject, chash = line.split("|", 1)
            commits.append((subject.strip(), chash.strip()))
        return commits
    except Exception:
        return []


def classify_commits(commits: list[tuple[str, str]]):
    """Categorize commits into conventional groups."""
    added = []
    fixed = []
    changed = []
    docs = []

    skip_patterns = [
        r"^merge\b",
        r"^\[skip ci\]",
        r"^bump version",
        r"^chore\(release\)",
    ]

    for subj, chash in commits:
        if any(re.search(pat, subj, re.IGNORECASE) for pat in skip_patterns):
            continue

        clean_subj = subj
        m = re.match(r"^([a-zA-Z0-9_\-]+)(?:\((.*?)\))?:\s*(.*)$", subj)
        if m:
            ctype = m.group(1).lower()
            scope = m.group(2)
            desc = m.group(3)
            scope_prefix = f"**{scope}**: " if scope else ""
            clean_subj = f"{scope_prefix}{desc[0].upper() + desc[1:] if desc else ''}"
        else:
            ctype = "other"

        entry = f"{clean_subj} (`{chash}`)"

        if ctype in ("feat", "add"):
            added.append(entry)
        elif ctype in ("fix", "bug", "patch"):
            fixed.append(entry)
        elif ctype in ("docs", "doc"):
            docs.append(entry)
        else:
            changed.append(entry)

    return added, fixed, changed, docs


def build_markdown_section(version: str, date_str: str, added, fixed, changed, docs) -> str:
    """Build markdown section for CHANGELOG.md."""
    clean_ver = version.lstrip("v")
    lines = [f"## [{clean_ver}] - {date_str}", ""]

    if added:
        lines.append("### Added")
        for item in added:
            lines.append(f"- {item}")
        lines.append("")

    if fixed:
        lines.append("### Fixed")
        for item in fixed:
            lines.append(f"- {item}")
        lines.append("")

    if changed:
        lines.append("### Changed")
        for item in changed:
            lines.append(f"- {item}")
        lines.append("")

    if docs:
        lines.append("### Documentation")
        for item in docs:
            lines.append(f"- {item}")
        lines.append("")

    # Fallback if no categorized commits
    if not (added or fixed or changed or docs):
        lines.append("- Maintenance updates, dependencies and performance optimizations.")
        lines.append("")

    return "\n".join(lines)


def build_release_notes(version: str, added, fixed, changed, docs) -> str:
    """Build formatted release notes for GitHub Releases."""
    lines = [f"## Badil {version} Release 🇪🇬", ""]

    if added:
        lines.append("### ✨ New Features")
        for item in added:
            lines.append(f"- {item}")
        lines.append("")

    if fixed:
        lines.append("### 🐛 Bug Fixes")
        for item in fixed:
            lines.append(f"- {item}")
        lines.append("")

    if changed:
        lines.append("### ⚡ Improvements & Maintenance")
        for item in changed:
            lines.append(f"- {item}")
        lines.append("")

    if docs:
        lines.append("### 📚 Documentation")
        for item in docs:
            lines.append(f"- {item}")
        lines.append("")

    lines.append("---")
    lines.append("### 📦 Download Assets")
    lines.append(f"- **`Badil-{version}-arm64.apk`**: Optimized for 64-bit Android devices (phones & tablets).")
    lines.append(f"- **`Badil-{version}-universal.apk`**: Compatible with all supported Android architectures.")
    lines.append("")

    return "\n".join(lines)


def update_changelog_file(version: str, new_section: str):
    """Insert new section into CHANGELOG.md right below header if not already present."""
    clean_ver = version.lstrip("v")
    target_header = f"## [{clean_ver}]"

    if not os.path.exists(CHANGELOG_PATH):
        content = (
            "# Changelog\n\n"
            "All notable changes to the **Badil (بَديل)** project will be documented in this file.\n\n"
            "The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),\n"
            "and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).\n\n"
            "---\n\n"
            f"{new_section}\n"
        )
        with open(CHANGELOG_PATH, "w", encoding="utf-8") as f:
            f.write(content)
        print(f"Created {CHANGELOG_PATH}")
        return

    with open(CHANGELOG_PATH, "r", encoding="utf-8") as f:
        existing = f.read()

    if target_header in existing:
        print(f"Version {target_header} already exists in CHANGELOG.md; skipping file update.")
        return

    # Insert below the first '---'
    divider = "---\n\n"
    if divider in existing:
        prefix, suffix = existing.split(divider, 1)
        updated = f"{prefix}{divider}{new_section}\n---\n\n{suffix}"
    else:
        updated = f"{existing}\n\n---\n\n{new_section}\n"

    with open(CHANGELOG_PATH, "w", encoding="utf-8") as f:
        f.write(updated)
    print(f"Updated {CHANGELOG_PATH} with {version}")


def main():
    version_arg = sys.argv[1] if len(sys.argv) > 1 else None
    tags = get_git_tags()

    if version_arg:
        current_version = version_arg
    elif tags:
        current_version = tags[0]
    else:
        current_version = "v1.1.0"

    # Identify previous tag
    previous_tag = None
    if tags:
        try:
            curr_idx = tags.index(current_version)
            if curr_idx + 1 < len(tags):
                previous_tag = tags[curr_idx + 1]
        except ValueError:
            # If current_version is not a pushed tag yet, use newest tag as previous
            previous_tag = tags[0]

    print(f"Generating changelog for: {current_version} (previous: {previous_tag})")
    commits = get_commits_between(previous_tag, current_version if current_version in tags else "HEAD")
    added, fixed, changed, docs = classify_commits(commits)

    today = datetime.now().strftime("%Y-%m-%d")
    md_section = build_markdown_section(current_version, today, added, fixed, changed, docs)
    release_notes = build_release_notes(current_version, added, fixed, changed, docs)

    # Write RELEASE_NOTES.md
    with open(RELEASE_NOTES_PATH, "w", encoding="utf-8") as f:
        f.write(release_notes)
    print(f"Wrote release notes to {RELEASE_NOTES_PATH}")

    # Update CHANGELOG.md
    update_changelog_file(current_version, md_section)


if __name__ == "__main__":
    main()
