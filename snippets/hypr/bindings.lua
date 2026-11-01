-- Personal keybindings. Appended to ~/.config/hypr/bindings.lua.
-- Every rebind first unbinds the Omarchy default it replaces (hl.unbind), then binds the key again.
-- App launchers: change the commands to taste; keep the key choices unless the user says otherwise.

-- Close windows with SUPER+Q instead of SUPER+W
hl.unbind("SUPER + W")
o.bind("SUPER + Q", "Close window", hl.dsp.window.close())

-- App shortcuts
o.bind("SUPER + B", "Brave Origin", { launch = "brave-origin" })
o.bind("SUPER + Z", "Zed", { launch = "zeditor" })
o.bind("SUPER + E", "File manager", { omarchy = "nautilus" })
o.bind("SUPER + W", "WhatsApp", { webapp = "https://web.whatsapp.com/", focus = true })
-- SUPER+G was Omarchy's "Toggle window grouping"; GitHub opens as a Brave Origin tab, not a web app
hl.unbind("SUPER + G")
o.bind("SUPER + G", "GitHub", { launch = "brave-origin https://github.com/" })
o.bind("SUPER + Y", "YouTube", { webapp = "https://youtube.com/", focus = true })
-- SUPER+C was Omarchy's "Universal copy"
hl.unbind("SUPER + C")
o.bind("SUPER + C", "VS Code", { launch = "code" })
-- SUPER+V was Omarchy's "Universal paste"; the clipboard manager moves here
-- from SUPER+CTRL+V
hl.unbind("SUPER + V")
hl.unbind("SUPER + CTRL + V")
o.bind("SUPER + V", "Clipboard manager", "omarchy-shell shell toggle omarchy.clipboard")
-- SUPER+X was Omarchy's "Universal cut"; it now opens the System menu like SUPER+ESCAPE
hl.unbind("SUPER + X")
o.bind("SUPER + X", "System menu", "omarchy-menu toggle system")

-- Screenshot (same as PRINT); SUPER+SHIFT+S was Omarchy's "Google Maps" webapp
hl.unbind("SUPER + SHIFT + S")
o.bind("SUPER + SHIFT + S", "Screenshot", "omarchy-capture-screenshot")

-- Omarchy's X web app bindings are not wanted (no X web app installed)
hl.unbind("SUPER + SHIFT + X")
hl.unbind("SUPER + SHIFT + ALT + X")
