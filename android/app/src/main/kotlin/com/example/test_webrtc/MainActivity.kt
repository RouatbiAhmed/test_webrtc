
// kotlin
package com.example.test_webrtc

import android.content.Intent
import android.os.Bundle

import android.os.PowerManager
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.hiennv.flutter_callkit_incoming.CallkitConstants



class MainActivity: FlutterActivity() {

    private val CHANNEL_PROXIMITY= "com.yourapp/proximity"
    private val CHANNEL_CALLKIT = "callkit_channel"
    private var powerManager: PowerManager? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var callkitChannel: MethodChannel? = null
// var callIntent Extras: Bundle? null


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

    /*
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        powerManager = getSystemService(POWER_SERVICE) as PowerManager

        // Proximity Channel
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL_PROXIMITY
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "turnOffScreen" -> {
                    turnOffScreen()
                    result.success(null)
                }

                "turnOnScreen" -> {
                    turnOnScreen()
                    result.success(null)
                }

                "startService" -> {
                    val intent = Intent(this, CallForegroundService::class.java)
                    startService(intent)
                    result.success("started")
                }

                "stopService" -> {
                    val intent = Intent(this, CallForegroundService::class.java)
                    stopService(intent)
                    result.success("stopped")
                }

                else -> result.notImplemented()
            }
        }
    }*/


    private fun fromBundle(bundle: Bundle): HashMap<String, Any?> {
        var data: HashMap<String, Any?> = HashMap()
        val extraCallkitData = bundle.getBundle("EXTRA_CALLKIT_CALL_DATA") ?: return data
        data = extraCallkitData.getSerializable(CallkitConstants.EXTRA_CALLKIT_EXTRA) as HashMap<String, Any?>
        return data
    }

    private fun turnOffScreen() {
        if (wakeLock == null || !wakeLock!!.isHeld) {
            wakeLock = powerManager?.newWakeLock(
                PowerManager.PROXIMITY_SCREEN_OFF_WAKE_LOCK,
                "MyApp::MyWakeLockTag"
            )
            wakeLock?.acquire()
        }
    }

    private fun turnOnScreen() {
        wakeLock?.let {
            if (it.isHeld) {
                it.release()
            }
        }
    }



}


