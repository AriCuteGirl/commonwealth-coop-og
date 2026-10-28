#!/bin/sh
# Starts the co-op server (the unmodified FathersFallout server, built for Linux) from this folder.
# Port from F4COOP_PORT (Server Manager sets it); the rest of config.json is kept as you edit it.
set -e
cd "$(dirname "$0")"
case "$(uname -m)" in
  aarch64|arm64) BIN=bin/linux-arm64/f4coop-server ;;
  x86_64|amd64)  BIN=bin/linux-x64/f4coop-server ;;
  *) echo "no server build for $(uname -m)" >&2; exit 1 ;;
esac
[ -x "$BIN" ] || chmod +x "$BIN"
mkdir -p data
python3 - "${F4COOP_PORT:-7779}" <<'EOF'
import json, os, sys
path = "config.json"
cfg = {"server-name": "Commonwealth Co-op Server", "master-server": "", "ip": "0.0.0.0",
       "run-as-service": False, "player-limit": 8, "tick-rate": 60, "password": ""}
if os.path.exists(path):
    with open(path) as f:
        cfg.update(json.load(f))
cfg["port"] = int(sys.argv[1])
cfg["log-location"] = "./data/server.log"
tmp = path + ".tmp"
with open(tmp, "w") as f:
    json.dump(cfg, f, indent=4)
os.replace(tmp, path)
EOF
exec "./$BIN"
