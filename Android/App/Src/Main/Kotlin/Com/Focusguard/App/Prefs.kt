package com.focusguard.app

import android.content.Context
import android.content.SharedPreferences

object Prefs {
    private const val FILE = "focusguard"
    const val KEY_END = "end"
    const val KEY_TOTAL = "total"

    fun get(c: Context): SharedPreferences = c.getSharedPreferences(FILE, Context.MODE_PRIVATE)

    fun clear(c: Context) {
        get(c).edit().remove(KEY_END).remove(KEY_TOTAL).apply()
    }
}
