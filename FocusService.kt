package com.focusguard.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat

/** Keeps the focus timer alive in the background. Blocking engine hooks in here in step 3. */
class FocusService : Service() {

    private val handler = Handler(Looper.getMainLooper())
    private val finishRunnable = Runnable { complete() }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val end = Prefs.get(this).getLong(Prefs.KEY_END, 0L)
        createChannels()
        ServiceCompat.startForeground(
            this, ACTIVE_ID, buildActiveNotification(end),
            ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
        )
        val remaining = end - System.currentTimeMillis()
        if (remaining <= 0) {
            Prefs.clear(this)
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
            return START_NOT_STICKY
        }
        handler.removeCallbacks(finishRunnable)
        handler.postDelayed(finishRunnable, remaining)
        return START_STICKY
    }

    override fun onDestroy() {
        handler.removeCallbacks(finishRunnable)
        super.onDestroy()
    }

    private fun complete() {
        Prefs.clear(this)
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.notify(
            DONE_ID,
            NotificationCompat.Builder(this, CH_DONE)
                .setSmallIcon(android.R.drawable.ic_lock_idle_lock)
                .setContentTitle("Focus session complete")
                .setContentText("Nice work. Take a break, you earned it.")
                .setContentIntent(openAppIntent())
                .setAutoCancel(true)
                .build()
        )
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private fun openAppIntent(): PendingIntent = PendingIntent.getActivity(
        this, 0, Intent(this, MainActivity::class.java),
        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
    )

    private fun buildActiveNotification(end: Long): Notification =
        NotificationCompat.Builder(this, CH_ACTIVE)
            .setSmallIcon(android.R.drawable.ic_lock_idle_lock)
            .setContentTitle("Focus session active")
            .setContentText("Stay on task. Time left:")
            .setUsesChronometer(true)
            .setChronometerCountDown(true)
            .setWhen(if (end > 0) end else System.currentTimeMillis())
            .setShowWhen(true)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setCategory(NotificationCompat.CATEGORY_PROGRESS)
            .setContentIntent(openAppIntent())
            .build()

    private fun createChannels() {
        if (Build.VERSION.SDK_INT < 26) return
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.createNotificationChannel(
            NotificationChannel(CH_ACTIVE, "Focus session", NotificationManager.IMPORTANCE_LOW)
        )
        nm.createNotificationChannel(
            NotificationChannel(CH_DONE, "Session complete", NotificationManager.IMPORTANCE_HIGH)
        )
    }

    companion object {
        private const val CH_ACTIVE = "focus_active"
        private const val CH_DONE = "focus_done"
        private const val ACTIVE_ID = 1001
        private const val DONE_ID = 1002
    }
}
