#!/usr/bin/env python3
"""Tiny HTTP status page for the co-op server (Server Manager's health check from the internet).

The game server only speaks UDP (GameNetworkingSockets), so it can't answer an HTTP check itself.
This serves GET /health on TCP (F4COOP_STATUS_PORT): 200 + {"running", "players"} while the server
logs its 30-second status line, 503 otherwise. Reads data/server.log through manage.py.
"""
import http.server
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import manage  # noqa: E402

ROOT = os.path.dirname(os.path.abspath(__file__))


class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path.split("?")[0] not in ("/", "/health"):
            self.send_error(404)
            return
        st = manage.state(ROOT)
        body = json.dumps({"running": st["running"], "players": len(st["players"])}).encode()
        self.send_response(200 if st["running"] else 503)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *args):
        pass


if __name__ == "__main__":
    port = int(os.environ.get("F4COOP_STATUS_PORT", "7779"))
    http.server.ThreadingHTTPServer(("0.0.0.0", port), Handler).serve_forever()
