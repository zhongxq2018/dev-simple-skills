#!/bin/bash
set -e

SKILLS_DIR="$HOME/.claude/skills"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Determine source: local skills/ dir or download from GitHub
if [ -d "$SCRIPT_DIR/skills" ]; then
  SOURCE_DIR="$SCRIPT_DIR/skills"
  echo "Installing from local directory..."
else
  REPO_URL="https://github.com/zhongxq2018/dev-simple-skills"
  TMP_DIR=$(mktemp -d)
  echo "Downloading from $REPO_URL..."
  if command -v git &>/dev/null; then
    git clone --depth 1 "$REPO_URL" "$TMP_DIR" 2>/dev/null
  else
    curl -fsSL "$REPO_URL/archive/refs/heads/main.zip" -o "$TMP_DIR/repo.zip"
    unzip -q "$TMP_DIR/repo.zip" -d "$TMP_DIR"
    mv "$TMP_DIR"/dev-simple-skills-*/* "$TMP_DIR"/
  fi
  SOURCE_DIR="$TMP_DIR/skills"
fi

mkdir -p "$SKILLS_DIR"

for skill_dir in "$SOURCE_DIR"/*/; do
  skill_name=$(basename "$skill_dir")
  echo "  Installing: $skill_name"
  cp -r "$skill_dir" "$SKILLS_DIR/$skill_name"
done

echo ""
echo "Done! Installed skills to $SKILLS_DIR"
echo "Restart Claude Code to use the new skills."
