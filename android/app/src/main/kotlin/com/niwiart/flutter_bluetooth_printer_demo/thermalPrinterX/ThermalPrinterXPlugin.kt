package com.niwiart.flutter_bluetooth_printer_demo.thermalPrinterX

import com.niwiart.flutter_bluetooth_printer_demo.thermalPrinterX.ThermalPrinterXMethodHandler
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodChannel

class ThermalPrinterXPlugin: FlutterPlugin, ActivityAware {

    private val thermalPrinterMethodChannel = "com.niwiart.plugin/plugin/bluetooth/method";

    private lateinit var methodChannel: MethodChannel;
    private lateinit var methodHandler: ThermalPrinterXMethodHandler ;

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel = MethodChannel(binding.binaryMessenger, thermalPrinterMethodChannel);
        methodHandler = ThermalPrinterXMethodHandler(methodChannel);
        methodChannel.setMethodCallHandler(methodHandler);
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null);
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        methodHandler.initActivity(binding.activity);
    }

    override fun onDetachedFromActivityForConfigChanges() {
        methodHandler.closeActivity();
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        methodHandler.initActivity(binding.activity);
    }

    override fun onDetachedFromActivity() {
        methodHandler.closeActivity();
    }
}