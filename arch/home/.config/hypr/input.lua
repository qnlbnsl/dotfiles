-- Keep only your personal input overrides here. Uncommented settings below
-- replace Omarchy's defaults.

-- Keyboard layout and options.
-- See https://wiki.hypr.land/Configuring/Basics/Variables/#input
-- hl.config({
--   input = {
--     -- Use multiple keyboard layouts and switch between them with Left Alt + Right Alt.
--     kb_layout = "us,dk,eu",
--     kb_options = "compose:caps,shift:both_capslock_cancel,grp:alts_toggle",
--
--     -- Use a specific keyboard variant if needed (e.g. intl for international keyboards).
--     kb_variant = "intl",
--
--     -- Change speed of keyboard repeat.
--     repeat_rate = 40,
--     repeat_delay = 250,
--
--     -- Start with numlock on by default.
--     numlock_by_default = true,
--
--     -- Increase sensitivity for mouse/trackpad (default: 0).
--     sensitivity = 0.35,
--
--     -- Turn off mouse acceleration (default: adaptive).
--     accel_profile = "flat",
--
--     touchpad = {
--       -- Use natural (inverse) scrolling.
--       natural_scroll = true,
--
--       -- Use two-finger clicks for right-click instead of lower-right corner.
--       clickfinger_behavior = true,
--
--       -- Control the speed of your scrolling.
--       scroll_factor = 0.4,
--
--       -- Enable the touchpad while typing.
--       disable_while_typing = false,
--
--       -- Left-click-and-drag with three fingers.
--       drag_3fg = 1,
--     },
--   },
-- })

-- App-specific touchpad scroll speeds.
-- o.window("(Alacritty|kitty|foot)", { scroll_touchpad = 1.5 })
-- o.window("com.mitchellh.ghostty", { scroll_touchpad = 0.2 })

-- Enable touchpad gestures for changing workspaces.
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Gestures/
-- hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- Enable touchpad gestures for moving focus (helpful on scrolling layout).
-- hl.gesture({ fingers = 3, direction = "left", action = function() hl.dispatch(hl.dsp.focus({ direction = "l" })) end })
-- hl.gesture({ fingers = 3, direction = "right", action = function() hl.dispatch(hl.dsp.focus({ direction = "r" })) end })

-- Gestures only fire when the held modifiers match exactly, and Wispr Flow dictation (held
-- Caps Lock = Ctrl+F19 via keyd) holds Ctrl, so every swipe is registered bare and with Ctrl.
local function swipe(spec)
  hl.gesture(spec)
  hl.gesture({ fingers = spec.fingers, direction = spec.direction, action = spec.action, mods = "CTRL" })
end

-- Workspace swipes: 3 or 4 fingers left = next workspace, right = previous.
for _, fingers in ipairs({ 3, 4 }) do
  swipe({ fingers = fingers, direction = "horizontal", action = "workspace" })
end

-- Mission Control: 3 or 4 fingers up opens the desktop overview, down closes it.
-- The overview is quickshell-overview (~/.config/quickshell/overview), started in autostart.lua.
local function overview(action)
  return function() hl.dispatch(hl.dsp.exec_cmd("qs ipc -c overview call overview " .. action)) end
end
for _, fingers in ipairs({ 3, 4 }) do
  swipe({ fingers = fingers, direction = "up", action = overview("open") })
  swipe({ fingers = fingers, direction = "down", action = overview("close") })
end

-- Tap-and-drag (double-tap, hold, move) keeps going if you lift and put your finger back
-- down quickly, so a drag can cross the whole screen (e.g. windows onto Mission Control desktops).
hl.config({ input = { touchpad = { drag_lock = 1 } } })

-- Mac-style "natural" scrolling: content follows your fingers. Touchpads only, so a mouse
-- wheel keeps its usual direction.
hl.config({ input = { touchpad = { natural_scroll = true } } })

-- Mac-like workspace swipes: commit once past 20% of the distance (stock 50%) or on a
-- gentler flick, instead of snapping back. The slide itself is in looknfeel.lua.
hl.config({ gestures = { workspace_swipe_cancel_ratio = 0.2, workspace_swipe_min_speed_to_force = 10 } })
