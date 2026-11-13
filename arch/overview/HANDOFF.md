# Mission Control: handoff

Written 2026-11-04, updated 2026-11-13. Steps 1-3 of the build order are done (3 needs polish)
and a first version of step 4 works; see "Build order" and "Improvements to make". Line numbers
are as of 2026-11-04. To resume, read this file, then start at "Improvements to make".

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
- Closing a desktop in the middle shifts the later ones down (confirmed 2026-11-09), so their `Super+N` changes.
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
   **Done 2026-11-09 within a monitor.** `ws-layout reorder <from> <to>` and `ws-layout close <ws>` do the work, layouts included; in the overview, dragging a desktop thumbnail (from anywhere on it, its windows too) reorders it macOS-style: the desktop leaves the strip, a copy follows the cursor anywhere on the screen (above the spread), and the other desktops slide aside to open a gap where it would land. Nothing is renumbered until the drop. On the drop the copy settles into the gap and the strip holds that order (and its size) while `ws-layout` moves the windows, then snaps to the real state. The owner asked for this on 2026-11-09 after the first version only framed the target desktop. The ✕ sits on the hovered thumbnail's top-left corner (not on "New Desktop", not when there's only one desktop). Errors from `ws-layout` become a notification. Tested by driving a fake uinput mouse (the script is described under Findings).
   - Changed on purpose: dragging a window inside a strip thumbnail now moves the whole desktop, like the macOS Spaces bar. Single windows are still dragged in the spread below. Click (focus) and middle click (close) on strip windows still work.
   - Closing joins the two desktops side by side, each half keeping its layout.
   - A desktop holding the Windows VM's Looking Glass window (1 or 11 while it runs) can't be moved or shifted: `hypr/windows-vm.lua` would pull it back. `ws-layout` refuses with a notification.
   - **TODO (owner, 2026-11-09): stop the jumping while `ws-layout` runs.** Focus (and the cursor) go back and forth during a reorder, because each window inserted on a desktop that's on screen focuses the window it splits, and every insertion moves the cursor (see "What step 1 found"). Ideas, untested: rebuild a shown desktop while it's hidden (only hidden desktops split by cursor, so no focus changes), e.g. show a neighbouring empty desktop on that monitor during the move and switch back at the end; batch all insertions of one desktop into a single `hyprctl --batch` (positions can be computed from the tree instead of read back between steps); hide the cursor during the move.
   - Dragging a desktop to the other monitor: done in step 3.
