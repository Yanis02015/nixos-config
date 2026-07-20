#!/usr/bin/env bash
# Sélecteur de session tmux (sesh + fzf). Appelé depuis deux endroits qui ne
# partagent pas le même contexte fzf :
#   - SUPER+T (bindings.lua)   : nouveau terminal hors tmux -> fzf classique
#   - prefix+s (tmux.conf)     : déjà dans tmux -> popup fzf-tmux, passer --popup
if [[ "$1" == "--popup" ]]; then
  FZF=(fzf-tmux -p 80%,70%)
else
  FZF=(fzf)
fi

SELECTED=$(sesh list --icons | "${FZF[@]}" \
  --no-sort --ansi --border-label ' sesh ' --prompt '⚡  ' \
  --header '  ^a all ^t tmux ^g configs ^x zoxide ^d kill ^f find' \
  --bind 'tab:down,btab:up' \
  --bind 'ctrl-a:change-prompt(⚡  )+reload(sesh list --icons)' \
  --bind 'ctrl-t:change-prompt(🪟  )+reload(sesh list -t --icons)' \
  --bind 'ctrl-g:change-prompt(⚙️  )+reload(sesh list -c --icons)' \
  --bind 'ctrl-x:change-prompt(📁  )+reload(sesh list -z --icons)' \
  --bind 'ctrl-f:change-prompt(🔎  )+reload(fd -H -d 2 -t d -E .Trash . ~)' \
  --bind 'ctrl-d:execute(tmux kill-session -t {2..})+change-prompt(⚡  )+reload(sesh list --icons)' \
  --preview-window 'right:55%' \
  --preview 'sesh preview {}')

[ -n "$SELECTED" ] && sesh connect "$SELECTED"
