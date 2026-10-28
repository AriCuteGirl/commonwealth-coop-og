#!/bin/sh
# Starts the co-op server (the FathersFallout server, built for Linux) from this folder.
# Runs inside data/ (the only writable folder under Server Manager's service): config.json and
# server.log live there. Port from F4COOP_PORT; the rest of data/config.json is kept as you edit it.
set -e
cd "$(dirname "$0")"
case "$(uname -m)" in
  aarch64|arm64) BIN=bin/linux-arm64/f4coop-server; LD=/lib/ld-linux-aarch64.so.1 ;;
  x86_64|amd64)  BIN=bin/linux-x64/f4coop-server;   LD=/lib64/ld-linux-x86-64.so.2 ;;
  *) echo "no server build for $(uname -m)" >&2; exit 1 ;;
esac
BIN="$PWD/$BIN"
mkdir -p data
cd data
python3 - "${F4COOP_PORT:-7779}" <<'EOF'
import json, os, sys
path = "config.json"
cfg = {"server-name": "Commonwealth Co-op Server", "master-server": "", "ip": "0.0.0.0",
       "run-as-service": False, "player-limit": 8, "tick-rate": 60, "password": ""}
if os.path.exists(path):
    with open(path) as f:
        cfg.update(json.load(f))
cfg["port"] = int(sys.argv[1])
cfg["log-location"] = "./server.log"
tmp = path + ".tmp"
with open(tmp, "w") as f:
    json.dump(cfg, f, indent=4)
os.replace(tmp, path)
EOF
# Status page for the health check (TCP); stops with the service (same cgroup).
python3 -B ../status.py &
# The upload may not keep the execute bit and the folder is read-only: start it through the loader.
if [ -x "$BIN" ]; then exec "$BIN"; else exec "$LD" "$BIN"; fi
