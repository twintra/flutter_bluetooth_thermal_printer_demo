import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_printer_demo/app.dart';
import 'package:flutter_bluetooth_printer_demo/library/bluetooth_printer_x/bluetooth.printer.x.provider.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => BluetoothPrinterXProvider()),
    ],
    child: const App(),
  ));
}
