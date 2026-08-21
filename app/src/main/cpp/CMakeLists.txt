add_library(shadps4droidex SHARED
    jni_bridge.cpp
)

target_link_libraries(shadps4droidex
    shadps4_core
    fexcore_android
    log
)
