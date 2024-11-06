package com.niwiart.flutter_bluetooth_printer_demo.thermalPrinter

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodChannel

class ThermalPrinterPlugin: FlutterPlugin {

    private val thermalPrinterMethodChannel = "com.abbot.health_station/plugin/thermalPrinter/method";

    private lateinit var methodChannel: MethodChannel;

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel = MethodChannel(binding.binaryMessenger, thermalPrinterMethodChannel);
        methodChannel.setMethodCallHandler(ThermalPrinterMethodHandler());
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null);
    }
}