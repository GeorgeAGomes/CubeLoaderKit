#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# bump_version.sh — semver bump using Git tags as source of truth
# Usage: bump_version.sh [patch|minor|major] [alpha|beta|""]
# ---------------------------------------------------------------------------

BUMP="${1:-patch}"
PRE="${2:-}"   # e.g. "alpha", "beta", or "" for stable
CHANGELOG_SCRIPT="scripts/extract_changelog_entry.sh"

# --- validate working tree ---------------------------------------------------
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "error: working tree is not clean. commit or stash your changes first." >&2
  exit 1
fi

# --- discover latest stable semver tag (X.Y.Z only) -------------------------
LATEST=$(git tag --list '[0-9]*.[0-9]*.[0-9]*' \
           | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' \
           | sort -t. -k1,1n -k2,2n -k3,3n \
           | tail -n1 || true)

if [[ -z "$LATEST" ]]; then
  LATEST="0.0.0"
  echo "no existing semver tag found — starting from 0.0.0"
fi

IFS='.' read -r MAJOR MINOR PATCH <<< "$LATEST"

# --- bump -------------------------------------------------------------------
case "$BUMP" in
  major) MAJOR=$((MAJOR + 1)); MINOR=0; PATCH=0 ;;
  minor) MINOR=$((MINOR + 1)); PATCH=0 ;;
  patch) PATCH=$((PATCH + 1)) ;;
  *)
    echo "error: unknown bump type '$BUMP'. use patch, minor, or major." >&2
    exit 1 ;;
esac

BASE="${MAJOR}.${MINOR}.${PATCH}"

# --- resolve pre-release tag (auto-increment N in X.Y.Z-pre.N) --------------
if [[ -n "$PRE" ]]; then
  # find highest existing X.Y.Z-pre.N
  LAST_N=$(git tag --list "${BASE}-${PRE}.*" \
             | grep -E "^${BASE}-${PRE}\.[0-9]+$" \
             | sed "s/^${BASE}-${PRE}\.//" \
             | sort -n \
             | tail -n1 || true)
  N=$(( ${LAST_N:-0} + 1 ))
  NEW_TAG="${BASE}-${PRE}.${N}"
else
  NEW_TAG="${BASE}"
fi

if [[ ! -x "$CHANGELOG_SCRIPT" ]]; then
  echo "error: missing executable ${CHANGELOG_SCRIPT}." >&2
  exit 1
fi

if ! RELEASE_NOTES="$("$CHANGELOG_SCRIPT" "$NEW_TAG")"; then
  exit 1
fi

echo "current: ${LATEST}"
echo "new:     ${NEW_TAG}  (${BUMP} bump${PRE:+ / ${PRE}})"
echo "notes:   changelog entry found for ${NEW_TAG}"

# --- create and push tag -----------------------------------------------------
git tag "$NEW_TAG"
git push origin "$NEW_TAG"
echo "tag '$NEW_TAG' created and pushed."
echo "GitHub Release will be created from CHANGELOG.md for '$NEW_TAG'."
