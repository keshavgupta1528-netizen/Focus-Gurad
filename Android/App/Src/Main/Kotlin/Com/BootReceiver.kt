package com.focusguard.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.content.ContextCompat

/** Re-arms an unfinished focus session after the phone restarts. */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) return
        val end = Prefs.get(context).getLong(Prefs.KEY_END, 0L)
        if (end > System.currentTimeMillis()) {
            try {
                ContextCompat.startForegroundService(context, Intent(context, FocusService::class.java))
            } catch (_: Exception) {
                // Some OEMs block background starts; the session resumes when the app opens.
            }
        }
    }
}
