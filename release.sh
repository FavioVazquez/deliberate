#!/usr/bin/env bash
set -euo pipefail

# deliberate -- Release script
# Usage: ./scripts/release.sh [patch|minor|major]
#
# This script:
# 1. Bumps the version in package.json
# 2. Updates CHANGELOG.md with the new version header
# 3. Commits the version bump
# 4. Creates a git tag
# 5. Pushes to origin with tags
# 6. Creates a GitHub release
# 7. Publishes to npm

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUMP_TYPE="${1:-patch}"

if [[ "$BUMP_TYPE" != "patch" && "$BUMP_TYPE" != "minor" && "$BUMP_TYPE" != "major" ]]; then
  echo "Usage: release.sh [patch|minor|major]"
  echo "  patch: 0.1.0 -> 0.1.1 (bug fixes)"
  echo "  minor: 0.1.0 -> 0.2.0 (new features, new agents)"
  echo "  major: 0.1.0 -> 1.0.0 (breaking changes)"
  exit 1
fi

cd "$ROOT_DIR"

# Pre-flight checks
echo "=== Pre-flight checks ==="

if [[ -n "$(git status --porcelain)" ]]; then
  echo "ERROR: Working directory is not clean. Commit or stash changes first."
  git status --short
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "ERROR: GitHub CLI (gh) is required. Install: https://cli.github.com"
  exit 1
fi

if ! command -v npm >/dev/null 2>&1; then
  echo "ERROR: npm is required."
  exit 1
fi

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [[ "$CURRENT_BRANCH" != "main" ]]; then
  echo "WARNING: You are on branch '$CURRENT_BRANCH', not 'main'."
  read -p "Continue? [y/N] " confirm
  [[ "$confirm" == "y" || "$confirm" == "Y" ]] || exit 1
fi

# Get current and new version
CURRENT_VERSION=$(node -p "require('./package.json').version")
echo "Current version: $CURRENT_VERSION"

# Bump version (npm version updates package.json and creates git tag)
NEW_VERSION=$(npm version "$BUMP_TYPE" --no-git-tag-version | sed 's/^v//')
echo "New version: $NEW_VERSION"

# Update CHANGELOG.md
DATE=$(date +%Y-%m-%d)
CHANGELOG_ENTRY="## [$NEW_VERSION] - $DATE"

if grep -q "## \[Unreleased\]" CHANGELOG.md 2>/dev/null; then
  # Replace [Unreleased] with the new version
  sed -i "s/## \[Unreleased\]/$CHANGELOG_ENTRY/" CHANGELOG.md
else
  # Insert new version header after the first ## line
  sed -i "/^## \[/i\\
\\n$CHANGELOG_ENTRY\\n" CHANGELOG.md
fi

echo ""
echo "=== CHANGELOG.md updated ==="
echo "Please review and add release notes to CHANGELOG.md before continuing."
echo "The new version header has been added. Add your changes under it."
echo ""
read -p "Open CHANGELOG.md for editing? [Y/n] " edit_changelog
if [[ "$edit_changelog" != "n" && "$edit_changelog" != "N" ]]; then
  ${EDITOR:-vi} CHANGELOG.md
fi

# Commit and tag
echo ""
echo "=== Committing and tagging ==="
git add package.json CHANGELOG.md
git commit -m "release: v$NEW_VERSION"
git tag -a "v$NEW_VERSION" -m "Release v$NEW_VERSION"

# Push
echo ""
echo "=== Pushing to origin ==="
git push origin "$CURRENT_BRANCH"
git push origin "v$NEW_VERSION"

# Create GitHub release
echo ""
echo "=== Creating GitHub release ==="

# Extract changelog for this version
RELEASE_NOTES=$(awk "/^## \[$NEW_VERSION\]/{found=1; next} /^## \[/{if(found) exit} found{print}" CHANGELOG.md)

if [[ -z "$RELEASE_NOTES" ]]; then
  RELEASE_NOTES="Release v$NEW_VERSION"
fi

gh release create "v$NEW_VERSION" \
  --title "v$NEW_VERSION" \
  --notes "$RELEASE_NOTES"

# Publish to npm
echo ""
echo "=== Publishing to npm ==="
read -p "Publish to npm? [Y/n] " publish
if [[ "$publish" != "n" && "$publish" != "N" ]]; then
  npm publish
  echo ""
  echo "Published! Users can now run: npx deliberate"
else
  echo "Skipped npm publish. Run 'npm publish' manually when ready."
fi

echo ""
echo "=== Release v$NEW_VERSION complete ==="
echo "  Git tag: v$NEW_VERSION"
echo "  GitHub: https://github.com/FavioVazquez/deliberate/releases/tag/v$NEW_VERSION"
echo "  npm: https://www.npmjs.com/package/deliberate"
