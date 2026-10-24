# arch/

Personal desktop config for Arch/Omarchy (Hyprland). Everything here is the
source of truth: the live files in `~/.config` are symlinks into this folder,
so an Omarchy update, `omarchy refresh`, or a reinstall can't lose it.

```sh
make arch-config   # link ~/.config files + set up the overview (also runs with `make` on Hyprland machines)
make arch-system   # install /etc and /usr/lib files with sudo (keyd, uinput, udev)
```

## Layout

```
arch/
├── home/                     shared, symlinked into ~ (file by file)
│   └── .config/
│       ├── hypr/             only files that differ from Omarchy's stock copies
│       │   ├── input.lua         trackpad gestures (workspace swipes, Mission Control)
│       │   ├── looknfeel.lua     Wispr Flow window rules
│       │   └── autostart.lua     starts the overview
│       └── quickshell/overview/config.json
├── system/                   shared, copied to / with sudo (keyd, udev, modules-load)
├── hosts/<hostname>/         per-machine overrides, same home/ + system/ layout; wins over shared
│   └── razer-13/             Razer Blade: monitor scale, Caps Lock remap
└── overview/                 macOS-style workspace overview
    ├── UPSTREAM              upstream repo + pinned commit
    └── macos.patch           our changes on top of it
```

A file in `hosts/$(hostname)/home` replaces the shared one at the same path.
To set up another machine, add `hosts/<its hostname>/` with whatever differs
(e.g. `monitors.lua`) and run `make arch-config`.

## Trackpad gestures (`input.lua`)

| Gesture | Action |
|---|---|
| 3 or 4 fingers left / right | next / previous workspace (content follows fingers) |
| 3 or 4 fingers up | open the desktop overview (Mission Control) |
| 3 or 4 fingers down | close it |

These are Hyprland `hl.gesture` rules, so they work on any libinput touchpad,
including an Apple Magic Trackpad.

## Wispr Flow push-to-talk

Caps Lock sends F19 (keyd, `hosts/razer-13/system/etc/keyd/razer-capslock.conf`),
and Wispr Flow's push-to-talk is set to F19 alone (hands-free: F19 + Space).
F19 is unused, so dictation never holds real modifiers that clash with shortcuts.
Shift+Caps Lock is still real caps lock. On another machine, map a key to F19 the
same way (or set the shortcut in Wispr's settings).

## Overview (Mission Control)

[quickshell-overview](https://github.com/Shanu-Kumawat/quickshell-overview),
restyled like macOS Mission Control:

- **Workspace background**: a band across the top with one thumbnail per desktop
  in use, plus a "+ New Desktop". Labels sit above, a white ring marks the current one.
- **Desktop background**: the area below, where the current desktop's windows are
  spread out as large live previews. Hover shows the app name, click focuses,
  middle-click closes. Drag a window onto a desktop thumbnail to move it there.
  While hovering, a glass "+" slot previews where it lands: the window under the
  cursor splits (left/right if it's wide, top/bottom if tall). Moving across it goes
  through four zones: 25% | 50% | 50% | 25%, the side following the cursor.
- Starting Wispr Flow dictation (F19, i.e. Caps Lock) closes the overview so the
  text lands in the window underneath.
- Your wallpaper sits behind everything; pinned windows (like the Wispr pill) are skipped.

Both backgrounds are set in `config.json` under `overview.workspaceBackground`
(`color`, `gradientTo`, `borderColor`, `borderWidth`, `bottomPadding`) and
`overview.desktopBackground` (`color`, `gradientTo`). Colours are `#AARRGGBB`;
set `gradientTo` for a top-to-bottom gradient.

Upstream ships no licence file, so this repo keeps only our patch, not its source.

- Look and feel without code: edit `home/.config/quickshell/overview/config.json`.
- Code changes: edit the QML in `~/.config/quickshell/overview` (a git checkout
  on branch `macos`), then `make arch-overview-save` to write `macos.patch`.
- Reload after changes: `pkill -x qs; qs -c overview &` (or log out and in).
- Toggle by hand: `qs ipc -c overview call overview toggle`.

## Notes

- Hyprland reloads on save, but edits made through the symlink target may not
  trigger it; run `hyprctl reload && hyprctl configerrors`.
- After `make arch-system` restarts keyd, restart Wispr Flow
  (`pkill -x wispr-flow`, then relaunch).
