#!/usr/bin/env bash
# Lance le setup de travail habituel. Déclenché uniquement à la main
# (SUPER+SHIFT+W, voir bindings.lua) — pas d'autostart.
#
# Le placement (workspace/fullscreen/float/size) est géré par des règles de
# fenêtre permanentes dans windowrules.lua (voir "setup de travail" dedans),
# pas ici : passer ces options directement à hl.dsp.exec_cmd() est cassé en
# 0.55 pour les apps qui forkent/wrappent leur binaire réel (suivi par PID
# du process lancé, pas de la fenêtre). Une règle de classe matche la
# fenêtre elle-même une fois créée, donc c'est fiable peu importe le PID.
#
#   1: Brave (plein écran)
#   2: Claude Desktop
#   3: Zed
#   4: Discord + Zen
#   5: Terminal flottant (petit)

exec_cmd() {
	hyprctl dispatch "hl.dsp.exec_cmd(\"$1\")"
}

exec_cmd "brave"
exec_cmd "claude-desktop"
exec_cmd "zeditor"
exec_cmd "discord"
exec_cmd "zen-beta"
exec_cmd "ghostty --title=startws-term"
