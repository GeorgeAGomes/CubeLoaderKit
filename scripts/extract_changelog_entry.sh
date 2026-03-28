#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# extract_changelog_entry.sh — prints the body of a CHANGELOG section
# Usage: extract_changelog_entry.sh <version>
# ---------------------------------------------------------------------------

VERSION="${1:-}"

if [[ -z "$VERSION" ]]; then
  echo "error: missing version. usage: extract_changelog_entry.sh <version>" >&2
  exit 1
fi

if [[ ! -f CHANGELOG.md ]]; then
  echo "error: CHANGELOG.md not found." >&2
  exit 1
fi

ENTRY=$(
  awk -v version="$VERSION" '
    BEGIN { found = 0 }
    /^## \[/ {
      if (found) {
        exit
      }
      if (index($0, "## [" version "]") == 1) {
        found = 1
        next
      }
    }
    found { print }
  ' CHANGELOG.md
)

if [[ -z "${ENTRY//[$' \t\r\n']}" ]]; then
  echo "error: no changelog entry found for version '$VERSION'." >&2
  exit 1
fi

printf '%s\n' "$ENTRY"
