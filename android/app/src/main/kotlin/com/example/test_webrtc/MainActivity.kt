
// kotlin
package com.example.test_webrtc

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        intent?.let { handleNewIntent(it) }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // Update the activity intent so Flutter plugins reading the intent get the latest data
        setIntent(intent)
        handleNewIntent(intent)
    }

    private fun handleNewIntent(intent: Intent) {
        // Try to notify the Flutter CallKit plugin if present (reflection to avoid build-time dependency).
        try {
            val cls = Class.forName("com.dooboolab.fluttercallkit_incoming.FlutterCallkitIncoming")
            val method = cls.getMethod("onNewIntent", Intent::class.java)
            method.invoke(null, intent)
        } catch (e: Exception) {
            // Plugin or method not present — ignore
        }
    }
}
