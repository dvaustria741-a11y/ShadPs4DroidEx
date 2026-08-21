#include <jni.h>
#include <android/log.h>
#include "shadps4_core.h"
#include "fexcore_android.h"

#define LOG_TAG "ShadPs4DroidEx"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)

extern "C" JNIEXPORT jstring JNICALL
Java_com_dvaustria741a11y_shadps4droidex_NativeBridge_getStatus(JNIEnv* env, jobject /* this */) {
    LOGI("shadps4_core: %s", shadps4_core::status());
    LOGI("fexcore_android: %s", fexcore_android::status());
    std::string msg = std::string("shadps4_core -> ") + shadps4_core::status() +
                       " | fexcore_android -> " + fexcore_android::status();
    return env->NewStringUTF(msg.c_str());
}
