#!/bin/bash
# Links the commands into ~/.local/bin and the skill into the Claude skills folder
# (${CLAUDE_CONFIG_DIR:-~/.claude}/skills). Re-run after a git pull; it only ever
# replaces links that point into this repo. Runs the self-tests from this checkout
# first, and nothing is linked if one fails.
set -euo pipefail
usage() { echo "usage: ./install.sh   (no options; --help shows this)"; }
for a in "$@"; do
  case "$a" in
    -h|--help) usage; exit 0 ;;
    *) echo "install.sh: unknown option $a" >&2; usage >&2; exit 2 ;;
  esac
done
repo=$(cd "$(dirname "$0")" && pwd)
for t in codex-usage codex-sync; do  # from the checkout, before any link exists; set -e stops here on a failure
  python3 -I "$repo/bin/$t" --selftest >/dev/null
  echo "$t selftest ok"
done

bin="$HOME/.local/bin"
skills="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills"
mkdir -p "$bin" "$skills"
skills=$(cd "$skills" && pwd)
skipped=""

link() {  # link <target> <link path>
  if [ -e "$2" ] && [ ! -L "$2" ]; then
    echo "skip $2: a real file is there; move it away to use this repo's copy" >&2
    skipped="$skipped  $2"$'\n'
    return
  fi
  if [ -L "$2" ] && [[ "$(readlink "$2")" != "$repo"/* ]]; then
    echo "skip $2: it links somewhere else ($(readlink "$2"))" >&2
    skipped="$skipped  $2"$'\n'
    return
  fi
  ln -sfn "$1" "$2" && echo "linked $2"
}

link "$repo/bin/codex-usage" "$bin/codex-usage"
link "$repo/bin/codex-sync" "$bin/codex-sync"
link "$repo/skills/codex-worker" "$skills/codex-worker"
mkdir -p "$(dirname "$skills")/agents"
link "$repo/agents/codex-worker.md" "$(dirname "$skills")/agents/codex-worker.md"
if command -v codex >/dev/null 2>&1 && [ "$(realpath "$(command -v codex)")" != "$repo/bin/codex" ]; then
  echo "codex is already installed ($(command -v codex)); the extension locator is not needed"
else
  link "$repo/bin/codex" "$bin/codex"
fi

case ":$PATH:" in *":$bin:"*) ;; *) echo "add $bin to your PATH" >&2 ;; esac
[ -z "$skipped" ] || printf 'skipped, something else is already there:\n%s' "$skipped" >&2
echo "next: run codex-sync --dry-run, then codex-sync, to share skills, rules and guard hooks with Codex"
