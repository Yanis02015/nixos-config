--------------
--- INPUTS ---
--------------

hl.config({
	input = {
		-- kb_layout = "fr",
		-- kb_options = "ctrl:swap_lalt_lctl",
		-- kb_file remplace layout/options : c'est le layout fr + ctrl:swap_lalt_lctl
		-- généré via `xkbcli compile-keymap`, avec les touches ² et < inversées
		-- (TLDE <-> LSGT). Si tu changes de layout/options un jour, il faut
		-- régénérer ce fichier et refaire le swap à la main dedans.
		kb_file = "~/.config/hypr/custom.xkb",

		repeat_rate = 60,
		repeat_delay = 300,

		numlock_by_default = true,

		follow_mouse = 1,
		touchpad = {
			natural_scroll = true,
			scroll_factor = 1,
		},
	},
	cursor = {
		inactive_timeout = 10,
		no_warps = true,
	},
})

hl.gesture({
	fingers = 3,
	direction = "horizontal",
	action = "workspace",
})
