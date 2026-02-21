package io.flutter.plugins

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

// awesome_notifications handles its own boot recovery automatically.
// This receiver is kept as a placeholder — no action needed.
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        // awesome_notifications reschedules notifications after reboot internally.
    }
}
