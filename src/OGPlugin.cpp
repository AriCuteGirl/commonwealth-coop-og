// Commonwealth Co-op - FathersFallout 24.2 client ported to Fallout 4 1.10.163 (OG).
// Modified version of FathersFallout - Copyright (C) 2026 FatherLamb. GNU GPL v3 with the
// additional terms in NOTICE. Not an official FathersFallout release.
//
// Plugin identity for both F4SE lines: F4SEPlugin_Version (F4SE 0.7.x, NG/AE) and F4SEPlugin_Query
// (F4SE 0.6.x, which never reads the version data).

#include "OGPlugin.h"

#include <Windows.h>
#undef ERROR

#include <filesystem>

F4SE_PLUGIN_VERSION = []() noexcept {
    F4SE::PluginVersionData v{};
    v.PluginVersion({ 0, 24, 2, 0 });
    v.PluginName(F4MP::OG::kPluginName);
    v.AuthorName("FatherLamb (original), OG port");
    v.UsesAddressLibrary(true);
    v.UsesAddressLibraryNG(true);
    v.IsLayoutDependent(true);
    v.IsLayoutDependentNG(true);
    v.CompatibleVersions({ F4SE::RUNTIME_1_10_163, F4SE::RUNTIME_LATEST });
    return v;
}();

F4SE_PLUGIN_QUERY(const F4SE::QueryInterface* a_f4se, F4SE::PluginInfo* a_info)
{
    a_info->infoVersion = F4SE::PluginInfo::kVersion;
    a_info->name = F4MP::OG::kPluginName;
    a_info->version = 0x00180200;   // 0.24.2
    if (a_f4se->IsEditor()) return false;
    // Addresses come from the Address Library per runtime; CommonLibF4 refuses unknown versions itself.
    return a_f4se->RuntimeVersion() == F4SE::RUNTIME_1_10_163;
}

namespace F4MP::OG
{
    std::filesystem::path PluginDir()
    {
        wchar_t buf[MAX_PATH]{};
        HMODULE self = nullptr;
        GetModuleHandleExW(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS | GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
            reinterpret_cast<LPCWSTR>(&PluginDir), &self);
        GetModuleFileNameW(self, buf, MAX_PATH);
        return std::filesystem::path(buf).parent_path();
    }

    bool PreloadNetworking()
    {
        // GameNetworkingSockets.dll and its dependencies ship in Plugins\CommonwealthCoop\. The plugin
        // delay-loads it; loading it here by full path makes Windows resolve its own imports
        // (abseil, protobuf, OpenSSL) from that folder too.
        const auto dll = PluginDir() / L"CommonwealthCoop" / L"GameNetworkingSockets.dll";
        if (LoadLibraryExW(dll.c_str(), nullptr, LOAD_WITH_ALTERED_SEARCH_PATH)) return true;
        REX::ERROR("[{}] could not load {} (error {}): networking is off", kPluginName, dll.string(), GetLastError());
        return false;
    }
}
