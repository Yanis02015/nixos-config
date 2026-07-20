-- suppress maximize
hl.window_rule({
	name = "suppress-maximize-events",
	match = { class = ".*" },
	suppress_event = "maximize",
})

-- default size/position for any window toggled to floating (SUPER+O), so it
-- doesn't just keep its full tiled size. Placed before the per-app float
-- rules below so those still win for the apps that specify their own size.
hl.window_rule({
	name = "default-float-size",
	match = { float = true },
	size = "60% 60%",
	center = true,
})

-- fix xwayland drags
hl.window_rule({
	name = "fix-xwayland-drags",
	match = {
		class = "^$",
		title = "^$",
		xwayland = true,
		float = true,
		fullscreen = false,
		pin = false,
	},
	no_focus = true,
})

-- hyprland-run
hl.window_rule({
	name = "move-hyprland-run",
	match = { class = "hyprland-run" },
	move = "20 monitor_h-120",
	float = true,
})

-- wiremix
hl.window_rule({
	name = "wiremix-float",
	match = { title = "^wiremix-term$", class = "com.mitchellh.ghostty" },
	float = true,
	move = "1307 51",
	size = "600 400",
})

-- yazi
hl.window_rule({
	name = "yazi-float",
	match = { title = "^yazi-term$", class = "com.mitchellh.ghostty" },
	float = true,
	center = true,
	size = "70% 70%",
})

-- lazydocker
hl.window_rule({
	name = "lazydocker-float",
	match = { title = "^lazydocker-term$", class = "com.mitchellh.ghostty" },
	float = true,
	center = true,
	size = "80% 80%",
})

-- bluetui
hl.window_rule({
	name = "bluetui-float",
	match = { title = "^bluetui-term$", class = "com.mitchellh.ghostty" },
	float = true,
	move = "1307 51",
	size = "600 800",
})

-- impala
hl.window_rule({
	name = "impala-float",
	match = { title = "^impala-term$", class = "com.mitchellh.ghostty" },
	float = true,
	move = "1307 51",
	size = "600 800",
})

-- sesh (sélecteur de session tmux)
hl.window_rule({
	name = "sesh-float",
	match = { title = "^sesh-term$", class = "com.mitchellh.ghostty" },
	float = true,
	center = true,
	size = "80% 70%",
})

-- nmtui
hl.window_rule({
	name = "nmtui-float",
	match = { title = "^nmtui-term$", class = "com.mitchellh.ghostty" },
	float = true,
	center = true,
	size = "600 800",
})

-- sysmenu tui
hl.window_rule({
	name = "sysmenu-floating-tui",
	match = { title = "^sysmenu-tui$", class = "com.mitchellh.ghostty" },
	float = true,
	center = true,
	size = "900 600",
})

-- rencal calendar
hl.window_rule({
	name = "rencal-float",
	match = { class = "^rencal$" },
	float = true,
	center = true,
	size = "66% 66%",
})

-- nautilus previewer
hl.window_rule({
	name = "NautilusPreview-float",
	match = { class = "^org.gnome.NautilusPreviewer$" },
	float = true,
	center = true,
	size = "900 600",
})

-- Apple Music PWA
hl.window_rule({
	name = "apple-music",
	match = { class = "^chrome-blgdilankhbcpipclgpdndahbehalgkh-Default$" },
	workspace = "5 silent",
	no_shadow = true,
	opaque = true,
})
