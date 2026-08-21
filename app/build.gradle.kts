plugins {
    id("com.android.application")
}

android {
    namespace = "com.dvaustria741a11y.shadps4droidex"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.dvaustria741a11y.shadps4droidex"
        minSdk = 28   // Vulkan 1.1 baseline; shadPS4 needs a real Vulkan driver
        targetSdk = 35
        versionCode = 1
        versionName = "0.0.1-scaffold"

        ndk {
            // arm64 only, matching PORTING_PLAN.md
            abiFilters += "arm64-v8a"
        }

        externalNativeBuild {
            cmake {
                cppFlags += "-std=c++23"
            }
        }
    }

    externalNativeBuild {
        cmake {
            path = file("../CMakeLists.txt")
            version = "3.24.0+"
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = false
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}
