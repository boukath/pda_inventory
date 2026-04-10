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

    // =========================================================
    // --- OPTIMIZATION: Pre-allocate memory for 2048 tags ---
    // Prevents the HashSet from pausing to resize itself during heavy scans
    // =========================================================
    private val scannedTags = HashSet<String>(2048)

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

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL_NAME).setMethodCallHandler { call, methodResult ->
            when (call.method) {
                "connectHardware" -> {
                    connectToSled()
                    methodResult.success(null)
                }
                "disconnectHardware" -> {
                    mReader?.SD_Disconnect()
                    methodResult.success(null)
                }
                "startScan" -> {
                    startInventory()
                    methodResult.success(null)
                }
                "stopScan" -> {
                    stopInventory()
                    methodResult.success(null)
                }
                "writeEpc" -> {
                    val newEpc = call.argument<String>("newEpc")
                    if (newEpc != null) {
                        writeTagEpc(newEpc)
                        methodResult.success(true)
                    } else {
                        methodResult.error("INVALID_EPC", "EPC must be a valid hex string of proper length", null)
                    }
                }
                "setTxPower" -> {
                    val power = call.argument<Int>("power") ?: 30
                    if (mReader?.SD_GetConnectState() == SDConsts.SDConnectState.CONNECTED) {
                        try {
                            val ret = mReader?.RF_SetRadioPowerState(power)
                            Log.d("RFID_DEBUG", "📡 Antenna Power Set to $power dBm. Result: $ret")
                            methodResult.success(true)
                        } catch (e: Exception) {
                            Log.e("RFID_DEBUG", "❌ Exception setting power: ${e.message}")
                            methodResult.error("HARDWARE_ERROR", e.message, null)
                        }
                    } else {
                        Log.e("RFID_DEBUG", "❌ Cannot set power. Sled disconnected.")
                        methodResult.error("DISCONNECTED", "Sled is not connected", null)
                    }
                }
                "getBattery" -> {
                    if (mReader?.SD_GetConnectState() == SDConsts.SDConnectState.CONNECTED) {
                        mReader?.SD_GetBatteryStatus() // Asks hardware to broadcast battery
                        methodResult.success(true)
                    } else {
                        methodResult.error("DISCONNECTED", "Sled is not connected", null)
                    }
                }
                else -> methodResult.notImplemented()
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
        val openStatus = mReader?.SD_Open()
        Log.d("RFID_DEBUG", "🔓 SD_Open Status: $openStatus")

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
        connectToSled()
    }

    override fun onPause() {
        setBarcodeKeyMapOn(true)
        mReader?.RF_StopInventory()
        super.onPause()
    }

    override fun onDestroy() {
        mReader?.SD_Disconnect()
        mReader?.SD_Close()
        super.onDestroy()
    }

    private fun startInventory() {
        if (mReader?.SD_GetConnectState() == SDConsts.SDConnectState.CONNECTED) {
            scannedTags.clear()
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

    private fun writeTagEpc(newEpc: String) {
        if (mReader?.SD_GetConnectState() == SDConsts.SDConnectState.CONNECTED) {
            Log.d("RFID_DEBUG", "✏️ Attempting to write EPC: $newEpc")

            Thread {
                try {
                    val accessPassword = "00000000"
                    val result = mReader?.RF_WRITE(SDConsts.RFMemType.EPC, 2, newEpc, accessPassword, false)
                    Log.d("RFID_DEBUG", "Write Command Sent. Immediate Return Code: $result")
                } catch (e: Exception) {
                    Log.e("RFID_DEBUG", "❌ Exception during write command", e)
                }
            }.start()

        } else {
            Log.e("RFID_DEBUG", "❌ Cannot write. Sled disconnected.")
            connectToSled()
        }
    }

    private val sledHandler = object : Handler(Looper.getMainLooper()) {
        override fun handleMessage(msg: Message) {
            when (msg.what) {
                SDConsts.Msg.RFMsg -> {
                    if (msg.arg1 == SDConsts.RFCmdMsg.INVENTORY || msg.arg1 == SDConsts.RFCmdMsg.READ) {
                        if (msg.arg2 == SDConsts.RFResult.SUCCESS) {
                            val rawData = msg.obj?.toString()
                            if (rawData != null && rawData.isNotEmpty()) {

                                // =========================================================
                                // --- HYPER-FAST PARSING: No split(), no replace() array creation ---
                                // =========================================================
                                var cleanEpc = ""
                                val epcIndex = rawData.indexOf("epcdc:")

                                if (epcIndex != -1) {
                                    val start = epcIndex + 6 // Jump past "epcdc:"
                                    var end = rawData.indexOf(';', start)
                                    if (end == -1) end = rawData.length
                                    cleanEpc = rawData.substring(start, end).trim()
                                } else {
                                    var end = rawData.indexOf(';')
                                    if (end == -1) end = rawData.length
                                    val tempString = rawData.substring(0, end).trim()

                                    if (!tempString.startsWith("rssi:") && !tempString.startsWith("loc:")) {
                                        cleanEpc = tempString
                                    }
                                }

                                if (cleanEpc.isNotEmpty()) {
                                    if (scannedTags.add(cleanEpc)) {
                                        eventSink?.success("TAG:$cleanEpc")
                                    }
                                }
                            }
                        }
                    }
                    else if (msg.arg1 == SDConsts.RFCmdMsg.WRITE || msg.arg1 == SDConsts.RFCmdMsg.WRITE_TAG_ID) {
                        if (msg.arg2 == SDConsts.RFResult.SUCCESS) {
                            Log.d("RFID_DEBUG", "✅ Physical Tag Written Successfully!")
                            eventSink?.success("STATUS:WRITE_SUCCESS")
                        } else {
                            Log.e("RFID_DEBUG", "❌ Physical Tag Write Failed. Make sure tag is close.")
                            eventSink?.success("STATUS:WRITE_FAILED")
                        }
                    }
                }
                SDConsts.Msg.SDMsg -> {
                    if (msg.arg1 == SDConsts.SDCmdMsg.SLED_WAKEUP) {
                        if (msg.arg2 == SDConsts.SDResult.SUCCESS) {
                            Log.d("RFID_DEBUG", "✅ SLED Woke up. Connecting Radio...")

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
                    else if (msg.arg1 == SDConsts.SDCmdMsg.SLED_BATTERY_STATE_CHANGED) {
                        val batteryLevel = msg.arg2
                        Log.d("RFID_DEBUG", "🔋 Sled Battery: $batteryLevel%")
                        eventSink?.success("BATTERY:$batteryLevel")
                    }
                }
            }
        }
    }
}