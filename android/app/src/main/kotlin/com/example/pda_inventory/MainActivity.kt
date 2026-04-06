package com.example.pda_inventory

import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.Message
import android.util.Log

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
                    Log.d("RFID_DEBUG", "Dart started listening to EventChannel")
                    eventSink = events
                }
                override fun onCancel(arguments: Any?) {
                    Log.d("RFID_DEBUG", "Dart stopped listening to EventChannel")
                    eventSink = null
                }
            }
        )

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL_NAME).setMethodCallHandler { call, result ->
            when (call.method) {
                "startScan" -> {
                    startInventory()
                    result.success(null)
                }
                "stopScan" -> {
                    stopInventory()
                    result.success(null)
                }
                else -> result.notImplemented()
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

    override fun onResume() {
        super.onResume()
        // Close stale ports before opening
        mReader?.SD_Close()

        Handler(Looper.getMainLooper()).postDelayed({
            val result = mReader?.SD_Open()
            if (result == true) {
                Log.d("RFID_DEBUG", "✅ Sled Opened Successfully")
                // CRITICAL: Tells the sled to map its physical gun trigger to RFID scanning
                mReader?.SD_SetTriggerMode(SDConsts.SDTriggerMode.RFID)
                mReader?.SD_Wakeup()
            } else {
                Log.e("RFID_DEBUG", "❌ Sled Open Failed.")
            }
        }, 500)
    }

    override fun onPause() {
        mReader?.SD_Close()
        super.onPause()
    }

    // This handles the On-Screen "TEST SCAN" button
    private fun startInventory() {
        val state = mReader?.SD_GetConnectState()
        if (state != SDConsts.SDConnectState.CONNECTED) {
            Log.e("RFID_DEBUG", "Port closed! Re-opening...")
            mReader?.SD_Open()
            mReader?.SD_SetTriggerMode(SDConsts.SDTriggerMode.RFID)
            mReader?.SD_Wakeup()

            Handler(Looper.getMainLooper()).postDelayed({
                executeInventoryCommand()
            }, 500)
        } else {
            mReader?.SD_Wakeup()
            executeInventoryCommand()
        }
    }

    private fun executeInventoryCommand() {
        try {
            val result = mReader?.RF_PerformInventory(true, true, true)
            if (result == 0) {
                Log.d("RFID_DEBUG", "✅ Software Scan Started!")
            } else {
                Log.e("RFID_DEBUG", "❌ Software Scan failed: $result")
            }
        } catch (e: Exception) {
            Log.e("RFID_DEBUG", "Error", e)
        }
    }

    private fun stopInventory() {
        Log.d("RFID_DEBUG", "Stopping Software Scan...")
        mReader?.RF_StopInventory()
    }

    // Central Data and Status Handler
    private val sledHandler = object : Handler(Looper.getMainLooper()) {
        override fun handleMessage(msg: Message) {
            when (msg.what) {
                // 1. Tags coming in from the antenna
                SDConsts.Msg.RFMsg -> {
                    val rawData = msg.obj?.toString()
                    if (!rawData.isNullOrEmpty()) {
                        val parts = rawData.split(";")
                        val epc = if (parts.size >= 2) parts[1] else parts[0]
                        // Prefixing with "TAG:" so Flutter knows it's an EPC
                        eventSink?.success("TAG:${epc.trim()}")
                    }
                }
                // 2. Hardware Trigger status updates
                SDConsts.Msg.SDMsg -> {
                    if (msg.arg1 == SDConsts.SDCmdMsg.TRIGGER_PRESSED) {
                        Log.d("RFID_DEBUG", "🔫 Physical Trigger PULLED")
                        eventSink?.success("STATUS:START")
                    } else if (msg.arg1 == SDConsts.SDCmdMsg.TRIGGER_RELEASED) {
                        Log.d("RFID_DEBUG", "🔫 Physical Trigger RELEASED")
                        eventSink?.success("STATUS:STOP")
                    }
                }
            }
        }
    }
}