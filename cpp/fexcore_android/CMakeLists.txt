# Placeholder target for the FEXCore-only Android build.
#
# STATUS: stub. FEXCore's real sources under external/FEX/FEXCore are NOT yet wired in.
# FEX's build assumes a full Linux target (binfmt_misc install rules, x86 rootfs
# discovery, glibc allocator hooks) that doesn't apply here. Carving out just the
# JIT block-compiler/executor pieces of FEXCore into a standalone arm64-v8a static
# library is real, unstarted work — this stub exists so the rest of the CMake graph
# and the CI pipeline are exercised end-to-end from day one.

add_library(fexcore_android STATIC
    stub.cpp
)

target_include_directories(fexcore_android PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)
