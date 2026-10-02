#!/bin/bash
# Starship-like status line: dir, git branch, node/java (project-gated), model, context %
input=$(cat)
IFS=$'\t' read -r cwd model used < <(echo "$input" | jq -r '[(.workspace.current_dir // .cwd // ""), (.model.display_name // ""), (.context_window.used_percentage // "")] | @tsv')
[ -z "$cwd" ] && cwd=$PWD

# Directory, truncated to 3 components like Starship
d=$cwd
case "$d" in "$HOME") d="~";; "$HOME"/*) d="~/${d#"$HOME"/}";; esac
IFS='/' read -ra parts <<< "$d"
if [ "${#parts[@]}" -gt 3 ]; then
  n=${#parts[@]}
  d="…/${parts[$((n-3))]}/${parts[$((n-2))]}/${parts[$((n-1))]}"
fi
printf '\033[1;36m%s\033[0m' "$d"

# Git branch (no optional locks, no network)
br=$(git -C "$cwd" --no-optional-locks symbolic-ref --short -q HEAD 2>/dev/null || git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
[ -n "$br" ] && printf ' on \033[1;35m\356\202\240 %s\033[0m' "$br"

# Node (only in Node projects)
if [ -f "$cwd/package.json" ] && command -v node >/dev/null 2>&1; then
  printf ' via \033[1;32m\356\234\230 %s\033[0m' "$(node -v 2>/dev/null)"
fi

# Java (only in Java projects); read SDKMAN symlink instead of launching a JVM
if [ -f "$cwd/pom.xml" ] || [ -f "$cwd/build.gradle" ] || [ -f "$cwd/build.gradle.kts" ]; then
  jv=$(basename "$(readlink "$HOME/.sdkman/candidates/java/current" 2>/dev/null)")
  [ -n "$jv" ] && printf ' via \033[1;31m\356\211\226 v%s\033[0m' "$jv"
fi

[ -n "$model" ] && printf ' \033[2m|\033[0m \033[1;34m%s\033[0m' "$model"
[ -n "$used" ] && printf ' \033[2m|\033[0m ctx %.0f%%' "$used"
printf '\n'