3. **Cross-monitor drag and real layouts. Working 2026-11-09, needs polish:**
   - One `HyprlandFocusGrab` over all monitors' overviews (in `Overview.qml`). With one grab per monitor, handed over when the focused monitor changed, the hand-over took the pointer away from a drag that crossed monitors.
   - The drag is shared through `GlobalStates.crossDrag` (what is dragged) and `crossDragPos` (cursor in global layout coordinates). Each monitor's widget follows it; the release goes to the source, which asks the widget with a target for its drop plan. Qt's `Drag` is gone.
   - Windows: a spread window can be dropped on the other monitor's strip (any desktop or New Desktop). A ghost of the window follows the cursor there.
   - Desktops: dragging a strip thumbnail over the other monitor closes its gap at home and opens one in the other strip, which grows by one while it's there. Dropping runs `ws-layout reorder <from> <to>`. The other monitor gets a ghost built from the desktop's windows (a `ShaderEffectSource` can't cross windows).
   - The spread places windows by real position at one uniform scale, so a half and two quarters look like that. Floating windows sit on top.
   - The eighth-of-a-screen zone is gone: drops on a window split it in half.
   - Tested with the uinput mouse: a window from the left spread to the right strip's New Desktop, and desktop 8 (two stacked windows) to the right monitor's New Desktop (it became 16; mid-drag frames show the left gap closed and the right one open). The owner then tried both directions: they work but need more work (details to come from the owner).
   - Known: while a window is on the other monitor, its tile in the source spread is off-surface (invisible). The extra thumbnail in the target strip is labelled with its number, not "New Desktop".
4. **Live rearranging on the normal desktop. First version working 2026-11-13** (not committed yet):
   - `modules/overview/LiveDrag.qml` in the overview shell, plus the `SUPER + mouse:272` binds at
     the end of `hypr/bindings.lua`. Super+drag no longer uses Hyprland's `window.drag()`.
   - The press bind calls `qs ipc -c overview call livedrag start X Y` (cursor from
     `hl.get_cursor_pos()`). The release is caught by a one-off bind on the bare `mouse:272`
     (`release`, `ignore_mods`) made inside the press bind: a `SUPER + mouse:272` release bind
     doesn't fire when Super is let go first. It calls `livedrag drop X Y` and unbinds itself.
   - While the button is held the real windows rearrange (changed 2026-11-13 after the owner
     saw the first version's copies zoom instead of resize): once the cursor rests in a zone for
     70 ms the dragged window is really put where the drop would put it, so the other windows
     resize and redraw at their new size. A frame marks the dragged window's new place and a
     small copy of it follows the cursor. Leaving every zone, or a swap, puts it back in its own
     place (an insertion next to its old sibling, or `ws-layout apply` of a layout recorded at
     the start when the sibling was a whole subtree). A swap still happens on the drop, shown
     meanwhile with copies at actual size (clipped, not zoomed) and a glass slot. Floating
     windows follow the cursor for real (throttled to one move per 70 ms).
   - Each change is one `hyprctl --batch`, run one at a time; the newest wanted state wins. The
     drop waits for the last one. Focusing the window to split warps the cursor, so
     `cursor:no_warps` is on while a window is placed.
   - Where it lands, judged against the desktop with the dragged window taken out: near an edge
     of the window under the cursor, that window splits in half and the dragged one takes that
     side; in the middle (same desktop only) the two swap; on an empty desktop it fills it.
     Works across monitors. Floating windows are moved to the drop point.
   - The layout is predicted with ws-layout's tree-from-geometry method ported to JS. The drop
     is one `hyprctl --batch`: move the window to `special:ws-layout`, set dwindle options
     (`force_split`, `split_width_multiplier`, ratio 1), focus the target, move the window back,
     restore the options, focus the dragged window.
   - Tested with `arch/overview/fakemouse.py` on throwaway `foot --app-id lt-N` windows: split
     left of a full-height window, split left inside a stacked pair, swap in a column, swap side
     by side, a window to the other monitor's desktop (split below its window). The predictions
     matched the result except for a few px (502/498 instead of 503/503).
   - What the prototype found (tested): with a press consumed by a bind Hyprland gives the
     pointer to no surface, so the overlay gets no motion. A `HyprlandFocusGrab` over all the
     overlay windows fixes that (motion arrives on both monitors). But if the overlay takes
     keyboard focus, the release bind doesn't fire, so the overlay has none (no Escape).
   - Crossing monitors (fixed 2026-11-13, after the owner found Super+drag couldn't reach the
     left monitor): the grab doesn't move the pointer to the other monitor's overlay while the
     button is held, and the source overlay gets no motion outside its own surface. So when no
     surface motion has come for 40 ms, `LiveDrag.qml` polls `hyprctl cursorpos -j` (every
     16 ms at most) until it does. Tested right to left with the fake mouse (preview and slot on
     the left monitor, the source desktop closing up on the right).
   - `qs ipc -c overview call livedrag setTrace true` logs moves, applied states and the drop
     (`qs log -c overview -r 'qml.debug=true'`); `setDryRun true` also stops anything moving.
   - Old: `setDryRun true` logged the plan as it changes and the
     drop's commands (`qs log -c overview -r 'qml.debug=true'`) without moving anything.

**What step 1 found about Hyprland 0.56.2** (tested)
- Dwindle doesn't expose its tree (a window's `layout` field in Lua only has the layout name), so the tree comes from geometry. The root box is the work area: windows sit inside it by `border_size`, and the split line is the middle of the gap between windows. With that model the ratios come out exact.
- `hl.dsp.layout(...)` messages (`togglesplit` etc.) only work on the current workspace, even with a `window` argument. `ws-layout` instead sets dwindle options for each insertion: `split_width_multiplier` 0.01 or 100 forces side by side or stacked, `force_split = 2` puts the new window second, `default_split_ratio` sets the share. It puts them back after.
- Which window a new arrival splits: on a hidden desktop, the window under the cursor; on a desktop that's on screen, the focused window (`use_active_for_splits`). With `use_active_for_splits = false` it split the first window every time.
- `hl.dsp.window.fullscreen({ mode, action = "set"|"unset", window })` works on hidden windows, but the mode must match (`maximized` for fullscreen 1). `fullscreen_state` did nothing.
- Testing the overview without a real mouse: `/dev/uinput` is writable by the user (ACL), so a short Python script can create a uinput mouse with raw ioctls (no python-evdev installed), warp with `hl.dsp.cursor.move`, nudge to get hover, then press, move relatively and release. `grim` during the drag shows the visuals. Saved since 2026-11-13 as `arch/overview/fakemouse.py` (with a fake Super key; see its notes on keyd and acceleration). It moves the real cursor, so don't run it while the owner is using the machine.
- `hyprctl eval` can't return values, but an `error(...)` message comes back, which is handy for probing the Lua API.
- `ws-layout apply` moves the cursor (and on an on-screen desktop the focus) for each window and puts them back. Fine for a drop; if it shows during reordering, look at hiding the cursor.

## Improvements to make

Collected 2026-11-13. "Owner" marks what the owner reported; the rest came out of building step 4.

**Mission Control (overview)**
1. (Owner) Dragging a window from the spread (or anywhere) onto an empty desktop in the strip
   inserts a new desktop instead of moving the window onto that empty desktop. It should move
   the window there. Not investigated yet; start with how a window drop on the strip picks
   "insert desktop" versus "move to desktop" (`OverviewWidget.qml`, the cross-drag drop plan).
2. (Owner) Step 3 needs more work in general; details still to come from the owner.
3. From step 3: while a window is over the other monitor its tile in the source spread is
   invisible, and the extra thumbnail in the target strip shows a number, not "New Desktop".
4. From step 2: focus and the cursor jump while `ws-layout` reorders (ideas in step 2).

**Live rearranging (step 4)**
5. Drops can only split one window. Add zones at the desktop's edges that split the whole
   desktop (e.g. a full-height column on the right), which today can't be made by dragging.
6. No way to cancel mid-drag (the overlay can't take keyboard focus, see step 4). Dropping back
   on the window's own place does nothing, which works as a cancel for now. A temporary
   Escape bind made in the press bind could do it, but Super+Escape is Omarchy's system menu.
7. The overlay appears roughly 300 ms after the press (`qs ipc` start, mapping the surfaces,
   the grab). Keeping the overlay mapped but empty and input-transparent when idle might cut it.
8. Floating windows: untested. They follow the cursor in steps (one move per 70 ms), not
   smoothly like the old `window.drag()`. Maybe keep `window.drag()` for them.
9. Swap: Hyprland's swap dispatcher run by hand once gave a layout that wasn't a plain swap of
   the two windows (with a nested split); the overlay's swaps matched. Check more layouts.
10. Fixed (owner, 2026-11-13): the other windows zoomed instead of resizing. They now really
    resize during the drag. Left over: the small copy under the cursor showed blank in a test
    once the window was moved; and while a window is parked in `special:ws-layout` between two
    placements, a crash of the overview shell would leave it there.
11. Fullscreen and maximized windows aren't handled: a desktop with one can't be a drop target,
    and a fullscreen window can't be dragged. Groups (overlapping windows) block it too.
12. If the overview shell isn't running, Super+drag does nothing (no fallback to `window.drag()`).
13. Super+click without moving does nothing (the old drag focused nothing either).
14. Only lightly tried with a real mouse (the owner: within a monitor it works).
15. On the other monitor the cursor is polled by spawning `hyprctl` (up to ~60 a second while
    dragging there). Reading Hyprland's request socket directly (`Quickshell.Io` Socket on
    `$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket.sock`) would be cheaper.
16. (Owner) Plain drags without Super (an app's title bar or tab strip) are Hyprland's own
    move and don't show the preview. Hyprland has no event for a drag starting; it would need
    watching for the window moving after a left press, and fixing up Hyprland's own drop.

## Open questions for the owner

1. Should `Super+Alt+W` stay? It closes a window whatever its tabs, which is an exception to "only `Super+Q` quits".
2. Should live rearranging also come to Mission Control later? The owner said it "could be done" there but prefers the current thumbnail behaviour for now.

## State when this was written

Steps 1-3 are committed. A first version of step 4 works and is saved to `macos.patch` and
`hypr/bindings.lua` but not committed (2026-11-13). Next: the owner tries step 4 with a real
mouse, then the list under "Improvements to make".

## Warnings

- Don't test `Super+W` in the `org.omarchy.agent` window. With one tab, it closes that window and ends the Claude session.
