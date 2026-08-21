// The buildable Android project is BachataS4, vendored in place under
// external/shadps4/android/BachataS4 — its CMake and shell scripts compute paths
// relative to that exact nesting depth (see BachataS4/core/runtime/src/main/cpp/
// CMakeLists.txt's BACHATA_ROOT), so it is not flattened to repo root here.
includeBuild("external/shadps4/android/BachataS4")

rootProject.name = "ShadPs4DroidEx"
