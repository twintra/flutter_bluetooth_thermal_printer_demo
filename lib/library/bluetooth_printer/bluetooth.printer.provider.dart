import 'dart:ui' as ui;
import 'package:image/image.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'services/thermal.printer.service.dart';
import 'widgets/bluetooth.printer.setting.dialog.dart';
import 'widgets/find.devices.widget.dart';

String _engToThaiLite(String eng) {
  List<String> alphabetsList = eng.split("");
  String result = "";
  for (String alphabet in alphabetsList) {
    switch (alphabet.toLowerCase()) {
      case "a":
        result += "เอ";
        break;
      case "b":
        result += "บี";
        break;
      case "c":
        result += "ซี";
        break;
      case "d":
        result += "ดี";
        break;
      case "e":
        result += "อี";
        break;
      case "f":
        result += "เอฟ";
        break;
      case "g":
        result += "จี";
        break;
      case "h":
        result += "เอช";
        break;
      case "i":
        result += "ไอ";
        break;
      case "j":
        result += "เจ";
        break;
      case "k":
        result += "เค";
        break;
      case "l":
        result += "แอล";
        break;
      case "m":
        result += "เอ็ม";
        break;
      case "n":
        result += "เอ็น";
        break;
      case "o":
        result += "โอ";
        break;
      case "p":
        result += "พี";
        break;
      case "q":
        result += "คิว";
        break;
      case "r":
        result += "อาร์";
        break;
      case "s":
        result += "เอส";
        break;
      case "t":
        result += "ที";
        break;
      case "u":
        result += "ยู";
        break;
      case "v":
        result += "วี";
        break;
      case "w":
        result += "ดับเบิลยู";
        break;
      case "x":
        result += "เอ็กซ์";
        break;
      case "y":
        result += "วาย";
        break;
      case "z":
        result += "แซด";
        break;
      default:
        result += alphabet;
    }
  }
  return result;
}

class BluetoothPrinterProvider extends ChangeNotifier {
  //

  List<ScanResult> _scanResults = [];
  List<ScanResult> get scanResults => _scanResults;

  List<BluetoothDevice> _connectedDevices = [];
  List<BluetoothDevice> get connectedDevices => _connectedDevices;

  BluetoothDevice? _selectedPrinter;
  Future<BluetoothDevice?> get selectedPrinter async {
    bool value = await ThermalPrinterService.isConnected();
    if (!value) _selectedPrinter = null;
    return _selectedPrinter;
  }

  BluetoothAdapterState _state = BluetoothAdapterState.off;
  BluetoothAdapterState get state => _state;

  bool _isScanning = false;
  bool get isScanning => _isScanning;

  Future<bool> get isOn async {
    return _state == BluetoothAdapterState.on;
  }

  Future<bool> get isCommunicating async {
    bool value = await ThermalPrinterService.isConnected();
    if (!value) _selectedPrinter = null;
    return value;
  }

  // Constructor
  BluetoothPrinterProvider() {
    debugPrint("============= init bluetooth printer provider =============");
    FlutterBluePlus.scanResults.listen((results) {
      _scanResults = results;
      notifyListeners();
    });
    FlutterBluePlus.isScanning.listen((scanning) {
      _isScanning = scanning;
      notifyListeners();
    });
    FlutterBluePlus.adapterState.listen((btState) {
      _state = btState;
      notifyListeners();
    });

    // _connectedDevicesStream(periodic: const Duration(seconds: 2)).listen((event) {
    //   _checkHandler();
    // });

    // _checkHandler();
  }

  // Stream<List<BluetoothDevice>> _connectedDevicesStream({Duration periodic = const Duration(seconds: 10)}) async* {
  //   List<BluetoothDevice> devices = await _bt.connectedDevices;
  //   while (true) {
  //     List<BluetoothDevice> newDevices = await _bt.connectedDevices;
  //     if (devices.length != newDevices.length) {
  //       devices = newDevices;
  //       debugPrint("Devices online amount changed");
  //       yield newDevices;
  //     }
  //     await Future.delayed(periodic);
  //   }
  // }

  // void _checkHandler() async {
  //   bool communicating = await isCommunicating;
  //   if (!communicating) {
  //     _selectedPrinter = null;
  //     return;
  //   }
  //   for (BluetoothDevice device in connectedDevices) {
  //     if (_selectedPrinter!.id == device.id) {}
  //   }
  //   notifyListeners();
  // }

  Future<void> startScan({Duration? timeout = const Duration(seconds: 4)}) async {
    _connectedDevices = FlutterBluePlus.connectedDevices;
    if (isScanning) return;
    await FlutterBluePlus.startScan(timeout: timeout);
  }

  Future<void> stopScan() async {
    if (!isScanning) return;
    await FlutterBluePlus.stopScan();
  }

  Future<void> toggleConnect(BluetoothDevice device) async {
    try {
      await connect(device);
    } on PlatformException catch (e) {
      if (e.code == "already_connected") disconnect(device);
    } catch (_) {}
  }

