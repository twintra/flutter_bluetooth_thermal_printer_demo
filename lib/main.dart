import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_printer_demo/app.dart';
import 'package:flutter_bluetooth_printer_demo/library/bluetooth_printer/bluetooth.printer.provider.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => BluetoothPrinterProvider()),
    ],
    child: const App(),
  ));
}
