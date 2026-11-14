-- Personal window rules. Appended to the END of ~/.config/hypr/hyprland.lua
-- (after the require("default.hypr.toggles") line).

-- Papers replaces Evince as the PDF viewer; float it like Omarchy floats Evince.
o.window("org.gnome.Papers", { tag = "+floating-window" })

-- Omarchy's browser rule matches brave-browser but not brave-origin, so Brave
-- Origin got the default app transparency. Treat it like the other browsers.
o.window("^brave-origin$", { tag = "+chromium-based-browser" })
o.window({ tag = "chromium-based-browser" }, { tag = "-default-opacity", tile = true, opacity = "1.0 0.985" })

-- VLC runs through XWayland and cannot ask Wayland to block idle, so the screensaver started during playback.
-- Hyprland blocks idle for it while the window is focused (mpv does this itself).
o.window("^vlc$", { idle_inhibit = "focus" })
