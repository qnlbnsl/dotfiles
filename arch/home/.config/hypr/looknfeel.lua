-- Change the default Omarchy look'n'feel.

-- https://wiki.hypr.land/Configuring/Basics/Variables/#general
-- hl.config({
--   general = {
--     -- No gaps between windows or borders.
--     gaps_in = 0,
--     gaps_out = 0,
--     border_size = 0,
--
--     -- Change to niri-like side-scrolling layout.
--     layout = "scrolling",
--   },
-- })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#decoration
-- hl.config({
--   decoration = {
--     -- Use round window corners.
--     rounding = 8,
--
--     -- Dim unfocused windows (0.0 = no dim, 1.0 = fully dimmed).
--     dim_inactive = true,
--     dim_strength = 0.15,
--   },
-- })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#animations
-- hl.config({
--   animations = {
--     -- Disable all animations.
--     enabled = false,
--   },
-- })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#layout
-- hl.config({
--   layout = {
--     -- Avoid overly wide single-window layouts on wide screens.
--     single_window_aspect_ratio = { 1, 1 },
--   },
-- })

-- https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/
-- hl.config({
--   scrolling = {
--     -- See only one column per screen instead of two.
--     column_width = 0.97,
--   },
-- })

-- Wispr Flow: don't let its windows (e.g. the dictation pill) yank focus from the app you're typing in.
o.window("^wispr-flow$", { focus_on_activate = false })
-- Wispr Flow dictation pill: borderless, on every workspace, bottom-center, never focused.
o.window({ class = "^wispr-flow$", title = "^(Status|Flow Status Indicator)$" }, {
  tag = "-default-opacity",
  float = true,
  pin = true,
  no_initial_focus = true,
  no_focus = true,
  no_dim = true,
  no_shadow = true,
  no_blur = true,
  border_size = 0,
  opacity = "1 1",
  move = { "(monitor_w/2-window_w/2)", "(monitor_h-window_h)" },
})

-- macOS shape language: rounded "squircle-ish" corners, a soft drop shadow, frosted blur
-- behind translucent surfaces, and a 1px hairline border (its color comes from the theme:
-- hyprland_active_border in ~/.config/omarchy/themes/macos-graphite/colors.toml).
hl.config({
  general = {
    border_size = 1,
  },
  decoration = {
    rounding = 12,
    rounding_power = 3,
    shadow = {
      enabled = true,
      range = 32,
      render_power = 3,
      offset = "0 8",
      color = "rgba(00000066)",
      color_inactive = "rgba(00000038)",
    },
    blur = {
      enabled = true,
      size = 8,
      passes = 3,
      vibrancy = 0.2,
      noise = 0.015,
    },
  },
})

-- macOS cursor (apple_cursor, an Xcursor theme; Hyprland falls back to Xcursor). The GTK
-- cursor setting is applied by ~/.config/omarchy/hooks/theme-set.d/macos-look.
hl.env("XCURSOR_THEME", "macOS")

-- Tighter gaps than Omarchy's 5 / 10 (20% less), closer to macOS's edge-to-edge windows.
hl.config({ general = { gaps_in = 4, gaps_out = 8 } })

-- Omarchy turns workspace animations off, so a released swipe jumped to its end
-- (or snapped back) instantly. Slide it with a soft ease-out instead, 0.4s like macOS
-- (Apple publishes no figure; reported Spaces switches run ~0.3-0.5s, typically ~400ms).
hl.animation({ leaf = "workspaces", enabled = true, speed = 4, bezier = "easeOutQuint", style = "slide" })
