#!/bin/bash
# Builds the server for Linux (Ubuntu 24.04, x86_64 or arm64) into ./f4coop-server.
# GameNetworkingSockets, protobuf and OpenSSL are linked statically; libcurl stays shared.
set -euo pipefail
cd "$(dirname "$0")"
sudo apt-get install -y build-essential cmake ninja-build git libprotobuf-dev protobuf-compiler libssl-dev \
  libspdlog-dev libfmt-dev libcurl4-openssl-dev
[ -d gns ] || git clone --depth 1 -b v1.4.1 https://github.com/ValveSoftware/GameNetworkingSockets gns
cmake -S gns -B gns/build -G Ninja -DCMAKE_BUILD_TYPE=Release -DBUILD_STATIC_LIB=ON -DBUILD_SHARED_LIB=OFF \
  -DBUILD_EXAMPLES=OFF -DBUILD_TESTS=OFF -DBUILD_TOOLS=OFF -DUSE_CRYPTO=OpenSSL -DCMAKE_INSTALL_PREFIX="$PWD/gns/prefix"
ninja -C gns/build install
L=/usr/lib/$(gcc -print-multiarch)
g++ -O2 -std=c++17 -o f4coop-server src/main.cpp src/Network/GameServer.cpp src/Heartbeat.cpp \
-Igns/prefix/include/GameNetworkingSockets \
  -DSTEAMNETWORKINGSOCKETS_STATIC_LINK -DPOSIX -DLINUX -DSPDLOG_HEADER_ONLY -DSPDLOG_FMT_EXTERNAL -DFMT_HEADER_ONLY \
  -D_RESOURCES='"./resources/"' -DGIT_VERSION='"d282314"' -DBUILD_TIME='"build"' \
  gns/prefix/lib/libGameNetworkingSockets_s.a "$L/libprotobuf.a" "$L/libssl.a" "$L/libcrypto.a" \
  -lcurl -lpthread -ldl -static-libstdc++ -static-libgcc
strip f4coop-server
