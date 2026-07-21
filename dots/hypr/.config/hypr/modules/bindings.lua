----------------
--- Bindings ---
----------------
local bind = hl.bind

-- wallpaper switcher
bind("SUPER + P", hl.dsp.exec_cmd("~/nixos-config/scripts/rotate_wallpaper.sh"))

-- generics
bind("SUPER + Return", hl.dsp.exec_cmd(TERMINAL))
bind("SUPER + SHIFT + O", hl.dsp.exec_cmd("obsidian"))
bind("SUPER + SHIFT + F", hl.dsp.exec_cmd(FILEMANAGER))
bind("SUPER + SHIFT + E", hl.dsp.exec_cmd("ghostty --title=yazi-term -e yazi"))
bind("SUPER + SHIFT + D", hl.dsp.exec_cmd("ghostty --title=lazydocker-term -e lazydocker"))
-- sesh : sélecteur de session tmux (nouveau terminal ne rejoint plus de
-- session partagée automatiquement, voir .zshrc) — retrouve/crée une
-- session par projet en un raccourci
bind("SUPER + T", hl.dsp.exec_cmd("ghostty --title=sesh-term -e ~/nixos-config/scripts/sesh-picker.sh"))
bind("SUPER +  B", hl.dsp.exec_cmd(BROWSER))

-- quickshell Bindings
bind("SUPER + SPACE", hl.dsp.exec_cmd("qs -p $HOME/.config/quickshell/minimalBar ipc call launcher toggle")) -- launcher
bind("SUPER + ALT + SPACE", hl.dsp.exec_cmd("qs -p $HOME/.config/quickshell/minimalBar ipc call rightIsland toggle")) -- toggle right island
bind("SUPER +  N", hl.dsp.exec_cmd("qs -p $HOME/.config/quickshell/minimalBar ipc call notifications toggle")) -- noti panel
bind("SUPER + C", hl.dsp.exec_cmd("qs -p $HOME/.config/quickshell/minimalBar ipc call clipboard toggle")) -- clipboard secondary
bind("SUPER + R", hl.dsp.exec_cmd("qs -p $HOME/.config/quickshell/minimalBar ipc call reminders toggle")) -- clipboard secondary
-- hide shell bar
bind("SUPER + SHIFT + SPACE", hl.dsp.exec_cmd("qs -p $HOME/.config/quickshell/minimalBar ipc call bar toggle")) --hide bar
