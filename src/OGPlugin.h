// Commonwealth Co-op - FathersFallout 24.2 client ported to Fallout 4 1.10.163 (OG).
// Modified version of FathersFallout - Copyright (C) 2026 FatherLamb. GNU GPL v3 with the
// additional terms in NOTICE. Not an official FathersFallout release.

#pragma once

#include <filesystem>

namespace F4MP::OG
{
    inline constexpr const char* kPluginName = "CommonwealthCoop";

    // Folder of this DLL (Data\F4SE\Plugins).
    std::filesystem::path PluginDir();

    // Loads Plugins\CommonwealthCoop\GameNetworkingSockets.dll before its first (delay-loaded) use.
    bool PreloadNetworking();
}
