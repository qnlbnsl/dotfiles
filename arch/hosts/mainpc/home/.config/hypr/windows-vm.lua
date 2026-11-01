-- Windows 11 VM (arch/vm) as each monitor's first workspace: Windows screen 1 on workspace 1
-- (left monitor), screen 2 on 11 (right monitor), screen 3 on 21. Each Windows screen is its
-- own Looking Glass window: looking-glass-client, looking-glass-client-2, -3 (app ids set by
-- windows-desktop). Switching to one of those workspaces brings its window back if it was
-- moved, or opens the clients if the VM runs but they aren't open. Starting a stopped VM is
-- explicit (bar icon / `windows-desktop`), so logging in doesn't grab the RTX A1000 from host
-- AI work.
-- Loaded from bindings.lua when this file exists (mainpc only).

local MAX_SCREENS = 3

local function lg_class(screen)
  return screen == 1 and "looking-glass-client" or ("looking-glass-client-" .. screen)
end

o.window("^looking-glass-client(-[0-9]+)?$", {
  fullscreen = true,
  idle_inhibit = "fullscreen",
  tag = "-default-opacity",
  opacity = "1 1",
})
for screen = 1, MAX_SCREENS do
  o.window("^" .. lg_class(screen) .. "$", { workspace = tostring((screen - 1) * 10 + 1) .. " silent" })
end

local function find_window(class)
  for _, w in ipairs(hl.get_windows()) do
    if w.class == class then return w end
  end
end

-- Follow the VM: make room on each monitor's first workspace while it runs, put things
-- back when it stops (windows-desktop --watch).
hl.on("hyprland.start", function()
  hl.exec_cmd(os.getenv("HOME") .. "/.local/bin/windows-desktop --watch")
  hl.exec_cmd(os.getenv("HOME") .. "/.local/bin/windows-cursor-bridge")
end)

-- Mouse jumping: a Looking Glass window only sees the Windows cursor while it's on its own
-- screen, so entering another screen's window left the cursor stranded on the old screen
-- for a few seconds. When focus moves onto a Windows screen's window, send that screen and
-- where the mouse is inside the window; lg-screens.ps1 in Windows puts the cursor there
-- (relayed by windows-cursor-bridge).
local function xy(v)
  if type(v) ~= "table" then return nil end
  return v.x or v[1], v.y or v[2]
end

hl.on("window.active", function()
  local w = hl.get_active_window()
  if not w or not w.class then return end
  local screen
  if w.class == "looking-glass-client" then
    screen = 1
  else
    screen = tonumber(w.class:match("^looking%-glass%-client%-(%d+)$"))
  end
  if not screen then return end

  local cursor = hl.get_cursor_pos()
  local ax, ay = xy(w.at)
  local sw, sh = xy(w.size)
  if not (cursor and ax and sw and sw > 0 and sh > 0) then return end
  local fx = math.min(math.max((cursor.x - ax) / sw, 0), 1)
  local fy = math.min(math.max((cursor.y - ay) / sh, 0), 1)
  hl.exec_cmd(string.format("printf '%%d %%.4f %%.4f' %d %f %f | socat -u - UNIX-SENDTO:%s/windows-cursor.sock",
    screen, fx, fy, os.getenv("XDG_RUNTIME_DIR") or "/tmp"))
end)

hl.on("workspace.active", function()
  local ws = hl.get_active_workspace()
  if not ws or ws.id < 1 or ws.id % 10 ~= 1 then return end
  local screen = (ws.id - 1) // 10 + 1
  if screen > MAX_SCREENS then return end

  local w = find_window(lg_class(screen))
  if not w then
    hl.exec_cmd(os.getenv("HOME") .. "/.local/bin/windows-desktop --show")
  elseif not (w.workspace and w.workspace.id == ws.id) then
    hl.dispatch(hl.dsp.window.move({ workspace = tostring(ws.id), window = "address:" .. w.address, follow = false }))
  end
end)
