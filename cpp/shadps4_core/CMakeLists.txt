# Placeholder target for the shadPS4 core build (linker, PS4 syscalls/libraries),
# decoupled from shadPS4's assumption that game code executes natively on an
# x86-64 host CPU.
#
# STATUS: stub. Real work: pull in external/shadps4/src/core (and the pieces of
# src/video_core it needs) without its native-execution path, and route
# instruction execution through fexcore_android instead. Not started.

add_library(shadps4_core STATIC
    stub.cpp
)

target_include_directories(shadps4_core PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)

target_link_libraries(shadps4_core PUBLIC fexcore_android)
