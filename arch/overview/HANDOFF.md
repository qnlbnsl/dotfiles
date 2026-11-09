# Mission Control: handoff

Written 2026-11-04, updated 2026-11-09. Step 1 of the build order is done (`ws-layout`, below);
the rest isn't built yet. Line numbers are as of 2026-11-04.
To resume, read this file, then start at "Build order".

## Where the code is

| What | Where |
|---|---|
| Live overview code (a clone of quickshell-overview) | `~/.config/quickshell/overview`, mainly `modules/overview/` |
| Saved copy in dotfiles | `arch/overview/macos.patch` (matched the live code on 2026-11-04) |
| Save edits back to the patch | `make arch-overview-save`, then commit the patch |
| Overview settings | `arch/home/.config/quickshell/overview/config.json` |
| Keybindings | `arch/home/.config/hypr/bindings.lua` |
| Gestures | `~/.config/hypr/input.lua` |
| Record and rebuild a desktop's layout | `arch/home/.local/bin/ws-layout` (step 1) |

- The overview runs as `qs -c overview` and is opened by a 3 or 4 finger swipe up. Control it with `qs ipc -c overview call overview open|close|toggle`.
- Stack: Hyprland 0.56.2 with Lua config, dwindle layout, Quickshell 0.3.2.
- Monitors: one Samsung G9 split into two 2560x1440 halves at scale 1.25, so 2048x1152 logical each. HDMI-A-1 is on the left; the right half is a DisplayPort output whose name can change.
- Desktops 1-10 are pinned to the left monitor and 11-20 to the right. `Super+N` is per monitor.
- Dotfiles commits go straight to master with no Co-Authored-By trailer; the commit-msg hook rejects them.

## Decisions the owner has made

**Desktops**
- Reordering is an illusion: desktop numbers stay put and only their contents move. Dragging desktop 5 to position 1 moves everything accordingly.
- Reordering must also work between monitors. The UI can show whatever it needs to, as long as it looks like reordering.
- Closing a desktop moves its windows to a neighbouring desktop. Windows are not closed.
- New desktops are only created at the end of the strip. Drag one elsewhere afterwards if wanted.
- Only the tail is cleaned up: exactly one empty "New Desktop" at the end. An empty desktop in the middle stays, with no automatic gap closing. From the code this tail behaviour already works (`lastUsedWorkspace` and `visibleWorkspaceCount` in `OverviewWidget.qml`).

**Dragging**
- Inside Mission Control, keep the current left/right and "+" drop behaviour on thumbnails, not live rearranging.
- On the normal desktop, dragging a window without Mission Control should activate zones, make the other windows change to show the result, show a shadow where the window will land, and snap there on drop. This is what the owner meant by "spacing". It replaces hot corners.

**Dropped:** Control-Up, group by app, Show Desktop, App Exposé, hot corners as a separate feature.
**Maybe later:** drag a window to the top of the screen to open Mission Control.

## Findings

**Why dragging across monitors fails** (from reading the code, not reproduced)
- Each monitor has its own overview window (`Variants` in `Overview.qml`).
- Hyprland normally keeps a held click on its surface (`InputManager.cpp`, the "don't refocus" check). But `Overview.qml:63-75` moves the focus grab when the focused monitor changes, and the new grab only allows the other surface, so `SeatManager::refocusGrab` most likely takes the pointer away.
- The dragged tile and `DropArea`s also live in separate QML windows, so fixing the grab alone isn't enough.
- Planned fix: one `HyprlandFocusGrab` listing all panels with no hand-off, plus shared drag state so either monitor can draw the window and accept the drop. Global position = monitor x + `mouse.x`.
- `MissionControlWindows.qml` has no `onCanceled` handler; add one.

**Why quarters look wrong**
- `MissionControlWindows.qml:39-80` uses a best-fit grid, so a half plus two quarters shows as three tiles in a row. The fix is to place tiles by real position at a uniform scale (about 0.79).
- Drop zones are 25/50/50/25 (`OverviewWidget.qml:119`). The outer zones give a quarter of the target window, not of the screen, so dropping on a half-screen window can create an eighth by accident. Remove that zone.
- The zone that recreates a quarter is only about 23 px tall on a thumbnail.
- Drops on the same desktop are ignored (`MissionControlWindows.qml:207`, `OverviewWidget.qml:89`).

