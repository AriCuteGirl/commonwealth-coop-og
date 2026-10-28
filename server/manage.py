#!/usr/bin/env python3
"""Command-line admin tool for the Commonwealth Co-op server (used by Server Manager).

Every command prints one JSON object. Errors: {"ok": false, "error": "..."}, exit code 1.
The server (FathersFallout server, unmodified) keeps players in memory and logs joins, leaves and
a status line every 30 s to data/server.log; this tool reads that log.

usage: manage.py [--root DIR] <command> [args]

  info                 game, version, players online, uptime
  players              everyone online (from the log since the last server start)
  player <name>        one row from "players"
  settings             server-name, player-limit, tick-rate, password set or not (config.json)
  set <key> <value>    change server-name, player-limit, tick-rate or password (restart to apply)
  backup|backups|restore   nothing to back up (players live in memory): ok
  logs [lines]         last lines of data/server.log (default 100)

--root is the folder with start.sh (default: the folder of this file). Server Manager passes it
because it runs this script through "python3 -" over SSH.
"""
import json
import os
import re
import sys
import time

VERSION = "1.0.0"
GAME = "fallout4-coop-og"
STALE = 90  # no status line for this long: the server isn't running (it logs one every 30 s)
TS = re.compile(r"^\[(\d{4}-\d\d-\d\d \d\d:\d\d:\d\d)")
EDITABLE = {"server-name": str, "player-limit": int, "tick-rate": int, "password": str}


def out(obj, code=0):
    print(json.dumps(obj, separators=(",", ":")))
    sys.exit(code)


def when(line):
    m = TS.match(line)
    return int(time.mktime(time.strptime(m.group(1), "%Y-%m-%d %H:%M:%S"))) if m else None


def read_log(root):
    try:
        with open(os.path.join(root, "data", "server.log"), errors="replace") as f:
            return f.read().splitlines()
    except FileNotFoundError:
        return []


def state(root):
    lines = read_log(root)
    start = 0
    for i, line in enumerate(lines):
        if "] Initializing on port" in line:
            start = i
    online, last_status, started = {}, None, None
    for line in lines[start:]:
        t = when(line)
        if started is None and t:
            started = t
        m = re.search(r"\[\+\] (.+) joined  \(ID (\d+)\)", line)
        if m:
            online[m.group(1)] = {"id": int(m.group(2)), "name": m.group(1), "since": t or 0}
            continue
        m = re.search(r"\[-\] (.+) left ", line)
        if m:
            online.pop(m.group(1), None)
            continue
        if "[status]" in line or "] Initializing on port" in line:
            last_status = t
    running = last_status is not None and time.time() - last_status < STALE
    if not running:
        online = {}
    rows = []
    for p in online.values():
        p = dict(p)
        p["minutes"] = max(0, int((time.time() - p["since"]) // 60)) if p["since"] else 0
        rows.append(p)
    return {"running": running, "started": started, "players": rows}


def load_cfg(root):
    try:
        with open(os.path.join(root, "config.json")) as f:
            return json.load(f)
    except FileNotFoundError:
        return {}


def main(argv):
    root = os.path.dirname(os.path.abspath(__file__))
    if len(argv) >= 2 and argv[0] == "--root":
        root = os.path.expanduser(argv[1])
        argv = argv[2:]
    if not argv:
        out({"ok": False, "error": "no command"}, 1)
    cmd, args = argv[0], argv[1:]
    if cmd == "info":
        st = state(root)
        up = int(time.time() - st["started"]) if st["running"] and st["started"] else 0
        out({"ok": True, "game": GAME, "version": VERSION, "running": st["running"],
             "players": len(st["players"]), "uptime": up})
    if cmd == "players":
        out({"ok": True, "now": int(time.time()), "players": state(root)["players"]})
    if cmd == "player":
        if not args:
            out({"ok": False, "error": "usage: player <name>"}, 1)
        for row in state(root)["players"]:
            if row["name"] == args[0]:
                out({"ok": True, "player": row})
        out({"ok": False, "error": "no such player online"}, 1)
    if cmd == "settings":
        cfg = load_cfg(root)
        out({"ok": True, "settings": {
            "server-name": cfg.get("server-name", ""), "player-limit": cfg.get("player-limit", 8),
            "tick-rate": cfg.get("tick-rate", 60), "password_set": bool(cfg.get("password"))}})
    if cmd == "set":
        if len(args) != 2 or args[0] not in EDITABLE:
            out({"ok": False, "error": "usage: set <server-name|player-limit|tick-rate|password> <value>"}, 1)
        key, raw = args
        try:
            value = EDITABLE[key](raw)
        except ValueError:
            out({"ok": False, "error": f"{key} must be a number"}, 1)
        if key == "player-limit" and not 1 <= value <= 100:
            out({"ok": False, "error": "player-limit must be 1-100"}, 1)
        if key == "tick-rate" and not 10 <= value <= 120:
            out({"ok": False, "error": "tick-rate must be 10-120"}, 1)
        cfg = load_cfg(root)
        cfg[key] = value
        path = os.path.join(root, "config.json")
        with open(path + ".tmp", "w") as f:
            json.dump(cfg, f, indent=4)
        os.replace(path + ".tmp", path)
        out({"ok": True, "set": key, "restart_required": True})
    if cmd in ("backup", "backups", "restore"):
        out({"ok": True, "backups": [], "note": "players live in memory, nothing to back up"})
    if cmd == "logs":
        n = int(args[0]) if args and args[0].isdigit() else 100
        out({"ok": True, "lines": read_log(root)[-max(1, min(n, 2000)):]})
    out({"ok": False, "error": f"unknown command {cmd}"}, 1)


if __name__ == "__main__":
    main(sys.argv[1:])
