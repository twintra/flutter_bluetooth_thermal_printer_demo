package com.niwiart.flutter_bluetooth_printer_demo.thermalPrinter

import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.util.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.OutputStream
import java.util.*

class ThermalPrinterMethodHandler: MethodChannel.MethodCallHandler {
    private val debugTag : String = "ThermalPrinterMethodHandler"

    private var outputStream: OutputStream? = null

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {

        when (call.method) {
            "connect" -> {
                Log.d(debugTag, "connect")
                var macAddress :String = call.argument<String>("macAddress") ?: "";
                if(macAddress.isEmpty()) {
                    result.error("500", "Invalid argument", "macAddress could not be empty or null");
                    return
                }else {
                    GlobalScope.launch (Dispatchers.Main){
                        if(!isConnected()){
                            outputStream = connect(macAddress)?.apply { result.success(true) }
                        }else {
                            result.success(false)
                        }
                    }

                }

            }
            "disconnect" -> {
                if(isConnected()){
                    outputStream?.close()
                    outputStream = null
                    result.success(true);
                }else{
                    result.success(false);
                }

            }
            "isConnected" -> {
                result.success(isConnected());
            }
            "bluetoothState" -> {
                result.success(bluetoothState());
            }
            "writeByte" -> {
                var data :List<Int> = call.argument<List<Int>>("data") ?: listOf<Int>();
                if(!isConnected()) {
                    result.error("500", "Device is not being paired", "Please make a bluetooth pairing with the device to use this function");
                    return;
                }
                var bytes: ByteArray = "\n".toByteArray()

                data.forEach{
                    bytes += it.toByte()
                }

                try {
                    outputStream?.run {
                        write(bytes)
                        result.success(true)
                    }
                } catch (e : Exception){
                    result.error("500", e.message, e.stackTrace);
                    outputStream?.close()
                    outputStream = null
                }

            }
            else -> {
                result.notImplemented();
            }
        }
    }

    private fun isConnected(): Boolean {
        return outputStream!=null;
    }

    private fun bluetoothState(): Boolean {
        val bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
        return bluetoothAdapter != null && bluetoothAdapter.isEnabled
    }

    @SuppressLint("MissingPermission")
    private suspend fun connect(macAddress:String): OutputStream? {
        return withContext(Dispatchers.IO) {
            var outputStream : OutputStream? = null;
            val bluetoothAdapter : BluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
            if(bluetoothAdapter != null && bluetoothAdapter.isEnabled) {
                try {
                    val bluetoothDevice = bluetoothAdapter.getRemoteDevice(macAddress);
                    val bluetoothSocket = bluetoothDevice?.createRfcommSocketToServiceRecord(
                        UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")
                    )
                    bluetoothAdapter.cancelDiscovery()
                    bluetoothSocket?.connect()
                    if(bluetoothSocket!!.isConnected) outputStream = bluetoothSocket!!.outputStream;
                } catch (e: Exception) {
                    Log.d(debugTag, "connect error: ${e.message}");
                }
            } else {
                Log.d(debugTag, "Problem with adapter");
            }
            outputStream;
        }
    }
}