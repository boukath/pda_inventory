package com.example.pda_inventory

import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.Message
import android.util.Log
import android.view.KeyEvent
import android.content.Intent // Required for sending system intents

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

import co.kr.bluebird.sled.Reader
import co.kr.bluebird.sled.SDConsts

class MainActivity: FlutterActivity() {
    private val EVENT_CHANNEL_NAME = "com.pda_inventory/rfid_events"
    private val METHOD_CHANNEL_NAME = "com.pda_inventory/rfid_methods"

    private var eventSink: EventChannel.EventSink? = null
    private var mReader: Reader? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL_NAME).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }
                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            }
        )

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL_NAME).setMethodCallHandler { call, result ->
            if (call.method == "startScan") {
                startInventory()
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        try {
            mReader = Reader.getReader(this, sledHandler)
            Log.d("RFID_DEBUG", "✅ Bluebird SDK Initialized")
        } catch (e: Exception) {
            Log.e("RFID_DEBUG", "❌ SDK Init Failure", e)
        }
    }

    // --- NEW: Force the System Barcode Scanner to STOP ---
    private fun stopSystemBarcode() {
        try {
            // Bluebird HF550 standard stop intent
            val stopIntent = Intent("kr.co.bluebird.android.bbapi.action.BARCODE_SET_ENABLE")
            stopIntent.putExtra("EXTRA_ENABLE", false)
            sendBroadcast(stopIntent)

            // Second intent for older Bluebird models
            val stopIntent2 = Intent("com.bluebird.barcode.action.STOP")
            sendBroadcast(stopIntent2)

            Log.d("RFID_DEBUG", "Sent System Barcode STOP command")
        } catch (e: Exception) {
            Log.e("RFID_DEBUG", "Failed to send stop intent", e)
        }
    }

    override fun onResume() {
        super.onResume()

        // 1. Kill the barcode scanner first
        stopSystemBarcode()

        // 2. Clear any stale connection
        mReader?.SD_Close()

        // 3. Wait 1 second for the port to actually unlock
        Handler(Looper.getMainLooper()).postDelayed({
            val result = mReader?.SD_Open()
            if (result == true) {
                Log.d("RFID_DEBUG", "✅ Sled Opened Successfully")
                mReader?.SD_SetTriggerMode(SDConsts.SDTriggerMode.RFID)
                mReader?.SD_Wakeup()
            } else {
                Log.e("RFID_DEBUG", "❌ Sled Open Failed (-32). Port is still locked by the OS.")
            }
        }, 1000)
    }

    override fun onPause() {
        mReader?.SD_Close()

        // Re-enable barcode scanner when exiting so other apps aren't broken
        val startIntent = Intent("kr.co.bluebird.android.bbapi.action.BARCODE_SET_ENABLE")
        startIntent.putExtra("EXTRA_ENABLE", true)
        sendBroadcast(startIntent)

        super.onPause()
    }

    private fun startInventory() {
        val state = mReader?.SD_GetConnectState()
        if (state != SDConsts.SDConnectState.CONNECTED) {
            Log.e("RFID_DEBUG", "Sled is $state. Re-opening port...")
            mReader?.SD_Open()
            mReader?.SD_Wakeup()
            return
        }

        try {
            val result = mReader?.RF_PerformInventory(true, true, true)
            if (result != 0 && result != null) {
                Log.e("RFID_DEBUG", "Inventory Command Failed: $result")
            } else {
                Log.d("RFID_DEBUG", "Antenna is ACTIVE")
            }
        } catch (e: Exception) {
            Log.e("RFID_DEBUG", "Inventory Error", e)
        }
    }

    private fun stopInventory() {
        mReader?.RF_StopInventory()
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (event?.repeatCount == 0 && (keyCode == 280 || keyCode == 293)) {
            startInventory()
            return true
        }
        return super.onKeyDown(keyCode, event)
    }

    override fun onKeyUp(keyCode: Int, event: KeyEvent?): Boolean {
        if (keyCode == 280 || keyCode == 293) {
            stopInventory()
            return true
        }
        return super.onKeyUp(keyCode, event)
    }

    private val sledHandler = object : Handler(Looper.getMainLooper()) {
        override fun handleMessage(msg: Message) {
            when (msg.what) {
                SDConsts.Msg.RFMsg -> {
                    val rawData = msg.obj as? String
                    if (!rawData.isNullOrEmpty()) {
                        val parts = rawData.split(";")
                        val epc = if (parts.size >= 2) parts[1] else parts[0]
                        eventSink?.success(epc.trim())
                    }
                }
            }
        }
    }
}