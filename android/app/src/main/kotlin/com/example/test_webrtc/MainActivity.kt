
// kotlin
package com.example.test_webrtc
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import com.hiennv.flutter_callkit_incoming.CallkitConstants


class MainActivity: FlutterActivity() {
    private val CHANNEL_CALLKIT = "callkit_channel"
    private var callkitChannel: MethodChannel? = null


    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        callkitChannel = MethodChannel(flutterEngine?.dartExecutor?.binaryMessenger!!, CHANNEL_CALLKIT)
        val appOpenedIntent = intent
        if (appOpenedIntent != null &&
            appOpenedIntent.action == "com.hiennv.flutter_callkit_incoming.ACTION_CALL_ACCEPT") {
            val extras = appOpenedIntent.extras
            if (extras != null) {
                Log.d("CALKIT_INTENT", fromBundle(extras).toString())
                callkitChannel!!.invokeMethod("CALL_ACCEPTED_INTENT", fromBundle(extras))

            }
        }
    }

    private fun fromBundle(bundle: Bundle): HashMap<String, Any?> {
        var data: HashMap<String, Any?> = HashMap()
        val extraCallkitData = bundle.getBundle("EXTRA_CALLKIT_CALL_DATA") ?: return data
        data = extraCallkitData.getSerializable(CallkitConstants.EXTRA_CALLKIT_EXTRA) as HashMap<String, Any?>
        return data
    }


}


