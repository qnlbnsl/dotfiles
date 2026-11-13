#!/usr/bin/env python3
"""Fake uinput mouse and Super key for testing overview drags (arch/overview/HANDOFF.md).

Arguments are steps, run in order:
  warp:X,Y            put the cursor at X,Y (global layout coordinates) and nudge it for hover
  move:DX,DY[,N,MS]   N relative moves of DX,DY, MS apart (default 1 and 10)
  down / up           left button;  sdown / sup  Super key
  sleep:MS  shot:PATH (grim)  sh:CMD

Moves go through libinput acceleration; for exact distances run first
  hyprctl eval 'hl.config({input = {force_no_accel = true}})'   (hyprctl reload undoes it)
The devices use vendor 0xfeed: keyd's Wispr Flow rule grabs 1234:5678 and turned the
fake Super into stray shortcuts (btop opened).

Example, Super+drag 400 px left:  fakemouse.py warp:1500,800 sdown down move:-10,0,40,12 up sup
"""
import fcntl, os, struct, subprocess, sys, time
EV_SYN, EV_KEY, EV_REL = 0, 1, 2
BTN_LEFT, KEY_LEFTMETA = 0x110, 125
fd = os.open("/dev/uinput", os.O_WRONLY | os.O_NONBLOCK)
fcntl.ioctl(fd, 0x40045564, EV_KEY); fcntl.ioctl(fd, 0x40045564, EV_REL)
for k in (BTN_LEFT, 0x111): fcntl.ioctl(fd, 0x40045565, k)
for r in (0, 1): fcntl.ioctl(fd, 0x40045566, r)
fcntl.ioctl(fd, 0x405c5503, struct.pack("HHHH80sI", 3, 0xfeed, 0x0001, 1, b"ld-fake-mouse", 0))
fcntl.ioctl(fd, 0x5501)
kfd = os.open("/dev/uinput", os.O_WRONLY | os.O_NONBLOCK)
fcntl.ioctl(kfd, 0x40045564, EV_KEY)
for k in [KEY_LEFTMETA] + list(range(16, 26)): fcntl.ioctl(kfd, 0x40045565, k)
fcntl.ioctl(kfd, 0x405c5503, struct.pack("HHHH80sI", 3, 0xfeed, 0x0002, 1, b"ld-fake-keyboard", 0))
fcntl.ioctl(kfd, 0x5501)
def kev(c, v): os.write(kfd, struct.pack("llHHi", 0, 0, EV_KEY, c, v)); os.write(kfd, struct.pack("llHHi", 0, 0, 0, 0, 0))
def ev(t, c, v): os.write(fd, struct.pack("llHHi", 0, 0, t, c, v))
def syn(): ev(EV_SYN, 0, 0)
time.sleep(0.8)
try:
    for step in sys.argv[1:]:
        name, _, arg = step.partition(":")
        if name == "warp":
            x, y = arg.split(",")
            subprocess.run(["hyprctl", "dispatch", f"hl.dsp.cursor.move({{x = {x}, y = {y}}})"], capture_output=True)
            ev(EV_REL, 0, 1); syn(); time.sleep(0.02); ev(EV_REL, 0, -1); syn()
        elif name == "move":
            p = [int(v) for v in arg.split(",")]
            dx, dy, n, ms = (p + [1, 10])[:4] if len(p) == 2 else (p + [10])[:4]
            for _ in range(n):
                ev(EV_REL, 0, dx); ev(EV_REL, 1, dy); syn(); time.sleep(ms / 1000)
        elif name in ("down", "up"):
            ev(EV_KEY, BTN_LEFT, 1 if name == "down" else 0); syn()
        elif name in ("sdown", "sup"):
            kev(KEY_LEFTMETA, 1 if name == "sdown" else 0)
        elif name == "sleep":
            time.sleep(int(arg) / 1000)
        elif name == "shot":
            subprocess.run(["grim", arg])
        elif name == "sh":
            subprocess.run(arg, shell=True)
        time.sleep(0.03)
finally:
    time.sleep(0.2)
    fcntl.ioctl(fd, 0x5502); os.close(fd); fcntl.ioctl(kfd, 0x5502); os.close(kfd)
