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

-- macOS-style per-monitor workspaces: every monitor gets its own 1-10.
-- Monitors are ordered left to right; monitor k owns workspaces k*10+1 .. k*10+10,
-- so Super+3 on the right monitor is workspace 13. A workspace is created on the
-- monitor that asked for it and stays there, so switching on one monitor never
-- touches the other. On a single monitor this is identical to the defaults.
local function monitor_offset()
  local active = hl.get_active_monitor()
  if not active then return 0 end
  local monitors = hl.get_monitors()
  table.sort(monitors, function(a, b) return a.x < b.x end)
  for i, m in ipairs(monitors) do
    if m.name == active.name then return (i - 1) * 10 end
  end
  return 0
end

for n = 1, 10 do
  local key = "code:" .. tostring(n + 9)
  hl.unbind("SUPER + " .. key)
  o.bind("SUPER + " .. key, "Switch to workspace " .. n .. " on this monitor", function()
    hl.dispatch(hl.dsp.focus({ workspace = tostring(monitor_offset() + n) }))
  end)
  -- Super+Shift+3/4 stay as screenshots (bound above).
  if n ~= 3 and n ~= 4 then
    hl.unbind("SUPER + SHIFT + " .. key)
    o.bind("SUPER + SHIFT + " .. key, "Move window to workspace " .. n .. " on this monitor", function()
      hl.dispatch(hl.dsp.window.move({ workspace = tostring(monitor_offset() + n) }))
    end)
  end
  hl.unbind("SUPER + SHIFT + ALT + " .. key)
  o.bind("SUPER + SHIFT + ALT + " .. key, "Move window silently to workspace " .. n .. " on this monitor", function()
    hl.dispatch(hl.dsp.window.move({ workspace = tostring(monitor_offset() + n), follow = false }))
  end)
end

-- Cycle only through this monitor's workspaces.
hl.unbind("SUPER + TAB")
hl.unbind("SUPER + SHIFT + TAB")
hl.unbind("SUPER + mouse_down")
hl.unbind("SUPER + mouse_up")
o.bind("SUPER + TAB", "Next workspace on this monitor", hl.dsp.focus({ workspace = "m+1" }))
o.bind("SUPER + SHIFT + TAB", "Previous workspace on this monitor", hl.dsp.focus({ workspace = "m-1" }))
o.bind("SUPER + mouse_down", "Next workspace on this monitor", hl.dsp.focus({ workspace = "m+1" }))
o.bind("SUPER + mouse_up", "Previous workspace on this monitor", hl.dsp.focus({ workspace = "m-1" }))
