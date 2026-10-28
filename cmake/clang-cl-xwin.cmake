# Cross-compile for Windows x64 from Linux with clang-cl + lld-link and an xwin SDK (~/.xwin).
set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSTEM_PROCESSOR AMD64)
set(CMAKE_C_COMPILER clang-cl)
set(CMAKE_CXX_COMPILER clang-cl)
set(CMAKE_LINKER lld-link)
set(CMAKE_AR llvm-lib)
set(CMAKE_RC_COMPILER llvm-rc)
set(CMAKE_MT llvm-mt)

if(NOT XWIN_DIR)
  set(XWIN_DIR "$ENV{HOME}/.xwin64")
endif()

set(_xwin_inc
  "/imsvc${XWIN_DIR}/crt/include"
  "/imsvc${XWIN_DIR}/sdk/include/ucrt"
  "/imsvc${XWIN_DIR}/sdk/include/um"
  "/imsvc${XWIN_DIR}/sdk/include/shared")
string(JOIN " " _xwin_inc_str ${_xwin_inc})
set(CMAKE_C_FLAGS_INIT "--target=x86_64-pc-windows-msvc ${_xwin_inc_str}")
set(CMAKE_CXX_FLAGS_INIT "--target=x86_64-pc-windows-msvc ${_xwin_inc_str}")

set(_xwin_lib
  "/libpath:${XWIN_DIR}/crt/lib/x86_64"
  "/libpath:${XWIN_DIR}/sdk/lib/um/x86_64"
  "/libpath:${XWIN_DIR}/sdk/lib/ucrt/x86_64")
string(JOIN " " _xwin_lib_str ${_xwin_lib})
set(CMAKE_EXE_LINKER_FLAGS_INIT "${_xwin_lib_str}")
set(CMAKE_SHARED_LINKER_FLAGS_INIT "${_xwin_lib_str}")
set(CMAKE_MODULE_LINKER_FLAGS_INIT "${_xwin_lib_str}")

set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)
