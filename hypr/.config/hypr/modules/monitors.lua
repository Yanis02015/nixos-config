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

-- Écran externe (adapte le mode si besoin) : décommente si tu branches un
-- moniteur externe. Le setup original de l'auteur pointait vers HDMI-A-1 ;
-- ajuste le nom de sortie avec `hyprctl monitors` une fois branché.
-- hl.monitor({
-- 	output = "HDMI-A-1",
-- 	mode = "1920x1080@60",
-- 	position = "0x-1080",
-- 	scale = 1,
-- })
