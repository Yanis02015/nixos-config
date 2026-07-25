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

-- Écran externe : LG Electronics E2251, branché en HDMI. Positionné à gauche
-- du laptop (largeur 1920, donc origine en -1920x0 pour être collé contre eDP-1).
hl.monitor({
	output = "HDMI-A-1",
	mode = "1920x1080@60",
	position = "-1920x0",
	scale = 1,
})

-- Si l'écran externe est débranché, Hyprland se rabat automatiquement sur
-- eDP-1 seul (pas besoin de gérer ce cas à la main).

-- Sans règle explicite, le workspace 1 est assigné au premier moniteur
-- détecté par Hyprland — l'ordre dépend de quand chaque écran a été branché
-- (ex: PC allumé seul puis écran externe branché après coup = workspace 1
-- sur eDP-1 au lieu de l'externe). On fixe donc explicitement : workspace 1
-- sur l'écran externe, le reste (2-10) sur l'écran du laptop.
hl.workspace_rule({ workspace = "1", monitor = "HDMI-A-1", default = true })
for i = 2, 10 do
	hl.workspace_rule({ workspace = tostring(i), monitor = "eDP-1", default = (i == 2) })
end
