cmake_minimum_required(VERSION 3.25)
project(CommonwealthCoop VERSION 0.24.2 LANGUAGES C CXX)

# Commonwealth Co-op: FathersFallout 24.2 client ported to Fallout 4 1.10.163 (OG) / F4SE 0.6.23.
# Built with clang-cl + xwin (cmake/clang-cl-xwin.cmake).

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded")   # static CRT: nothing extra needed in the prefix

set(EXT ${CMAKE_CURRENT_SOURCE_DIR}/extern)
set(CLIB ${EXT}/commonlibf4)

add_compile_definitions(
  NOMINMAX WIN32_LEAN_AND_MEAN UNICODE _UNICODE
  _CRT_SECURE_NO_WARNINGS
  COMMONLIB_RUNTIMECOUNT=3
  SPDLOG_COMPILED_LIB SPDLOG_USE_STD_FORMAT SPDLOG_WCHAR_TO_UTF8_SUPPORT)
add_compile_options(/EHsc /utf-8 /permissive- /Zc:preprocessor
  -Wno-everything)   # third-party headers are noisy under clang

# ---- spdlog (compiled: header-only would leak <windows.h> macros into REX::W32) ----
file(GLOB SPDLOG_SRC ${EXT}/spdlog/src/*.cpp)
add_library(spdlog STATIC ${SPDLOG_SRC})
target_include_directories(spdlog PUBLIC ${EXT}/spdlog/include)

# ---- commonlib-shared + commonlibf4 (Dear-Modding-FO4 fork: OG/NG/AE) ----
file(GLOB_RECURSE SHARED_SRC CONFIGURE_DEPENDS ${CLIB}/lib/commonlib-shared/src/*.cpp)
add_library(commonlib-shared STATIC ${SHARED_SRC})
target_include_directories(commonlib-shared PUBLIC
  ${CLIB}/lib/commonlib-shared/include)
target_precompile_headers(commonlib-shared PRIVATE ${CLIB}/lib/commonlib-shared/src/REX/PCH.h)
target_link_libraries(commonlib-shared PUBLIC spdlog
  advapi32 bcrypt d3d11 d3dcompiler dbghelp dxgi ole32 shell32 user32 version ws2_32)

file(GLOB_RECURSE F4_SRC CONFIGURE_DEPENDS ${CLIB}/src/*.cpp)
add_library(commonlibf4 STATIC ${F4_SRC})
target_include_directories(commonlibf4 PUBLIC ${CLIB}/include ${CLIB}/lib/dearmoddingui-api/include)
target_precompile_headers(commonlibf4 PRIVATE ${CLIB}/include/F4SE/Impl/PCH.h)
target_link_libraries(commonlibf4 PUBLIC commonlib-shared)

# ---- GameNetworkingSockets: headers from v1.4.1, linked to the DLL the server ships ----
add_custom_command(
  OUTPUT ${CMAKE_BINARY_DIR}/GameNetworkingSockets.lib
  COMMAND llvm-dlltool -m i386:x86-64 -d ${CMAKE_CURRENT_SOURCE_DIR}/cmake/GameNetworkingSockets.def
          -l ${CMAKE_BINARY_DIR}/GameNetworkingSockets.lib
  DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/cmake/GameNetworkingSockets.def)
add_custom_target(gns_implib DEPENDS ${CMAKE_BINARY_DIR}/GameNetworkingSockets.lib)
add_library(gns INTERFACE)
add_dependencies(gns gns_implib)
target_include_directories(gns INTERFACE ${EXT}/gns/include)
target_link_libraries(gns INTERFACE ${CMAKE_BINARY_DIR}/GameNetworkingSockets.lib delayimp)
target_link_options(gns INTERFACE /DELAYLOAD:GameNetworkingSockets.dll)

# ---- the plugin ----
file(GLOB_RECURSE PLUGIN_SRC CONFIGURE_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp)
add_library(CommonwealthCoop SHARED ${PLUGIN_SRC})
target_include_directories(CommonwealthCoop PRIVATE src)
target_precompile_headers(CommonwealthCoop PRIVATE src/pch.h)
target_link_libraries(CommonwealthCoop PRIVATE commonlibf4 gns iphlpapi winmm)
target_link_options(CommonwealthCoop PRIVATE /DEBUG:FULL /OPT:REF /OPT:ICF)
