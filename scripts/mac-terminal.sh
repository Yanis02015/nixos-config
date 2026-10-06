#!/bin/sh
# macOS : ouvre une nouvelle fenêtre du Terminal d'Apple, en y lançant une commande si
# on en passe une. Appelé par skhd (dots/skhd). Si Terminal n'est pas lancé, `reopen`
# le démarre avec sa fenêtre par défaut, qu'on réutilise (sinon deux fenêtres).
#   mac-terminal.sh                        → shell
#   mac-terminal.sh '~/chemin/script.sh'   → commande tapée dans la nouvelle fenêtre
osascript - "${1:-}" <<'APPLESCRIPT'
on run argv
	set cmd to item 1 of argv
	tell application "Terminal"
		if it is running then
			do script cmd
		else
			reopen
			do script cmd in window 1
		end if
		activate
	end tell
end run
APPLESCRIPT