**Moving windows scrambles layouts**
- Dwindle rebuilds its tree as windows arrive, and Hyprland desktop IDs can't be renumbered, so reordering has to rebuild layouts.
- Plan: derive each desktop's split tree from window geometry (find a line that divides the rectangle, recurse), move the windows, then recreate the splits and ratios. Keep floating windows' positions and fullscreen state.
- `dropWindow()` in `OverviewWidget.qml:155-178` already does exact placement: set `default_split_ratio`, move the cursor to the target, move the window, swap if needed, then restore both.
- None of this is tested yet.

**Live rearranging on the normal desktop** (untested idea)
- Avoid a Hyprland plugin, since it could break on updates.
- `Super+mouse:272` currently uses `hl.dsp.window.drag()` (`default/hypr/bindings/tiling.lua:70`).
- Replace it with a press binding that opens an input-transparent overlay showing `ScreencopyView` previews, poll the cursor, and use a release binding to run the drop. Real windows don't move until the drop.
- Biggest risk: whether cursor tracking is smooth enough. Prototype this first.

## Build order

1. **Record and recreate layouts. Done 2026-11-09:** `ws-layout record <ws>` prints a desktop's layout as JSON (split tree with direction and ratio, floating positions, fullscreen/maximized), `ws-layout apply <ws> <file>` rebuilds it on any desktop, `ws-layout check <ws>` rebuilds in place and compares. Tested on throwaway `foot --app-id lt-N` terminals: half + two quarters, a five-window dwindle spiral, floating, fullscreen and maximized, hidden and on-screen desktops, and a move to the other monitor, all pixel-exact and with no drift on repeated rebuilds. Not handled: groups (it stops with an error) and pinned windows (skipped).
2. **Reorder and close desktops**, including between monitors. The ✕ appears on thumbnail hover. Closing moves windows to the left neighbour, or the right one if it's the first desktop.
3. **Cross-monitor window drag**, with the spread showing real layouts. Remove the eighth-of-a-screen zone.
4. **Live rearranging on the normal desktop**, starting with the prototype.

**What step 1 found about Hyprland 0.56.2** (tested)
- Dwindle doesn't expose its tree (a window's `layout` field in Lua only has the layout name), so the tree comes from geometry. The root box is the work area: windows sit inside it by `border_size`, and the split line is the middle of the gap between windows. With that model the ratios come out exact.
- `hl.dsp.layout(...)` messages (`togglesplit` etc.) only work on the current workspace, even with a `window` argument. `ws-layout` instead sets dwindle options for each insertion: `split_width_multiplier` 0.01 or 100 forces side by side or stacked, `force_split = 2` puts the new window second, `default_split_ratio` sets the share. It puts them back after.
- Which window a new arrival splits: on a hidden desktop, the window under the cursor; on a desktop that's on screen, the focused window (`use_active_for_splits`). With `use_active_for_splits = false` it split the first window every time.
- `hl.dsp.window.fullscreen({ mode, action = "set"|"unset", window })` works on hidden windows, but the mode must match (`maximized` for fullscreen 1). `fullscreen_state` did nothing.
- `hyprctl eval` can't return values, but an `error(...)` message comes back, which is handy for probing the Lua API.
- `ws-layout apply` moves the cursor (and on an on-screen desktop the focus) for each window and puts them back. Fine for a drop; if it shows during reordering, look at hiding the cursor.

## Open questions for the owner

1. Assumed, not confirmed: the ✕ on a middle desktop shifts later desktops down, as an exception to "no cleanup in the middle". The alternative is leaving an empty slot. If they shift, `Super+N` for those desktops changes.
2. Should `Super+Alt+W` stay? It closes a window whatever its tabs, which is an exception to "only `Super+Q` quits".
3. Should live rearranging also come to Mission Control later? The owner said it "could be done" there but prefers the current thumbnail behaviour for now.

## State when this was written

Everything from the 2026-11-05 session is committed and pushed. Not committed yet: this file and `ws-layout`. Other uncommitted dotfiles changes belong to the owner; leave them alone.

## Warnings

- Don't test `Super+W` in the `org.omarchy.agent` window. With one tab, it closes that window and ends the Claude session.
