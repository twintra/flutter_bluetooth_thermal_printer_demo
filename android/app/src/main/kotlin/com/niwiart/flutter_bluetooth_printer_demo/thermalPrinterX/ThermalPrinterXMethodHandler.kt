package com.niwiart.flutter_bluetooth_printer_demo.thermalPrinterX

import android.annotation.SuppressLint
import android.app.Activity
import android.bluetooth.BluetoothDevice
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class ThermalPrinterXMethodHandler(private var methodChannel:MethodChannel ) : MethodChannel.MethodCallHandler, BluetoothController.Listener {

    private var activity: Activity? = null;
    private var mBtController : BluetoothController? = null;
    private val foundDevices : ArrayList<BluetoothDevice> = ArrayList();

    fun initActivity(activity: Activity) {
        if(this.activity != null || mBtController != null) return;
        this.activity = activity
        mBtController = BluetoothController(activity, this)
        mBtController!!.registerBroadcastReceiver(activity)
    }

    fun closeActivity() {
        if(activity == null || mBtController == null) return;
        mBtController!!.disconnect();
        mBtController!!.unregisterBroadcastReceiver(activity!!)
        mBtController = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if(activity == null || mBtController == null) {
            result.error("500","Activity is null", "Activity is still null in this process.")
            return
        }

        when (call.method) {
            "startScan" -> {
                mBtController!!.startScan();
                result.success(true);
                return;
            }
            "stopScan" -> {
                mBtController!!.stopScan();
                result.success(true);
                return;
            }
            "connect" -> {
                val mac: String = call.argument<String>("remote_id")
                    ?: return result.error("500", "Args error","Please provide remote_id");
                val targetDevice : BluetoothDevice = foundDevices.findLast { it -> it.address == mac }
                    ?: return result.error("500", "Not found","No found device with MAC : $mac")
                mBtController!!.connect(activity!!, targetDevice );
                result.success(true);
                return;
            }
            "disconnect" -> {
                mBtController!!.disconnect();
                result.success(true);
                return;
            }
            "writeByte" -> {
                val data: List<Int> = call.argument<List<Int>>("data") ?: listOf<Int>();

                var bytes: ByteArray = "\n".toByteArray()

                data.forEach{
                    bytes += it.toByte()
                }

                mBtController!!.write(bytes);
                result.success(true);
                return;

            }
            else -> {
                result.notImplemented();
            }
        }
    }

    @SuppressLint("MissingPermission")
    override fun onFoundDevice(device: BluetoothDevice?) {
        if(foundDevices.contains(device)) return;
        Log.d(DEBUG_TAG, "found device ${device!!.address}" )
        val params:HashMap<String, Any> = HashMap();
        params["remote_id"] = device.address;
        params["name"] = device.name ?:"-";

        foundDevices.add(device)
        val foundDevicesMaps: List<HashMap<String, String>> = foundDevices.map { bluetoothDevice -> hashMapOf(
            "remote_id" to bluetoothDevice.address,
            "name" to "${bluetoothDevice.name ?:'-'}",
        ) }.toList()
        val args:HashMap<String, Any> = HashMap();
        args["data"] = foundDevicesMaps;

        invokeMethodUIThread("onFoundDevice", args)
    }

    override fun onStopScan() {
        Log.d(DEBUG_TAG, "stopScan" )
        val args:HashMap<String, Any> = HashMap();
        args["data"] = true;
        invokeMethodUIThread("onStopScan", args)
    }

    override fun onStartScan() {
        foundDevices.clear();
        Log.d(DEBUG_TAG, "startScan" )
    }

    override fun onConnected() {
        Log.d(DEBUG_TAG, "onConnect" )
        val args:HashMap<String, Any> = HashMap();
        args["data"] = true;
        invokeMethodUIThread("isConnected", args)
    }

    override fun onDisconnected() {
        Log.d(DEBUG_TAG, "onDisconnect" )
        val args:HashMap<String, Any> = HashMap();
        args["data"] = false;
        invokeMethodUIThread("isConnected", args)
    }

    override fun onStateChange(state: Int) {
        val args:HashMap<String, Any> = HashMap();
        args["data"] = state;
        invokeMethodUIThread("onStateChange", args)
    }

    override fun onReceiveData(data: ByteArray?) {
        Log.d(DEBUG_TAG, "onReceiveData: $data" )
    }

    private fun invokeMethodUIThread(method: String, data: HashMap<String, Any>) {
        Handler(Looper.getMainLooper()).post {
            //Could already be teared down at this moment
            // Log.d(debugTag, "invoking method channel $method")
            methodChannel.invokeMethod(method, data)

        }
    }

    companion object {
        const val DEBUG_TAG: String = "ThermalPrinterX"
    }

}