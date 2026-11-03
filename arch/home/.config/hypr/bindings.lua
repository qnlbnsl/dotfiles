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

-- Cmd+Q: quit the focused app, closing all its windows (Super+Alt+W closes just one).
o.bind("SUPER + Q", "Quit app", "mac-quit-app")

-- macOS tab keys, like Omarchy's universal Super+C/V: send the app's own Ctrl shortcut.
-- Same send method as default/hypr/bindings/clipboard.lua (key down, then up 50 ms later,
-- so the held Super doesn't merge in and the key doesn't stick).
local function send_keys(mods, key)
  hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "down" }))
  hl.timer(function()
    hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "up" }))
  end, { timeout = 50, type = "oneshot" })
end

-- Terminals get different keys: Ctrl+W there deletes a word, and Ghostty's new tab is
-- Ctrl+Shift+T. Uses Omarchy's "terminal" window tag (default/hypr/apps/terminals.lua).
local function in_terminal()
  local window = hl.get_active_window()
  if not window or not window.tags then return false end
  for i = 1, #window.tags do
    if window.tags[i]:gsub("%*$", "") == "terminal" then return true end
  end
  return false
end

-- Super+W: close the tab (Cmd+W); in a terminal, close the window as before.
-- Was "Close window", which moves to Super+Alt+W.
hl.unbind("SUPER + W")
o.bind("SUPER + W", "Close tab", function()
  if in_terminal() then
    hl.dispatch(hl.dsp.window.close())
  else
    send_keys("CTRL", "W")
  end
end)
o.bind("SUPER + ALT + W", "Close window", hl.dsp.window.close())

-- Super+T: new tab (Cmd+T). Was "Toggle window floating/tiling", which moves to Super+Alt+T.
hl.unbind("SUPER + T")
o.bind("SUPER + T", "New tab", function()
  if in_terminal() then send_keys("CTRL SHIFT", "T") else send_keys("CTRL", "T") end
end)
o.bind("SUPER + ALT + T", "Toggle window floating/tiling", hl.dsp.window.float({ action = "toggle" }))

-- Super+Shift+T: reopen the last closed tab (Cmd+Shift+T).
o.bind("SUPER + SHIFT + T", "Reopen closed tab", function() send_keys("CTRL SHIFT", "T") end)

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
  for i = 1, #monitors do
    if monitors[i].name == active.name then return (i - 1) * 10 end
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

-- Pin each monitor's ten workspaces to it, so a workspace created by a window rule or a
-- script (not just Super+N) lands on its own monitor, and move any that ended up elsewhere.
-- Redone when monitors change.
-- Numeric loops over #list, not ipairs: Omarchy's keybinding menu (Super+K) runs this file
-- against a stub `hl` whose calls return an object that's never nil, so ipairs on it never ends.
local workspace_pins = {}
local function pin_workspaces()
  for _, rule in ipairs(workspace_pins) do rule:set_enabled(false) end
  workspace_pins = {}
  local monitors = hl.get_monitors()
  table.sort(monitors, function(a, b) return a.x < b.x end)
  for i = 1, #monitors do
    local m = monitors[i]
    for n = 1, 10 do
      local id = tostring((i - 1) * 10 + n)
      table.insert(workspace_pins, hl.workspace_rule({ workspace = id, monitor = m.name }))
      local ws = hl.get_workspace(id)
      if ws and ws.monitor and ws.monitor.name ~= m.name then
        hl.dispatch(hl.dsp.workspace.move({ workspace = id, monitor = m.name }))
      end
    end
  end
end
pin_workspaces()
hl.on("hyprland.start", pin_workspaces)
hl.on("monitor.added", pin_workspaces)
hl.on("monitor.removed", pin_workspaces)

-- Cycle only through this monitor's workspaces.
hl.unbind("SUPER + TAB")
hl.unbind("SUPER + SHIFT + TAB")
hl.unbind("SUPER + mouse_down")
hl.unbind("SUPER + mouse_up")
o.bind("SUPER + TAB", "Next workspace on this monitor", hl.dsp.focus({ workspace = "m+1" }))
o.bind("SUPER + SHIFT + TAB", "Previous workspace on this monitor", hl.dsp.focus({ workspace = "m-1" }))
o.bind("SUPER + mouse_down", "Next workspace on this monitor", hl.dsp.focus({ workspace = "m+1" }))
o.bind("SUPER + mouse_up", "Previous workspace on this monitor", hl.dsp.focus({ workspace = "m-1" }))

-- Host-specific extras (e.g. mainpc's Windows VM workspaces), when that host provides them.
local windows_vm = os.getenv("HOME") .. "/.config/hypr/windows-vm.lua"
local f = io.open(windows_vm)
if f then f:close(); require("hypr.windows-vm") end
