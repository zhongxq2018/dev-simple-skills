#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# --- Determine source directory ---
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

# --- Collect available skills ---
skills=()
descriptions=()
for skill_dir in "$SOURCE_DIR"/*/; do
  [ -d "$skill_dir" ] || continue
  skill_name=$(basename "$skill_dir")
  skills+=("$skill_name")

  # Extract description from SKILL.md frontmatter
  desc=""
  if [ -f "$skill_dir/SKILL.md" ]; then
    desc=$(sed -n 's/^description: *//p' "$skill_dir/SKILL.md" | head -1)
  fi
  descriptions+=("${desc:-No description}")
done

if [ ${#skills[@]} -eq 0 ]; then
  echo "No skills found in $SOURCE_DIR"
  exit 1
fi

# --- Parse flags ---
install_all=false
for arg in "$@"; do
  case "$arg" in
    --all) install_all=true ;;
    *)     echo "Unknown option: $arg"; echo "Usage: $0 [--all]"; exit 1 ;;
  esac
done

# --- Select skills to install ---
selected_indices=()

if [ "$install_all" = true ]; then
  # Non-interactive: install all
  for i in "${!skills[@]}"; do
    selected_indices+=($i)
  done
elif [ ! -t 0 ]; then
  # Piped mode (curl | bash) without --all
  echo ""
  echo "Non-interactive mode detected. Use --all to install all skills:"
  echo "  curl -fsSL ... | bash -s -- --all"
  echo ""
  echo "Or download and run interactively:"
  echo "  git clone https://github.com/zhongxq2018/dev-simple-skills.git"
  echo "  cd dev-simple-skills && ./install.sh"
  exit 1
else
  # Interactive selection
  echo ""
  echo "Available skills:"
  echo ""
  echo "  [0] All"
  for i in "${!skills[@]}"; do
    echo "  [$((i + 1))] ${skills[$i]} — ${descriptions[$i]}"
  done
  echo ""

  while true; do
    read -rp "Enter skill numbers to install (e.g., 1 2 or 0 for all): " -a input

    # Empty input
    if [ ${#input[@]} -eq 0 ]; then
      echo "Please enter at least one number."
      continue
    fi

    # Check for "all"
    for num in "${input[@]}"; do
      if [ "$num" = "0" ]; then
        for i in "${!skills[@]}"; do
          selected_indices+=($i)
        done
        break 2
      fi
    done

    # Validate and collect selections
    valid=true
    temp_indices=()
    for num in "${input[@]}"; do
      if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le ${#skills[@]} ]; then
        temp_indices+=($((num - 1)))
      else
        echo "Invalid number: $num (valid range: 0-${#skills[@]})"
        valid=false
        break
      fi
    done

    if [ "$valid" = true ]; then
      selected_indices=("${temp_indices[@]}")
      break
    fi
  done
fi

# --- Install location (global only) ---
SKILLS_DIR="$HOME/.claude/skills"

# --- Install selected skills ---
mkdir -p "$SKILLS_DIR"

echo ""
for idx in "${selected_indices[@]}"; do
  skill_name="${skills[$idx]}"
  echo "  Installing: $skill_name"
  cp -r "$SOURCE_DIR/$skill_name" "$SKILLS_DIR/$skill_name"
done

echo ""
echo "Done! Installed ${#selected_indices[@]} skill(s) to $SKILLS_DIR"
echo "Restart Claude Code to use the new skills."
