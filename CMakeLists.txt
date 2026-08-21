cmake_minimum_required(VERSION 3.24)
project(ShadPs4DroidEx CXX C ASM)

# Android-only. This project intentionally does not support desktop targets.
if(NOT ANDROID)
    message(FATAL_ERROR
        "ShadPs4DroidEx only builds for Android (ANDROID_ABI=arm64-v8a). "
        "For desktop, use upstream shadPS4 directly: https://github.com/shadps4-emu/shadPS4")
endif()

if(NOT ANDROID_ABI STREQUAL "arm64-v8a")
    message(FATAL_ERROR "Only arm64-v8a is targeted right now (ANDROID_ABI was: ${ANDROID_ABI})")
endif()

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED True)

# --- FEXCore (JIT translation core only, not FEX's Linux userspace frontend) ---
# NOTE: FEX's own CMakeLists.txt is written for full Linux builds (binfmt_misc install
# rules, glibc-oriented options, x86 rootfs tooling). We do not include it directly yet.
# This subdirectory is a placeholder target until the FEXCore-only build surface is
# carved out — see PORTING_PLAN.md.
add_subdirectory(cpp/fexcore_android)

# --- shadPS4 core (PS4 syscalls/linker/libraries, minus its native x86-64 execution
# assumption and its desktop windowing/renderer glue) ---
add_subdirectory(cpp/shadps4_core)

# --- JNI bridge exposed to the Android app module ---
add_subdirectory(app/src/main/cpp)
