-------------------------------
--- monitors and workspaces ---
-------------------------------

hl.env("GDK_SCALE", "1")

hl.monitor({
	output = "eDP-1",
	mode = "1920x1080@120",
	position = "0x0",
	scale = 1,
})

-- Écran externe : LG Electronics E2251, branché en HDMI. Positionné à droite
-- du laptop (auto-détecté ainsi par Hyprland avant même d'ajouter cette
-- règle ; on la rend juste explicite/permanente).
hl.monitor({
	output = "HDMI-A-1",
	mode = "1920x1080@60",
	position = "1920x0",
	scale = 1,
})

-- Si l'écran externe est débranché, Hyprland se rabat automatiquement sur
-- eDP-1 seul (pas besoin de gérer ce cas à la main).