  Future<void> connect(BluetoothDevice device) async {
    await disconnect(device);
    await device.connect();
    int index = connectedDevices.indexWhere((element) => element.remoteId == device.remoteId);
    if (index >= 0) return;
    connectedDevices.add(device);
    notifyListeners();
  }

  Future<void> disconnect(BluetoothDevice device) async {
    if (await selectedPrinter != null && (await selectedPrinter)!.remoteId.str == device.remoteId.str) {
      await stopCommunication();
    }
    await device.disconnect();
    connectedDevices.removeWhere((element) => element.remoteId == device.remoteId);
    notifyListeners();
  }

  Future<void> startCommunication(BluetoothDevice device) async {
    try {
      bool result = await ThermalPrinterService.connect(device.remoteId.str);
      if (result) {
        _selectedPrinter = device;
      } else {
        stopCommunication();
        _selectedPrinter = null;
      }
    } catch (e) {
      rethrow;
    }

    notifyListeners();
  }

  Future<void> stopCommunication() async {
    try {
      bool result = await ThermalPrinterService.disconnect();
      if (result) _selectedPrinter = null;
    } catch (e) {
      rethrow;
    }

    notifyListeners();
  }

  Future<void> printReceipt(BuildContext context, {List<int> data = const []}) async {
    if (await isCommunicating) {
      try {
        await ThermalPrinterService.writeByte(data);
      } catch (e) {
        _selectedPrinter = null;
        notifyListeners();
        if (context.mounted) await showBluetoothScan(context);
      }
    } else {
      //no conectado, reconecte
    }
  }

  Future<Uint8List> _generateImageFromString(
    String text,
    ui.TextAlign align, {
    double fontSize = 20,
    ui.FontWeight fontWeight = ui.FontWeight.bold,
    int? maxLines,
  }) async {
    ui.PictureRecorder recorder = ui.PictureRecorder();
    Canvas canvas = Canvas(
      recorder,
      Rect.fromCenter(
        center: const Offset(0, 0),
        width: double.infinity,
        height: double.infinity, // cheated value, will will clip it later...
      ),
    );
    TextSpan span = TextSpan(
      style: TextStyle(
        color: Colors.black,
        fontSize: fontSize,
        fontWeight: fontWeight,
      ),
      text: text,
    );
    TextPainter tp = TextPainter(
      text: span,
      maxLines: maxLines,
      textAlign: align,
      textDirection: TextDirection.ltr,
    );
    tp.layout(minWidth: 0, maxWidth: 380);
    tp.paint(canvas, const Offset(0.0, 0.0));
    var picture = recorder.endRecording();
    final pngBytes = await picture.toImage(
      tp.size.width.toInt(),
      tp.size.height.toInt() - 2, // decrease padding
    );
    final byteData = await pngBytes.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<List<int>> receipt(BuildContext context,
      {String title = "", String name = "", String serviceCode = "", int queueBefore = 0}) async {
    String optionprinttype = "58 mm";
    List<int> bytes = [];
    // Using default profile
    final profile = await CapabilityProfile.load();
    final generator = Generator(optionprinttype == "58 mm" ? PaperSize.mm58 : PaperSize.mm80, profile);
    bytes += generator.reset();

    //Using `ESC *`

    bytes += generator.image(
      decodeImage(
        await _generateImageFromString(
          title,
          TextAlign.center,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      )!,
      align: PosAlign.center,
    );
    bytes += generator.image(
      decodeImage(
        await _generateImageFromString("ชื่อ-สกุล: $name", TextAlign.left),
      )!,
      align: PosAlign.left,
    );
    bytes += generator.image(
      decodeImage(await _generateImageFromString("รหัสรับบริการ", TextAlign.center, fontSize: 30))!,
      align: PosAlign.center,
    );
    final List<dynamic> barData = "{B$serviceCode".split("");
    bytes += generator.barcode(Barcode.code128(barData), textPos: BarcodeText.none);
    bytes += generator.text(
      serviceCode,
      styles: const PosStyles(
        bold: true,
        fontType: PosFontType.fontA,
        width: PosTextSize.size4,
        height: PosTextSize.size4,
        align: PosAlign.center,
      ),
    );
    bytes += generator.image(
      decodeImage(
        await _generateImageFromString(_engToThaiLite(serviceCode), TextAlign.center),
      )!,
      align: PosAlign.center,
    );
    bytes += generator.image(
      decodeImage(
        await _generateImageFromString("จำนวนคิวที่รอก่อนหน้า $queueBefore คิว", TextAlign.center),
      )!,
      align: PosAlign.center,
    );
    bytes += generator.image(
      decodeImage(
        await _generateImageFromString("----------------------------------------------", TextAlign.center, maxLines: 1),
      )!,
      align: PosAlign.center,
    );

    bytes += generator.feed(2);
    //bytes += generator.cut();
    return bytes;
  }

  Future<void> showBluetoothScan(BuildContext context) async {
    return await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) => const FindDevicesWidget(),
    ).then((value) => stopScan());
  }

  Future<void> showSetting(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (context) => const BluetoothPrinterSettingDialog(),
    );
  }
}
