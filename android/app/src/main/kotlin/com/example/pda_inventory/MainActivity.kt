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
import com.bluebird.keymapper.KeyMapperManager

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
            when (call.method) {
                "connectHardware" -> {
                    connectToSled()
                    result.success(null)
                }
                "disconnectHardware" -> {
                    mReader?.SD_Disconnect()
                    result.success(null)
                }
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

    private fun connectToSled() {
        // 1. OPEN THE SERIAL/USB PORT FIRST (Fixes "Serial is not exist")
        val openStatus = mReader?.SD_Open()
        Log.d("RFID_DEBUG", "🔓 SD_Open Status: $openStatus")

        // 2. WAKE UP THE SLED MCU
        if (mReader?.SD_GetConnectState() != SDConsts.SDConnectState.CONNECTED) {
            Log.d("RFID_DEBUG", "⏳ Waking up SLED...")
            mReader?.SD_Wakeup()
        } else {
            Log.d("RFID_DEBUG", "✅ SLED already awake and connected.")
        }
    }

    private fun setBarcodeKeyMapOn(setOn: Boolean) {
        try {
            val keyMapperManager = getSystemService("keymapper") as? KeyMapperManager
            keyMapperManager?.setKeyMapping(503, setOn)
            if (setOn) {
                keyMapperManager?.removeKeyMapSetting(503)
            }
        } catch (e: Exception) {
            Log.e("RFID_DEBUG", "❌ KeyMapper Failed", e)
        }
    }

    override fun onResume() {
        super.onResume()
        setBarcodeKeyMapOn(false)
        // Try to connect every time we resume the app
        connectToSled()
    }

    override fun onPause() {
        setBarcodeKeyMapOn(true)
        mReader?.RF_StopInventory()
        super.onPause()
    }

    override fun onDestroy() {
        // Safely disconnect AND release the serial port
        mReader?.SD_Disconnect()
        mReader?.SD_Close()
        super.onDestroy()
    }

    private fun startInventory() {
        if (mReader?.SD_GetConnectState() == SDConsts.SDConnectState.CONNECTED) {
            val result = mReader?.RF_PerformInventory(true, false, false)
            Log.d("RFID_DEBUG", "✅ Software Scan Triggered (Result: $result)")
        } else {
            Log.e("RFID_DEBUG", "❌ Cannot scan. Sled disconnected.")
            connectToSled()
        }
    }

    private fun stopInventory() {
        mReader?.RF_StopInventory()
    }

    private val sledHandler = object : Handler(Looper.getMainLooper()) {
        override fun handleMessage(msg: Message) {
            when (msg.what) {
                SDConsts.Msg.RFMsg -> {
                    if (msg.arg1 == SDConsts.RFCmdMsg.INVENTORY || msg.arg1 == SDConsts.RFCmdMsg.READ) {
                        if (msg.arg2 == SDConsts.RFResult.SUCCESS) {
                            val rawData = msg.obj?.toString()
                            if (!rawData.isNullOrEmpty()) {
                                val parts = rawData.split(";")
                                var cleanEpc = ""

                                for (dt in parts) {
                                    if (dt.startsWith("epcdc:")) {
                                        cleanEpc = dt.replace("epcdc:", "").trim()
                                    }
                                }

                                if (cleanEpc.isEmpty()) {
                                    cleanEpc = parts.firstOrNull { !it.startsWith("rssi:") && !it.startsWith("loc:") }?.trim() ?: ""
                                }

                                if (cleanEpc.isNotEmpty()) {
                                    eventSink?.success("TAG:$cleanEpc")
                                }
                            }
                        }
                    }
                }
                SDConsts.Msg.SDMsg -> {
                    if (msg.arg1 == SDConsts.SDCmdMsg.SLED_WAKEUP) {
                        if (msg.arg2 == SDConsts.SDResult.SUCCESS) {
                            Log.d("RFID_DEBUG", "✅ SLED Woke up. Connecting Radio...")

                            // NOW WE CONNECT THE RADIO
                            val connectResult = mReader?.SD_Connect()

                            if (connectResult == SDConsts.SDResult.SUCCESS || connectResult == SDConsts.SDResult.ALREADY_CONNECTED) {
                                Log.d("RFID_DEBUG", "✅ SLED CONNECTED! READY TO SCAN.")
                                mReader?.SD_SetTriggerMode(SDConsts.SDTriggerMode.RFID)
                            } else {
                                Log.e("RFID_DEBUG", "❌ SLED Connect Failed: $connectResult")
                            }
                        } else {
                            Log.e("RFID_DEBUG", "❌ SLED Wakeup failed!")
                        }
                    } else if (msg.arg1 == SDConsts.SDCmdMsg.TRIGGER_PRESSED) {
                        eventSink?.success("STATUS:START")
                        startInventory()
                    } else if (msg.arg1 == SDConsts.SDCmdMsg.TRIGGER_RELEASED) {
                        eventSink?.success("STATUS:STOP")
                        stopInventory()
                    }
                }
            }
        }
    }
}