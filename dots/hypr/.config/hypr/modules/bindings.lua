----------------
--- Bindings ---
----------------
local bind = hl.bind

-- wallpaper switcher
bind("SUPER + P", hl.dsp.exec_cmd("~/nixos-config/scripts/rotate_wallpaper.sh"))

-- generics
bind("SUPER + Return", hl.dsp.exec_cmd(TERMINAL .. " --title=main-term"))
bind("SUPER + SHIFT + O", hl.dsp.exec_cmd("obsidian"))
bind("SUPER + SHIFT + F", hl.dsp.exec_cmd(FILEMANAGER))
bind("SUPER + SHIFT + E", hl.dsp.exec_cmd("ghostty --title=yazi-term -e yazi"))
bind("SUPER + SHIFT + D", hl.dsp.exec_cmd("ghostty --title=lazydocker-term -e lazydocker"))
-- sesh : sélecteur de session tmux (nouveau terminal ne rejoint plus de
-- session partagée automatiquement, voir .zshrc) — retrouve/crée une
-- session par projet en un raccourci
bind("SUPER + T", hl.dsp.exec_cmd("ghostty --title=sesh-term -e ~/nixos-config/scripts/sesh-picker.sh"))
bind("SUPER +  B", hl.dsp.exec_cmd(BROWSER))
-- ouvre Zed + Zen + Discord d'un coup (pas de placement par workspace :
-- exec_cmd(cmd, {workspace=...}) est cassé en 0.55 pour les apps qui
-- forkent/wrappent leur binaire, voir historique git de ce fichier).
-- hl.dsp.exec_cmd() (utilisé pour les binds "normaux" ci-dessus) ne fait que
-- construire un descripteur de dispatch pour bind() — il ne lance rien
-- appelé seul. Dans le corps d'une fonction (exécutée au keypress), il faut
-- l'API impérative hl.exec_cmd() (même API que celle utilisée par
-- autostart.lua), sinon les appels ne font rien silencieusement.
bind("SUPER + SHIFT + W", function()
	hl.exec_cmd(EDITOR)
	hl.exec_cmd(BROWSER)
	hl.exec_cmd("discord")
end)

-- quickshell Bindings
bind("SUPER + SPACE", hl.dsp.exec_cmd("qs -p $HOME/.config/quickshell/minimalBar ipc call launcher toggle")) -- launcher
bind("SUPER + ALT + SPACE", hl.dsp.exec_cmd("qs -p $HOME/.config/quickshell/minimalBar ipc call rightIsland toggle")) -- toggle right island
bind("SUPER +  N", hl.dsp.exec_cmd("qs -p $HOME/.config/quickshell/minimalBar ipc call notifications toggle")) -- noti panel
bind("SUPER + C", hl.dsp.exec_cmd("qs -p $HOME/.config/quickshell/minimalBar ipc call clipboard toggle")) -- clipboard secondary
bind("SUPER + R", hl.dsp.exec_cmd("qs -p $HOME/.config/quickshell/minimalBar ipc call reminders toggle")) -- clipboard secondary
-- hide shell bar
bind("SUPER + SHIFT + SPACE", hl.dsp.exec_cmd("qs -p $HOME/.config/quickshell/minimalBar ipc call bar toggle")) --hide bar
