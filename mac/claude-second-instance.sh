#!/usr/bin/env bash
# Crée ~/Applications/<nom>.app : lance une 2e instance de Claude Desktop
# avec son propre dossier de données (--user-data-dir), donc un 2e compte
# connecté en parallèle du premier. Équivalent Mac de claude-1of10.desktop
# sur NixOS. Voir CLAUDE.md (section macOS).
#
# Usage : mac/claude-second-instance.sh ["Claude Perso" [Claude-perso]]
set -euo pipefail

NAME="${1:-Claude Perso}"
DIR_NAME="${2:-Claude-perso}"
DATA_DIR="$HOME/Library/Application Support/$DIR_NAME"
APP="$HOME/Applications/$NAME.app"
CLAUDE="/Applications/Claude.app"

mkdir -p "$HOME/Applications"
rm -rf "$APP"

# open -n : nouveau processus même si le Claude habituel tourne déjà.
# Mais Claude ne verrouille pas son dossier de données sur macOS (c'est
# LaunchServices qui évite les doublons, et -n le contourne) : si cette
# instance tourne déjà, on la ramène devant au lieu d'en lancer une autre
# sur le même profil.
osacompile -o "$APP" <<EOF
use AppleScript version "2.4"
use framework "Foundation"
use framework "AppKit"
use scripting additions

property dataDir : "$DATA_DIR"

on instancePid()
	return do shell script "pgrep -f -- " & quoted form of ("MacOS/Claude --user-data-dir=" & dataDir & "\$") & " | head -n 1"
end instancePid

on run
	set pidText to instancePid()
	if pidText is "" then
		do shell script "open -n -b com.anthropic.claudefordesktop --args --user-data-dir=" & quoted form of dataDir
		-- Attendre le processus pour le passer devant tant que le lanceur est
		-- l'app active : sinon le focus repart sur l'app d'avant.
		repeat 40 times
			delay 0.25
			set pidText to instancePid()
			if pidText is not "" then exit repeat
		end repeat
		if pidText is "" then return
	else
		-- Événement reopen (aevt/rapp), celui d'un clic sur le Dock : Claude
		-- réaffiche sa fenêtre si elle a été fermée. Pas au lancement : la
		-- fenêtre n'existe pas encore et Claude en créerait une deuxième.
		-- Codes en réels, les entiers AppleScript s'arrêtent à 2^29.
		set target to current application's NSAppleEventDescriptor's descriptorWithProcessIdentifier:(pidText as integer)
		set ev to current application's NSAppleEventDescriptor's appleEventWithEventClass:1.634039412E+9 eventID:1.9189884E+9 targetDescriptor:target returnID:-1 transactionID:0
		ev's sendEventWithOptions:(current application's NSAppleEventSendNoReply) |timeout|:5 |error|:(missing value)
	end if
	(current application's NSRunningApplication's runningApplicationWithProcessIdentifier:(pidText as integer))'s activateWithOptions:(current application's NSApplicationActivateAllWindows)
end run
EOF

# Icône de Claude. osacompile met aussi l'icône dans Assets.car, qui passe
# avant le .icns : on le retire.
cp "$CLAUDE/Contents/Resources/electron.icns" "$APP/Contents/Resources/applet.icns"
rm -f "$APP/Contents/Resources/Assets.car"
plutil -remove CFBundleIconName "$APP/Contents/Info.plist" 2>/dev/null || true
# Pas de LSUIElement (qui cacherait le lanceur du Dock) : une app qui n'est
# jamais active ne peut pas passer le premier plan à Claude (macOS ≥ 14).
# osacompile ne met pas d'identifiant ; macOS s'en sert pour les autorisations.
plutil -replace CFBundleIdentifier -string "local.nixos-config.$(echo "$DIR_NAME" | tr '[:upper:]' '[:lower:]')" "$APP/Contents/Info.plist"

# Les modifs ci-dessus cassent la signature d'osacompile : on re-signe en ad hoc.
codesign --force --deep --sign - "$APP"
touch "$APP"

echo "Créé : $APP (données : $DATA_DIR)"
