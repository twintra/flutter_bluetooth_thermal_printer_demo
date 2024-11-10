package com.niwiart.flutter_bluetooth_printer_demo.thermalPrinterX

import android.Manifest
import android.annotation.SuppressLint
import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Handler
import android.os.Message
import android.util.Log
import androidx.core.app.ActivityCompat
import com.niwiart.flutter_bluetooth_printer_demo.thermalPrinterX.ThermalPrinterXMethodHandler.Companion
import java.util.concurrent.ConcurrentHashMap

class BluetoothController(private var activity: Activity, listener: Listener) {


    private var mBtAdapter: BluetoothAdapter;

    private var mListener: Listener = listener;
    private var mBluetoothChatService: BluetoothChatService? = null

    /**
     * Scan bluetooth devices
     */
    fun startScan() {
        if (ActivityCompat.checkSelfPermission(
                activity,
                Manifest.permission.BLUETOOTH_SCAN
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            val permissions = arrayOf<String>( Manifest.permission.BLUETOOTH_SCAN )
            ActivityCompat.requestPermissions(activity, permissions, 1)
            return
        } else {

            mBtAdapter.startDiscovery()
        }
    }

    fun stopScan() {
        if (ActivityCompat.checkSelfPermission(
                activity,
                Manifest.permission.BLUETOOTH_SCAN
            ) != PackageManager.PERMISSION_GRANTED
        ) else {
            mBtAdapter.cancelDiscovery()

        }
    }

    // Handles various events fired by the Service.
    // ACTION_GATT_CONNECTED: connected to a GATT server.
    // ACTION_GATT_DISCONNECTED: disconnected from a GATT server.
    // ACTION_GATT_SERVICES_DISCOVERED: discovered GATT services.
    // ACTION_DATA_AVAILABLE: received data from the device.  This can be a result of read
    //                        or notification operations.
    private val mGattUpdateReceiver: BroadcastReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            val action = intent.action
            if (BluetoothDevice.ACTION_FOUND == action) {
                if (ActivityCompat.checkSelfPermission(
                        activity,
                        Manifest.permission.BLUETOOTH_SCAN
                    ) != PackageManager.PERMISSION_GRANTED
                ) return;
                val device =
                    intent.getParcelableExtra<BluetoothDevice>(BluetoothDevice.EXTRA_DEVICE)
                mListener.onFoundDevice(device)
                Log.i(
                    DEBUG_TAG,
                    "<<<Bluetooth Devices>>>  On Found Device : " + device!!.name + "  MAC:" + device.address
                )
            } else if (BluetoothAdapter.ACTION_DISCOVERY_FINISHED == action) {
                Log.i(DEBUG_TAG, "<<<Bluetooth Devices>>>  Stop Scan.......")
                mListener.onStopScan()
            } else if (BluetoothAdapter.ACTION_DISCOVERY_STARTED == action) {
                Log.i(DEBUG_TAG, "<<<Bluetooth Devices>>>  Start Scan.......")
                mListener.onStartScan()
            }
        }
    }

    //GATT
    private var mHandler: Handler = @SuppressLint("HandlerLeak")
    object : Handler() {
        override fun handleMessage(msg: Message) {
            super.handleMessage(msg)
            when (msg.what) {
                Const.MESSAGE_BLUETOOTH_STATE_CHANGE -> {
                    mListener.onStateChange(msg.arg1)
                    when (msg.arg1) {
                        BluetoothChatService.STATE_CONNECTING -> Log.i(
                            DEBUG_TAG,
                            "<<<Bluetooth Devices>>>  Connecting"
                        )
                        BluetoothChatService.STATE_CONNECTED -> {
                            Log.i(DEBUG_TAG, "<<<Bluetooth Devices>>>  connected")
                            mListener.onConnected()
                        }
                        BluetoothChatService.STATE_NONE -> {
                            Log.i(DEBUG_TAG, "<<<Bluetooth Devices>>>  disconnected")
                            mListener.onDisconnected()
                        }
                        else -> {}
                    }
                }
                Const.MESSAGE_BLUETOOTH_DATA -> mListener.onReceiveData(msg.obj as ByteArray)
            }
        }
    }

    /**
     * connect the bluetooth device
     * @param context
     * @param device
     */
    fun connect(context: Context, device: BluetoothDevice) {
        mBluetoothChatService = BluetoothChatService(context, mHandler)
        mBluetoothChatService!!.connect(device, true)
    }

    /**
     * Disconnect the bluetooth
     */
    fun disconnect() {
        if(mBluetoothChatService == null) return
        mBluetoothChatService!!.stop()
    }

    /**
     * Send data to the monitor
     * @param data
     */
    fun write(data: ByteArray?) {
        if(mBluetoothChatService == null) return
        mBluetoothChatService!!.write(data)
    }

    fun registerBroadcastReceiver(context: Context) {
        context.registerReceiver(mGattUpdateReceiver, makeGattUpdateIntentFilter())
    }

    fun unregisterBroadcastReceiver(context: Context) {
        context.unregisterReceiver(mGattUpdateReceiver)
    }

    private fun makeGattUpdateIntentFilter(): IntentFilter {
        val intentFilter = IntentFilter()
        intentFilter.addAction(BluetoothDevice.ACTION_FOUND)
        intentFilter.addAction(BluetoothDevice.ACTION_BOND_STATE_CHANGED)
        intentFilter.addAction(BluetoothAdapter.ACTION_DISCOVERY_FINISHED)
        intentFilter.addAction(BluetoothAdapter.ACTION_DISCOVERY_STARTED)
        return intentFilter
    }

    interface Listener {
        fun onFoundDevice(device: BluetoothDevice?)
        fun onStopScan()
        fun onStartScan()
        fun onConnected()
        fun onDisconnected()
        fun onStateChange(state: Int)
        fun onReceiveData(data: ByteArray?)
    }

    init {
        val btManager = activity.getSystemService(Activity.BLUETOOTH_SERVICE) as BluetoothManager
        mBtAdapter = btManager.adapter
    }

    companion object {
        private const val DEBUG_TAG : String = "BluetoothController";
    }
}