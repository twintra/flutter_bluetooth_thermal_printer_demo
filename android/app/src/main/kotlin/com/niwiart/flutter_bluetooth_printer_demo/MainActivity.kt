package com.niwiart.flutter_bluetooth_printer_demo

import com.niwiart.flutter_bluetooth_printer_demo.thermalPrinter.ThermalPrinterPlugin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        flutterEngine.plugins.add(ThermalPrinterPlugin())
    }
}
