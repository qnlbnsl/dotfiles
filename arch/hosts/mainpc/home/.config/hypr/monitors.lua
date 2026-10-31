-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

local omarchy_gdk_scale = 2
local omarchy_monitor_scale = 1.25

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = omarchy_monitor_scale })

-- Samsung Odyssey G9 (C49G95T) in picture-by-picture: two 2560x1440 halves (27"-equivalent,
-- ~109 ppi), one per cable. Both halves report the same description, and the DisplayPort
-- half's port name changes (DP-3, DP-7, ...), so match both halves by description and
-- pin only the HDMI half to the left by name (the later, more specific rule wins for it).
-- Preferred mode is 60Hz, so pin 120Hz; 1.25 matches the laptop's apparent text size.
-- Positions are logical (scaled) pixels: 2560 / 1.25 = 2048.
local g9 = "desc:Samsung Electric Company LC49G95T H4ZR701561"
hl.monitor({ output = g9, mode = "2560x1440@120", position = "2048x0", scale = 1.25 })
hl.monitor({ output = "HDMI-A-1", mode = "2560x1440@120", position = "0x0", scale = 1.25 })
