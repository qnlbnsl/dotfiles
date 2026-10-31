-- Windows 11 VM (arch/vm) as each monitor's first workspace: 1 on the left monitor, 11 on
-- the right (per-monitor numbering is in bindings.lua). Looking Glass shows one Windows
-- display, so there's a single client window and it follows you: switching to 1 or 11
-- moves it there. If the VM is running but the client isn't, it's opened. Starting a
-- stopped VM is explicit (bar icon / `windows-desktop`), so logging in doesn't grab the
-- RTX A1000 from host AI work.
-- Loaded from bindings.lua when this file exists (mainpc only).

local LG = "looking-glass-client"
local WINDOWS_WS = { [1] = true, [11] = true }

o.window("^" .. LG .. "$", {
  fullscreen = true,
  idle_inhibit = "fullscreen",
  tag = "-default-opacity",
  opacity = "1 1",
})

local function lg_window()
  for _, w in ipairs(hl.get_windows()) do
    if w.class == LG then return w end
  end
end

hl.on("workspace.active", function()
  local ws = hl.get_active_workspace()
  if not ws or not WINDOWS_WS[ws.id] then return end

  local w = lg_window()
  if not w then
    hl.exec_cmd(os.getenv("HOME") .. "/.local/bin/windows-desktop --show")
  elseif not (w.workspace and w.workspace.id == ws.id) then
    hl.dispatch(hl.dsp.window.move({ workspace = tostring(ws.id), window = "address:" .. w.address, follow = false }))
    hl.dispatch(hl.dsp.focus({ window = "address:" .. w.address }))
  end
end)
