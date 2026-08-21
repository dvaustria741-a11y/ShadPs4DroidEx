package com.dvaustria741a11y.shadps4droidex;

public class NativeBridge {
    static {
        System.loadLibrary("shadps4droidex");
    }

    public static native String getStatus();
}
