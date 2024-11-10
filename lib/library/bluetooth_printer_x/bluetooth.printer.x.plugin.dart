// ignore_for_file: constant_identifier_names

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum DeviceConnectionState {
  STATE_NONE, // we're doing nothing
  STATE_LISTEN, // now listening for incoming connections
  STATE_CONNECTING, // now initiating an outgoing connection
  STATE_CONNECTED, // now connected to a remote device
}

class BluetoothPrinterXPlugin {
  static bool _initialized = false;
  static const MethodChannel _methodChannel = MethodChannel("com.niwiart.plugin/plugin/bluetooth/method");
  static final StreamController<MethodCall> _methodStream = StreamController.broadcast();

  static StreamSubscription<dynamic>? _stateSubscription;
  static final StreamController<DeviceConnectionState> _state = StreamController<DeviceConnectionState>.broadcast();
  static Stream<DeviceConnectionState> get state => _state.stream;

  static Stream<T?> onEvent<T>(String eventName) {
    return _methodStream.stream.where((m) => m.method == eventName).map((event) => event.arguments).map((args) {
      if (args["data"] == null) return null;
      try {
        return args["data"] as T;
      } catch (e) {
        debugPrint("$e");
        return null;
      }
    });
  }

  static Future<void> _initService() async {
    if (_initialized) return;
    _initialized = true;

    _methodChannel.setMethodCallHandler((call) async {
      _methodStream.add(call);
    });
  }

  static Future<dynamic> _invokeMethod(String method, [dynamic arguments]) async {
    //
    _initService();

    dynamic output = await _methodChannel.invokeMethod(method, arguments);

    return output;
  }

  static Future<void> startScan() async {
    await _invokeMethod("startScan");
  }

  static Future<void> stopScan() async {
    await _invokeMethod("stopScan");
  }

  static Future<void> connect(String remoteId) async {
    _state.add(DeviceConnectionState.STATE_NONE);
    _stateSubscription =
        _methodStream.stream.where((m) => m.method == "onStateChange").map((m) => m.arguments).listen((args) {
      if (args["data"] != null) {
        int data = args["data"];
        DeviceConnectionState state = DeviceConnectionState.values.lastWhere((e) => e.index == data);
        _state.add(state);
      }
    });
    await _invokeMethod("connect", {"remote_id": remoteId});
  }

  static Future<void> disconnect() async {
    await _invokeMethod("disconnect");
    if (_stateSubscription != null) {
      _stateSubscription!.cancel();
      _stateSubscription = null;
    }
  }

  static Future<void> writeByte(List<int> data) async {
    print(await _invokeMethod("writeByte", {"data": data}));
  }
}
