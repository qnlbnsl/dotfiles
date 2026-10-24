-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Change an existing binding by unbinding it first, then binding the key again.
-- This example changes SUPER+SPACE from the launcher to the Omarchy root menu.
-- hl.unbind("SUPER + SPACE")
-- o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle root")

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- Logitech MX Keys examples:
-- o.bind("SUPER + SHIFT + S", nil, "omarchy-capture-screenshot")
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, "omarchy-shell shell toggle omarchy.emojis")

-- macOS screenshots: Super+Shift+3 = full screen, Super+Shift+4 = select an area.
-- Each saves to ~/Pictures, copies to the clipboard and shows a clickable thumbnail.
-- These replace "Move window to workspace 3/4" (code:12/13 are the 3 and 4 keys);
-- windows can still be moved there with Super+Shift+Alt+3/4 or in Mission Control.
hl.unbind("SUPER + SHIFT + code:12")
hl.unbind("SUPER + SHIFT + code:13")
o.bind("SUPER + SHIFT + code:12", "Screenshot full screen", "omarchy-capture-screenshot fullscreen")
o.bind("SUPER + SHIFT + code:13", "Screenshot area", "omarchy-capture-screenshot region")

-- Cmd+Q: quit the focused app, closing all its windows (Super+W still closes just one).
o.bind("SUPER + Q", "Quit app", "mac-quit-app")
