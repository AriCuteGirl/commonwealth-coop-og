# Co-op server source

The FathersFallout server (https://github.com/FLHNM/FathersFallout, `server/`, commit d282314),
GPL v3 with the terms in ../../NOTICE. FathersFallout - Copyright (C) 2026 FatherLamb.
Based on F4MP - Copyright (C) 2020 Alin Octavian, Benjamin Kyd.

One change, marked in src/main.cpp: SIGTERM/SIGINT now stop the server (upstream the handler set a
flag the main loop never read, so `systemctl stop` hung until the kill timeout).

`build-linux.sh` builds `f4coop-server` the way ../bin/linux-arm64 was built (Ubuntu 24.04 arm64).
