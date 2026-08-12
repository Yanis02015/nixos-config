#!/usr/bin/env bash
# Réaffirme claude-account-picker.desktop comme handler de x-scheme-handler/claude.
#
# claude-desktop (l'app Electron standard, paquet aaddrick/claude-desktop-debian)
# s'enregistre elle-même comme handler par défaut à CHAQUE lancement
# (app.setAsDefaultProtocolClient, confirmé présent dans son app.asar), ce qui
# écrase ~/.config/mimeapps.list et annule le choix du picker. Ce script est
# déclenché par un path unit systemd --user qui surveille ce fichier (voir
# claude-mimeapps-guard.path/.service dans nixos/configuration.nix) et reprend
# la main dès que l'association change.
set -euo pipefail

DESIRED="claude-account-picker.desktop"
CURRENT=$(xdg-mime query default x-scheme-handler/claude 2>/dev/null || true)

[[ "$CURRENT" == "$DESIRED" ]] && exit 0

xdg-mime default "$DESIRED" x-scheme-handler/claude
