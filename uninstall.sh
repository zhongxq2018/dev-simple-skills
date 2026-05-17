#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# --- Parse flags ---
uninstall_all=false
uninstall_local=false
for arg in "$@"; do
  case "$arg" in
    --all)   uninstall_all=true ;;
    --local) uninstall_local=true ;;
    *)       echo "Unknown option: $arg"; echo "Usage: $0 [--all] [--local]"; exit 1 ;;
  esac
done

# --- Determine scan locations ---
GLOBAL_DIR="$HOME/.claude/skills"
LOCAL_DIR="$SCRIPT_DIR/.claude/skills"

scan_dirs=()
if [ "$uninstall_local" = true ]; then
  scan_dirs+=("$LOCAL_DIR")
elif [ ! -t 0 ]; then
  scan_dirs+=("$GLOBAL_DIR")
else
  echo ""
  echo "Uninstall from:"
  echo "  [1] Global (~/.claude/skills)"
  echo "  [2] Local  (.claude/skills)"
  echo ""

  while true; do
    read -rp "Choose (1/2) [1]: " loc_choice
    loc_choice="${loc_choice:-1}"
    case "$loc_choice" in
      1) scan_dirs+=("$GLOBAL_DIR"); break ;;
      2) scan_dirs+=("$LOCAL_DIR"); break ;;
      *) echo "Please enter 1 or 2." ;;
    esac
  done
fi

# --- Collect project's own skills ---
PROJECT_SKILLS_DIR="$SCRIPT_DIR/skills"
project_skills=()
if [ -d "$PROJECT_SKILLS_DIR" ]; then
  for skill_dir in "$PROJECT_SKILLS_DIR"/*/; do
    [ -d "$skill_dir" ] || continue
    project_skills+=("$(basename "$skill_dir")")
  done
fi

# --- Collect installed skills (only those belonging to this project) ---
skills=()
for dir in "${scan_dirs[@]}"; do
  [ -d "$dir" ] || continue
  for ps in "${project_skills[@]}"; do
    if [ -d "$dir/$ps" ]; then
      # Avoid duplicates
      already=false
      for s in "${skills[@]}"; do
        [ "$s" = "$ps" ] && already=true && break
      done
      [ "$already" = false ] && skills+=("$ps")
    fi
  done
done

if [ ${#skills[@]} -eq 0 ]; then
  echo "No installed skills found."
  exit 0
fi

# --- Select skills to uninstall ---
selected_indices=()

if [ "$uninstall_all" = true ]; then
  for i in "${!skills[@]}"; do
    selected_indices+=($i)
  done
elif [ ! -t 0 ]; then
  echo ""
  echo "Non-interactive mode detected. Use --all to uninstall all skills:"
  echo "  ./uninstall.sh --all"
  exit 1
else
  echo ""
  echo "Installed skills:"
  echo ""
  echo "  [0] All"
  for i in "${!skills[@]}"; do
    echo "  [$((i + 1))] ${skills[$i]}"
  done
  echo ""

  while true; do
    read -rp "Enter skill numbers to uninstall (e.g., 1 2 or 0 for all): " -a input

    if [ ${#input[@]} -eq 0 ]; then
      echo "Please enter at least one number."
      continue
    fi

    for num in "${input[@]}"; do
      if [ "$num" = "0" ]; then
        for i in "${!skills[@]}"; do
          selected_indices+=($i)
        done
        break 2
      fi
    done

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

# --- Uninstall selected skills ---
echo ""
for idx in "${selected_indices[@]}"; do
  skill_name="${skills[$idx]}"
  removed=false
  for dir in "${scan_dirs[@]}"; do
    target="$dir/$skill_name"
    if [ -d "$target" ]; then
      rm -rf "$target"
      echo "  Removed: $target"
      removed=true
    fi
  done
  if [ "$removed" = false ]; then
    echo "  Not found: $skill_name"
  fi
done

echo ""
echo "Done! Uninstalled ${#selected_indices[@]} skill(s)."
