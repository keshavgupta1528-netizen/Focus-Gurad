package com.focusguard.app

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= 33 &&
            ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS)
            != PackageManager.PERMISSION_GRANTED
        ) {
            ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.POST_NOTIFICATIONS), 1)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "focusguard/engine")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startFocus" -> {
                        val end = call.argument<Number>("end")?.toLong() ?: 0L
                        val total = call.argument<Number>("total")?.toLong() ?: 0L
                        Prefs.get(this).edit()
                            .putLong(Prefs.KEY_END, end)
                            .putLong(Prefs.KEY_TOTAL, total)
                            .apply()
                        ContextCompat.startForegroundService(this, Intent(this, FocusService::class.java))
                        result.success(null)
                    }
                    "stopFocus" -> {
                        Prefs.clear(this)
                        stopService(Intent(this, FocusService::class.java))
                        result.success(null)
                    }
                    "getStatus" -> {
                        val p = Prefs.get(this)
                        val end = p.getLong(Prefs.KEY_END, 0L)
                        if (end > System.currentTimeMillis()) {
                            result.success(mapOf("end" to end, "total" to p.getLong(Prefs.KEY_TOTAL, 0L)))
                        } else {
                            result.success(emptyMap<String, Long>())
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
