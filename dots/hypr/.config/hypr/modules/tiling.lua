--------------------
--- tiling rules ---
--------------------

local bind = hl.bind

-- window management
bind("SUPER + W", hl.dsp.window.close())
bind("SUPER + O", hl.dsp.window.float({ action = "toggle" }))
bind("SUPER + F", hl.dsp.window.fullscreen())

-- focus
bind("SUPER + H", hl.dsp.focus({ direction = "left" }))
bind("SUPER + L", hl.dsp.focus({ direction = "right" }))
bind("SUPER + K", hl.dsp.focus({ direction = "up" }))
bind("SUPER + J", hl.dsp.focus({ direction = "down" }))

-- swap windows
bind("SUPER + SHIFT + H", hl.dsp.window.swap({ direction = "left" }))
bind("SUPER + SHIFT + L", hl.dsp.window.swap({ direction = "right" }))
bind("SUPER + SHIFT + K", hl.dsp.window.swap({ direction = "up" }))
bind("SUPER + SHIFT + J", hl.dsp.window.swap({ direction = "down" }))

-- resize horizontal
bind("SUPER + code:20", hl.dsp.window.resize({ x = -100, y = 0, relative = true }))
bind("SUPER + code:21", hl.dsp.window.resize({ x = 100, y = 0, relative = true }))

-- resize vertical
bind("SUPER + SHIFT + code:20", hl.dsp.window.resize({ x = 0, y = -100, relative = true }))
bind("SUPER + SHIFT + code:21", hl.dsp.window.resize({ x = 0, y = 100, relative = true }))

-- move active window to the next empty workspace
bind("SUPER + SHIFT + N", hl.dsp.window.move({ workspace = "empty" }))

-- cycle through open windows (no visual preview, just focus-hopping —
-- stopgap en attendant un vrai switcher visuel façon Alt+Tab)
bind("SUPER + Tab", hl.dsp.window.cycle_next())

-- switch workspaces with arrow keys
bind("SUPER + Left", hl.dsp.focus({ workspace = "-1" }))
bind("SUPER + Right", hl.dsp.focus({ workspace = "+1" }))

-- move active window to the previous/next workspace with arrow keys
bind("SUPER + SHIFT + Left", hl.dsp.window.move({ workspace = "-1" }))
bind("SUPER + SHIFT + Right", hl.dsp.window.move({ workspace = "+1" }))
bind("SUPER + SHIFT + CTRL + Left", hl.dsp.window.move({ workspace = "-1", follow = false }))
bind("SUPER + SHIFT + CTRL + Right", hl.dsp.window.move({ workspace = "+1", follow = false }))

-- switch workspaces
-- Liés par code physique (code:10 = touche "1", etc.), pas par symbole : en
-- AZERTY la touche "1" tape "&" sans Shift, "1" n'existe qu'avec Shift, donc
-- un bind par symbole ("SUPER + 1") ne matchait plus rien sans Shift enfoncé.
for i = 1, 9 do
	local code = "code:" .. (9 + i)
	bind("SUPER + " .. code, hl.dsp.focus({ workspace = i }))
	bind("SUPER + SHIFT + " .. code, hl.dsp.window.move({ workspace = i }))
	bind("SUPER + SHIFT + CTRL + " .. code, hl.dsp.window.move({ workspace = i, follow = false }))
end

-- floating display stuff
bind("SUPER + code:19", hl.dsp.focus({ workspace = 10 }))
bind("SUPER + SHIFT + code:19", hl.dsp.window.move({ workspace = 10 }))

-- special workspace (scrathpad)
bind("SUPER + S", hl.dsp.workspace.toggle_special("magic"))
bind("SUPER + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- mouse
bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })
