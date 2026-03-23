BUMP_SCRIPT := scripts/bump_version.sh

.PHONY: bump bump-patch bump-minor bump-major \
        bump-alpha bump-minor-alpha bump-major-alpha \
        bump-beta  bump-minor-beta  bump-major-beta  \
        version

## Show current version (latest stable semver tag)
version:
	@git tag --list '[0-9]*.[0-9]*.[0-9]*' \
	  | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$$' \
	  | sort -t. -k1,1n -k2,2n -k3,3n \
	  | tail -n1 \
	  | { read v; [ -n "$$v" ] && echo "$$v" || echo "(no tag yet)"; }

# --- stable -----------------------------------------------------------------
bump bump-patch:
	@bash $(BUMP_SCRIPT) patch

bump-minor:
	@bash $(BUMP_SCRIPT) minor

bump-major:
	@bash $(BUMP_SCRIPT) major

# --- alpha ------------------------------------------------------------------
bump-alpha:
	@bash $(BUMP_SCRIPT) patch alpha

bump-minor-alpha:
	@bash $(BUMP_SCRIPT) minor alpha

bump-major-alpha:
	@bash $(BUMP_SCRIPT) major alpha

# --- beta -------------------------------------------------------------------
bump-beta:
	@bash $(BUMP_SCRIPT) patch beta

bump-minor-beta:
	@bash $(BUMP_SCRIPT) minor beta

bump-major-beta:
	@bash $(BUMP_SCRIPT) major beta
