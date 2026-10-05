#!/bin/bash
# macOS uniquement — équivalent de `ghostty --title=X -e <commande>` sous Hyprland,
# appelé par les binds AeroSpace (dots/aerospace/.config/aerospace/aerospace.toml).
#   mac-ghostty.sh <titre> [commande...]
#
# Sur macOS, on ne lance pas Ghostty en CLI : on passe par `open -na Ghostty.app --args`
# (une nouvelle instance de l'app par appel). Le titre sert aux règles `on-window-detected`
# d'AeroSpace, comme les `windowrule` qui matchent `title = "^X-term$"` sous Hyprland.
#
# Une app lancée par `open` ne reçoit pas le PATH Homebrew : on le force pour la commande
# (sinon yazi, lazydocker, sesh… introuvables).
title=$1
shift
BREW_PATH=/opt/homebrew/bin:/opt/homebrew/sbin:/usr/bin:/bin:/usr/sbin:/sbin

if [ $# -eq 0 ]; then
  exec open -na Ghostty.app --args --title="$title"
fi
exec open -na Ghostty.app --args --title="$title" -e /usr/bin/env PATH="$BREW_PATH" "$@"
