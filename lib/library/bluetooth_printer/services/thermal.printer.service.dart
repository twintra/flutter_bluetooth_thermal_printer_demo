import 'package:flutter/services.dart';

class ThermalPrinterService {
  static const MethodChannel _methodChannel = MethodChannel("com.abbot.health_station/plugin/thermalPrinter/method");

  static Future<bool> connect(String macAddress) async {
    return await _methodChannel.invokeMethod("connect", {"macAddress": macAddress});
  }

  static Future<bool> disconnect() async {
    return await _methodChannel.invokeMethod("disconnect");
  }

  static Future<bool> writeByte(List<int> data) async {
    return await _methodChannel.invokeMethod("writeByte", {"data": data});
  }

  static Future<bool> isConnected() async {
    return await _methodChannel.invokeMethod("isConnected");
  }

  static Future<bool> bluetoothState() async {
    return await _methodChannel.invokeMethod("bluetoothState");
  }
}
