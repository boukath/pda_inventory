package com.example.pda_inventory // This matches your exact package name!

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

class MainActivity: FlutterActivity() {
    // 1. The name of the tunnel we use to send data to Flutter
    private val EVENT_CHANNEL = "com.pda_inventory/rfid"

    // 2. The custom Intent Action we will tell the Bluebird PDA to broadcast
    private val RFID_INTENT_ACTION = "com.pda_inventory.RFID_SCAN"

    // 3. The key that holds the actual RFID tag string
    private val RFID_DATA_EXTRA = "data"

    private var eventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 4. Setup the EventChannel to stream data to Flutter
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    registerRfidReceiver() // Start listening to the hardware when Flutter asks
                }

                override fun onCancel(arguments: Any?) {
                    unregisterReceiver(rfidReceiver) // Stop listening when Flutter closes the screen
                    eventSink = null
                }
            }
        )
    }

    // 5. The BroadcastReceiver that catches the hardware signals from the Bluebird gun
    private val rfidReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == RFID_INTENT_ACTION) {

                // Extract the tag data from the Bluebird OS
                val tagData = intent.getStringExtra(RFID_DATA_EXTRA)
                    ?: intent.getStringExtra("EXTRA_BARCODE_DECODING_DATA")
                    ?: intent.getStringExtra("data_string")

                if (tagData != null && tagData.isNotEmpty()) {
                    // 6. Send the RFID tag directly to Flutter instantly!
                    eventSink?.success(tagData)
                }
            }
        }
    }

    // 6. Safely register the receiver based on the Android version
    private fun registerRfidReceiver() {
        val filter = IntentFilter(RFID_INTENT_ACTION)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(rfidReceiver, filter, Context.RECEIVER_EXPORTED)
        } else {
            registerReceiver(rfidReceiver, filter)
        }
    }
}