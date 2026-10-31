-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

local omarchy_gdk_scale = 2
local omarchy_monitor_scale = 1.25

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = omarchy_monitor_scale })

-- Samsung Odyssey G9 (C49G95T) in picture-by-picture: two 2560x1440 halves (27"-equivalent,
-- ~109 ppi), one per cable. Both report the same description, so match by port.
-- Preferred mode is 60Hz, so pin 120Hz; 1.25 matches the laptop's apparent text size.
-- Positions are logical (scaled) pixels: 2560 / 1.25 = 2048.
hl.monitor({ output = "HDMI-A-1", mode = "2560x1440@120", position = "0x0", scale = 1.25 })
hl.monitor({ output = "DP-3", mode = "2560x1440@120", position = "2048x0", scale = 1.25 })
