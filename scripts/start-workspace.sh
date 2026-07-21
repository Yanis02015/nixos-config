#!/usr/bin/env bash
# Lance le setup de travail habituel, une appli par workspace. Déclenché
# uniquement à la main (SUPER+SHIFT+W, voir bindings.lua) — pas d'autostart.
#
# hyprctl sur cette machine est un fork "hyprland-lua" : `hyprctl dispatch
# <texte>` exécute littéralement `hl.dispatch(<texte>)` comme du Lua (voir
# hyprland.lua/modules/*.lua). La syntaxe classique `hyprctl dispatch exec
# "[workspace N silent] cmd"` ne s'applique donc pas ici — il faut appeler
# hl.dsp.exec_cmd(cmd, {options}), la même API que celle utilisée par les
# binds Lua (bindings.lua).
#
#   1: Brave (plein écran)
#   2: Claude Desktop
#   3: Zed
#   4: Discord + Zen
#   5: Terminal flottant (petit)

exec_ws() {
	local cmd="$1" opts="$2"
	hyprctl dispatch "hl.dsp.exec_cmd(\"${cmd}\", {${opts}})"
}

exec_ws "brave" 'workspace="1 silent", fullscreen=true'
exec_ws "claude-desktop" 'workspace="2 silent"'
exec_ws "zeditor" 'workspace="3 silent"'
exec_ws "discord" 'workspace="4 silent"'
exec_ws "zen-beta" 'workspace="4 silent"'
exec_ws "ghostty" 'workspace="5 silent", float=true, size="700 450", center=true'
