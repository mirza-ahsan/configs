-- Personal input settings. Appended to ~/.config/hypr/input.lua.

-- Touchpad: natural (inverse) scrolling
hl.config({
  input = {
    touchpad = {
      natural_scroll = true,
    },
  },
})

-- Mouse: no acceleration, so pointer movement is 1:1 with the mouse
hl.config({
  input = {
    accel_profile = "flat",
    sensitivity = 0,
  },
})
-- ...but the built-in touchpad keeps adaptive acceleration.
-- MACHINE-SPECIFIC: the device name comes from `hyprctl devices` (the touchpad entry).
-- On a different laptop replace it, or drop this line if there is no external mouse.
hl.device({ name = "ven_04f3:00-04f3:311c-touchpad", accel_profile = "adaptive" })

-- Caps Lock works as Caps Lock. Omarchy makes it the Compose key
-- (compose:caps,shift:both_capslock_cancel); Compose moves to Right Alt instead.
-- Layout stays Omarchy's (read from /etc/vconsole.conf); only the options change.
hl.config({
  input = {
    kb_options = "compose:ralt",
  },
})
