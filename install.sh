#!/usr/bin/env bash
# install.sh - one-line bootstrap for the Ritual Sovereign Agent.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/FASHAKING/ritual-agent-deployment/main/install.sh | bash
#
# Clones (or reuses) the repo, creates .env on first run, shows a numbered menu for the
# common actions, asks only for whatever that action needs, then hands off to run.sh.

set -euo pipefail

REPO_URL="https://github.com/FASHAKING/ritual-agent-deployment.git"
DEST="${RITUAL_AGENT_DIR:-$HOME/.ritual-agent-deployment}"

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  ESC=$'\033'; RESET="${ESC}[0m"; BOLD="${ESC}[1m"; ACCENT="${ESC}[38;5;141m"; MUTED="${ESC}[38;5;244m"
else
  ESC=; RESET=; BOLD=; ACCENT=; MUTED=
fi
say()  { printf '  %s\n' "$1"; }
ask()  { printf '  %s%s%s ' "$ACCENT" "$1" "$RESET" >&2; }

command -v git >/dev/null 2>&1 || { echo "git is required - see README for install instructions" >&2; exit 1; }

if [ -d "$DEST/.git" ]; then
  git -C "$DEST" pull --ff-only --quiet
else
  git clone --quiet "$REPO_URL" "$DEST"
fi
cd "$DEST"

[ -f .env ] || cp .env.example .env

RUNNER="bash run.sh"
command -v pwsh >/dev/null 2>&1 && [ "$(uname -s 2>/dev/null || echo Windows)" = "Windows" ] && RUNNER="pwsh run.ps1"

printf '\n  %sRitual Sovereign Agent%s\n' "$BOLD" "$RESET"
say "1) Deploy an agent"
say "2) Check agent status"
say "3) Stop an agent"
ask "choose [1-3]:"
read -r CHOICE < /dev/tty
echo

case "$CHOICE" in
  1)
    ask "task prompt for the agent [Say hello world]:"
    read -r PROMPT_INPUT < /dev/tty
    if [ -n "$PROMPT_INPUT" ]; then
      tmp="$(mktemp)"
      while IFS= read -r line || [ -n "$line" ]; do
        case "$line" in PROMPT=*) printf 'PROMPT=%s\n' "$PROMPT_INPUT" ;; *) printf '%s\n' "$line" ;; esac
      done < .env > "$tmp"
      mv "$tmp" .env
    fi
    exec $RUNNER deploy
    ;;
  2)
    ask "agent address (leave blank for the default):"
    read -r ADDR < /dev/tty
    exec $RUNNER status ${ADDR:+"$ADDR"}
    ;;
  3)
    ask "agent address (leave blank for the default):"
    read -r ADDR < /dev/tty
    exec $RUNNER stop ${ADDR:+"$ADDR"}
    ;;
  *)
    echo "  invalid choice" >&2
    exit 1
    ;;
esac
