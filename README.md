# Commonwealth Co-op (OG)

Online co-op for **Fallout 4 1.10.163** (GOG GOTY, or Steam "old gen"), with **F4SE 0.6.23**.

This is a **modified, unofficial** port of FathersFallout 24.2 (https://github.com/FLHNM/FathersFallout).
It is not FathersFallout and not an official release. FathersFallout - Copyright (C) 2026 FatherLamb.
Licensed GPL v3 with the additional terms in `NOTICE` (credits kept as required).

What changed from FathersFallout 24.2:
- Built against Dear-Modding-FO4/commonlibf4 (OG + NG + AE addresses) instead of libxse/commonlibf4 (1.11.x only).
- Exports `F4SEPlugin_Query`, so F4SE 0.6.23 loads it; trampoline allocated by the plugin on F4SE 0.6.x.
- Fast-travel hook finds its 4 call sites in the running exe instead of using 1.11.x-only addresses.
- GameNetworkingSockets is loaded from `Plugins\CommonwealthCoop\` (the DLL the official server ships).
- Renamed: plugin `CommonwealthCoop.dll`, settings `CommonwealthCoop.ini`, log `CommonwealthCoop.log`.

Verified 2026-10-28 on GOG 1.10.163 under Proton-GE: plugin loads, F1 menu opens, a host and a
second instance connected through the server, quests caught up, each game shows the other player's body.

## Install (each player)

You need from their authors (not included):
1. **F4SE 0.6.23** - https://f4se.silverlock.org (file `f4se_0_06_23.7z`, "for runtime 1.10.163").
   Copy `f4se_1_10_163.dll`, `f4se_loader.exe`, `f4se_steam_loader.dll` into the game folder (next to `Fallout4.exe`).
2. **Address Library for F4SE Plugins** - nexusmods.com/fallout4/mods/47327. From the archive copy only
   `F4SE/Plugins/version-1-10-163-0.bin` into `Data\F4SE\Plugins\`.
3. **F4SE Menu Framework** (3.x) - nexusmods.com/fallout4/mods/105090 (main file, not the optional ones).
   Copy its `F4SE` and `Interface` folders into `Data\`.

Then from this package copy `Data\` into the game folder. You end up with:

```
Fallout 4 GOTY\f4se_loader.exe, f4se_1_10_163.dll, f4se_steam_loader.dll
Fallout 4 GOTY\Data\F4SE\Plugins\CommonwealthCoop.dll
Fallout 4 GOTY\Data\F4SE\Plugins\CommonwealthCoop\GameNetworkingSockets.dll (+ abseil_dll, libcrypto-3-x64, libprotobuf)
Fallout 4 GOTY\Data\F4SE\Plugins\version-1-10-163-0.bin
Fallout 4 GOTY\Data\F4SE\Plugins\F4SEMenuFramework.dll (+ its folder and ini)
```

Start the game with **`f4se_loader.exe`** (Heroic: Game settings -> "Alternative EXE" = `f4se_loader.exe`).
Do not use the FathersFallout launcher: it only accepts 1.11.240.

Linux/Proton: the networking DLLs need `msvcp140.dll`/`vcruntime140.dll` in the prefix (Heroic's GOG
redist installs them; otherwise `winetricks vcrun2022`).

If a virtual gamepad is running (e.g. roblox-caffeine), Fallout 4 picks it up and the camera may turn by
itself: stop it, or set Settings -> Controls -> Controller off.

## Server on a VPS (Server Manager)

`manager/game.json` lets Server Manager import this repo (Games -> Import a game -> GitHub ->
`AriCuteGirl/commonwealth-coop-og`) and run the co-op server on a Linux arm64 VPS (e.g. Oracle free tier)
as the systemd service `fallout4-coop`, UDP 7779. The server is the FathersFallout server built for Linux
(`server/bin/linux-arm64/f4coop-server`, source and the one fix in `server/source/`).
Then everyone, host included, connects to the VPS: the host types its address in **Server** under
Host (others join me), friends type it under Join a friend.

## Play

Co-op needs a save made **after leaving Vault 111**.

**Host**
1. Start the server: `server\FathersFalloutServer.exe` (unchanged official server, UDP 7779).
   Linux: run it with Proton/Wine in any prefix that has the VC++ runtime.
2. Load your save, press **F1** -> Commonwealth Co-op -> Menu -> **Host (others join me)** -> **Host a game**.
3. Friends reach you through the Oracle relay: give them `130.162.243.144`, port `7779`
   (keep `ff_agent.py` running on the host PC), or forward UDP 7779 and give your own public IP.

**Friend**
1. Load your own save (a copy: joining catches your quests up to the host's).
2. F1 -> Commonwealth Co-op -> Menu -> **Join a friend**, your name, Host's IP, port 7779 -> **Join**.
   (`127.0.0.1` is rejected in Join mode by design; on the host's own PC use its LAN IP.)

Both players should run this same OG build. Mixing with the official FathersFallout on 1.11.x was not tested.

## Uninstall

Delete `Data\F4SE\Plugins\CommonwealthCoop.dll`, `CommonwealthCoop.ini` and the `CommonwealthCoop\` folder.

## Build from source (Linux)

Needs clang-cl, lld-link, llvm-dlltool, cmake, ninja and an x86_64 xwin SDK at `~/.xwin64`
(`xwin --accept-license --arch x86_64 splat --output ~/.xwin64`).

```
git clone --recurse-submodules https://github.com/Dear-Modding-FO4/commonlibf4 extern/commonlibf4   # ee0e4ce
git -C extern/commonlibf4 apply ../../patches/commonlibf4-og-trampoline.patch
git clone -b v1.16.0 https://github.com/gabime/spdlog extern/spdlog
git clone -b v1.4.1 https://github.com/ValveSoftware/GameNetworkingSockets extern/gns
cmake -S . -B build -G Ninja -DCMAKE_TOOLCHAIN_FILE=cmake/clang-cl-xwin.cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo
ninja -C build CommonwealthCoop
```
