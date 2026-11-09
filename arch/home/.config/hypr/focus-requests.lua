-- Apps asking for focus (a herdr or Claude terminal wanting attention, a link opening in
-- the browser) no longer yank you to another monitor. On the monitor you're on, they get
-- focus straight away as before. On another monitor, focus-countdown shows a notification
-- that counts down 5 s before switching: click it to switch now, dismiss it to stay.
-- Loaded from bindings.lua.

-- With this off, a focus request marks the window urgent instead of focusing it.
hl.config({ misc = { focus_on_activate = false } })

-- Windows that must never take focus on request (their own rules already say so).
local IGNORE = {
  "^wispr%-flow$",
  "^looking%-glass%-client",
}

local function ignored(class)
  for _, pattern in ipairs(IGNORE) do
    if class:match(pattern) then return true end
  end
  return false
end

hl.on("window.urgent", function(w)
  if type(w) ~= "table" or not w.address then w = hl.get_urgent_window() end
  if not w or not w.address or w.active or ignored(w.class or "") then return end

  local active = hl.get_active_monitor()
  if active and w.monitor and w.monitor.name == active.name then
    hl.dispatch(hl.dsp.focus({ window = "address:" .. w.address }))
  else
    hl.exec_cmd(os.getenv("HOME") .. "/.local/bin/focus-countdown " .. w.address)
  end
end)
