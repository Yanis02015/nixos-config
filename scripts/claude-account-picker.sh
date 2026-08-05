#!/usr/bin/env bash
# Choix interactif du compte Claude (standard vs 1of10) pour les liens
# claude:// (deep links MCP OAuth notamment) — appelé comme handler de
# x-scheme-handler/claude, voir claude-account-picker.desktop (packages.nix).
set -euo pipefail

URL="${1:-}"

CHOICE=$(printf 'Claude\nClaude 1of10\n' | fzf \
	--prompt='Compte  ' \
	--header="${URL:-Nouvelle fenêtre}" \
	--height=~50% --border --layout=reverse)

ARGS=()
[[ -n "$URL" ]] && ARGS+=("$URL")

case "$CHOICE" in
"Claude 1of10")
	exec claude-desktop --user-data-dir="$HOME/.config/Claude-1of10" "${ARGS[@]}"
	;;
"Claude")
	exec claude-desktop "${ARGS[@]}"
	;;
esac
