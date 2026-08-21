package com.dvaustria741a11y.shadps4droidex;

import android.app.Activity;
import android.os.Bundle;
import android.widget.TextView;

// Placeholder Activity. No emulation UI, no game loading, no rendering surface yet.
// Purpose right now: prove the JNI bridge to shadps4_core / fexcore_android links
// and loads on-device. See PORTING_PLAN.md for what's actually implemented.
public class MainActivity extends Activity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        TextView tv = new TextView(this);
        tv.setText("ShadPs4DroidEx (scaffold)\n\n" + NativeBridge.getStatus());
        setContentView(tv);
    }
}
