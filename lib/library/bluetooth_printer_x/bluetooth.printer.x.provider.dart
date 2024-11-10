import 'dart:ui' as ui;
import 'dart:async';

import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import './bluetooth.printer.x.plugin.dart';
import './widgets/scan.device.dialog.dart';
import 'package:image/image.dart';

import 'models/scan.result.dart';

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

class BluetoothPrinterXProvider extends ChangeNotifier {
  late StreamSubscription<bool?> _isConnectedSub;
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  StreamSubscription<DeviceConnectionState>? _connectionStateSub;
  DeviceConnectionState _connectionState = DeviceConnectionState.STATE_NONE;
  DeviceConnectionState get connectionState => _connectionState;

  StreamSubscription<List<ScanResult>?>? _scanResultsSub;
  StreamSubscription? _stopScanSub;
  bool get isScanning => _scanResultsSub != null;

  List<ScanResult> _scanResults = [];
  Iterable<ScanResult> get scanResults => List.unmodifiable(_scanResults);

  BluetoothPrinterXProvider() {
    _isConnectedSub = BluetoothPrinterXPlugin.onEvent<bool>("isConnected").listen((isConnected) {
      _isConnected = isConnected ?? false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    super.dispose();
    _isConnectedSub.cancel();
  }

  Future<void> startScan() async {
    if (isScanning) return;
    _scanResultsSub = BluetoothPrinterXPlugin.onEvent("onFoundDevice").map((data) {
      if (data == null) return null;
      List<ScanResult> d = [];
      for (var value in data) {
        Map<Object?, Object?> map = value as Map<Object?, Object?>;
        d.add(ScanResult.fromNative(map));
      }
      return d;
    }).listen((scanResult) {
      _scanResults = scanResult ?? [];
      notifyListeners();
    });
    _stopScanSub = BluetoothPrinterXPlugin.onEvent("onStopScan").listen(_onStopScan);
    await BluetoothPrinterXPlugin.startScan();
  }

  Future<void> stopScan() async {
    if (!isScanning) return;
    await BluetoothPrinterXPlugin.stopScan();
  }

  void _onStopScan(dynamic data) {
    if (_scanResultsSub != null) {
      _scanResultsSub!.cancel();
      _scanResultsSub = null;
    }
    if (_stopScanSub != null) {
      _stopScanSub!.cancel();
      _stopScanSub = null;
    }
  }

  Future<void> connect(String remoteId) async {
    print("connect $remoteId, ${_connectionState == DeviceConnectionState.STATE_CONNECTED}");
    if (_connectionState == DeviceConnectionState.STATE_CONNECTED) return;
    _connectionStateSub = BluetoothPrinterXPlugin.onEvent("onStateChange")
        .map((data) => DeviceConnectionState.values.lastWhere((e) => e.index == data))
        .listen((state) {
      if (state == DeviceConnectionState.STATE_NONE) _onDisconnected();
      _connectionState = state;
      notifyListeners();
    });
    await BluetoothPrinterXPlugin.connect(remoteId);
  }

  Future<void> disconnect() async {
    if (_connectionState != DeviceConnectionState.STATE_CONNECTED) return;
    await BluetoothPrinterXPlugin.disconnect();
  }

  void _onDisconnected() async {
    if (_connectionStateSub != null) {
      _connectionStateSub!.cancel();
      _connectionStateSub = null;
    }
  }

  Future<void> printReceipt(BuildContext context, {List<int> data = const []}) async {
    if (!_isConnected) return;
    try {
      print("printReceipt, ${data}");
      await BluetoothPrinterXPlugin.writeByte(data);
    } catch (e) {
      notifyListeners();
      if (context.mounted) await showScanDeviceDialog(context);
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

  Future<List<int>> getByteFromTSPL(List<String> tsplCommands) async {
    final gen = Generator(PaperSize.mm58, await CapabilityProfile.load());
    String bytes = "";
    for (String tsplCommand in tsplCommands) {
      bytes += "$tsplCommand\n";
    }
    print("Command: $bytes");
    return gen.rawBytes(bytes.codeUnits);
  }

  Future<List<int>> receipt(BuildContext context,
      {String title = "", String name = "", String serviceCode = "", int queueBefore = 0}) async {
    String optionprinttype = "80 mm";
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

  Future<void> showScanDeviceDialog(BuildContext context) async {
    List<Permission> permissions = [
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
    ];

    Map<Permission, PermissionStatus> statuses = await permissions.request();

    for (Permission permission in statuses.keys) {
      print(statuses[permission]);
      if (statuses[permission] != PermissionStatus.granted) return;
    }
    if (!context.mounted) return;
    await showDialog(context: context, builder: (context) => const ScanDeviceDialog()) //
        .then(
      (value) => stopScan(),
    );
  }
}
