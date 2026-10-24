# arch/

Personal desktop config for Arch/Omarchy (Hyprland). Everything here is the
source of truth: the live files in `~/.config` are symlinks into this folder,
so an Omarchy update, `omarchy refresh`, or a reinstall can't lose it.

```sh
make arch-config   # link ~/.config files + set up the overview (also runs with `make` on Hyprland machines)
make arch-system   # install /etc and /usr/lib files with sudo (keyd, uinput, udev)
make arch-wispr    # build + install the newest Wispr Flow (also runs with `make` on Hyprland machines)
```

## Layout

```
arch/
├── home/                     shared, symlinked into ~ (file by file)
│   └── .config/
│       ├── omarchy/themes/macos-graphite/   the macOS theme
│       ├── hypr/             only files that differ from Omarchy's stock copies
│       │   ├── input.lua         trackpad gestures (workspace swipes, Mission Control)
│       │   ├── looknfeel.lua     Wispr Flow window rules, macOS shape, gaps
│       │   ├── bindings.lua      macOS-style shortcuts (screenshots, quit)
│       │   └── autostart.lua     starts the overview
│       └── quickshell/overview/config.json
│   └── .local/bin/
│       ├── mac-quit-app      Super+Q: close every window of the focused app
│       └── slurp             area-picker colors (wraps /usr/bin/slurp)
├── system/                   shared, copied to / with sudo (keyd, udev, modules-load)
├── wispr-flow/               Wispr Flow build: install.sh + PKGBUILD.in
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

Scrolling is "natural" (Mac direction) on touchpads; mouse wheels are unchanged.

These are Hyprland `hl.gesture` rules, so they work on any libinput touchpad,
including an Apple Magic Trackpad.

## Keyboard shortcuts (`bindings.lua`)

Omarchy's stock bindings plus macOS equivalents:

| Keys | Action |
|---|---|
| Super+Shift+3 | screenshot of the whole screen (saved to ~/Pictures and copied) |
| Super+Shift+4 | screenshot of a dragged area |
| Super+Q | quit the focused app: closes all its windows (same window class) |
| Super+W | close just this window (Omarchy stock) |

These replace "move window to workspace 3/4" on Super+Shift; Super+Shift+Alt+3/4 still move a window there (without following it).

The area picker is slurp. `.local/bin/slurp` wraps it so it no longer washes the screen
white (slurp's default, which hid the cursor): a 26% mid-gray veil that contrasts both the
cursor's dark and light edges, a light glass selection, a
hairline border. It's first on PATH, so Omarchy's screenshot and recording pickers use it.

## Wispr Flow install (`make arch-wispr`)

`wispr-flow/install.sh` builds [wispr-flow-linux](https://github.com/wispr-flow-linux/wispr-flow-linux)
from the newest Wispr Flow Windows installer (Wispr's `latest.json` manifest, sha256-checked)
and installs it as the `wispr-flow-appimage` package, the same layout the AUR package uses.
The AUR package only follows wispr-flow-linux releases, which lag Wispr's own.

- The checkout and build cache live in `~/.cache/wispr-flow-linux`.
- If the newest installer doesn't build (one of the project's patches stops matching),
  it falls back to the version the project pins, and remembers the failure in
  `~/.cache/wispr-flow-linux.failed` so it isn't retried until the project changes.
  `PINNED=1` builds the pin directly.
- Does nothing when that version is already installed; `FORCE=1` rebuilds.
- Stops a running Wispr Flow before installing and starts it again afterwards.
- Run `make arch-system` once on a new machine for the uinput/udev/keyd setup.

## Wispr Flow push-to-talk

Holding Caps Lock holds Ctrl+F19 (keyd, `hosts/razer-13/system/etc/keyd/razer-capslock.conf`),
and Wispr Flow's push-to-talk is Ctrl+F19 (hands-free: Ctrl+F19+Space; Wispr insists
on a modifier). F19 is unused, so the chord can't fire real Ctrl shortcuts. Swipes are
also registered with Ctrl so they work while dictating. Shift+Caps Lock is still real
caps lock. On another machine, map a key to Ctrl+F19 the same way.

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

## macOS look (`macos-graphite` theme)

`home/.config/omarchy/themes/macos-graphite/` is an Omarchy theme modelled on macOS
dark mode with the Graphite accent: neutral grays (#1e1e1e / #323232 / #464646),
Apple's system colors for the terminal palette, a faint white hairline instead of a
colored window border, white keyboard backlight, and an original graphite wallpaper
(plus links to a few stock ones). Apply with `omarchy theme set macos-graphite`;
`omarchy theme set tokyo-night` reverts.

`looknfeel.lua` adds the shape: 12px corners (`rounding_power = 3` for a squircle-ish
curve), a soft downward shadow, blur behind translucent surfaces, 1px borders, and gaps about 20% tighter than stock (4 / 8).

Fonts, icons, cursor (packages: `inter-font`, AUR `whitesur-icon-theme`, `apple_cursor`;
install with `omarchy pkg add inter-font && omarchy pkg aur add whitesur-icon-theme apple_cursor`):
- Inter for GTK UI text and Mission Control labels (the bar stays on the monospace
  Nerd Font: Omarchy's shell hard-wires it and draws its icons from it).
- WhiteSur-dark icons via the theme's `icons.theme`.
- macOS cursor: `XCURSOR_THEME` in `looknfeel.lua`, GTK via the theme-set hook.
- `hooks/theme-set.d/macos-look` re-applies the GTK font and cursor on every theme
  switch (Omarchy's own theme switch doesn't manage them).

## Notes

- keyd retypes every key through its own virtual keyboard, which libinput treats as
  external, so "ignore the touchpad while typing" silently stopped working (palm
  brushes moved the caret mid-sentence). `system/etc/libinput/local-overrides.quirks`
  marks it internal; `make arch-system` installs it and restarts keyd to apply.

- Hyprland reloads on save, but edits made through the symlink target may not
  trigger it; run `hyprctl reload && hyprctl configerrors`.
- After `make arch-system` restarts keyd, restart Wispr Flow
  (`pkill -x wispr-flow`, then relaunch).
