import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../bluetooth.printer.provider.dart';
import 'find.devices.widget.dart';

class BluetoothPrinterSettingDialog extends StatelessWidget {
  const BluetoothPrinterSettingDialog({super.key});

  @override
  Widget build(BuildContext context) {
    BluetoothPrinterProvider printer = context.watch<BluetoothPrinterProvider>();
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.all(12),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "อุปกรณ์ที่ใช้งานอยู่",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              FutureBuilder<BluetoothDevice?>(
                future: printer.selectedPrinter,
                builder: (context, snapshot) {
                  BluetoothDevice? data = snapshot.data;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: data == null
                        ? [
                            const Text("ไม่มีอุปกรณ์ที่ใช้งานอยู่"),
                            const SizedBox(width: 10),
                            _button(
                              onTap: () => _scanBluetoothDevices(context),
                              text: "Find Devices",
                            ),
                          ]
                        : [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(data.platformName),
                                Text(data.remoteId.toString()),
                              ],
                            ),
                            const SizedBox(width: 10),
                            _button(
                              onTap: () async => await printer.disconnect(data),
                              color: Colors.red,
                              text: "Disconnect",
                            ),
                          ],
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _button({String text = "", required void Function() onTap, Color color = Colors.blue}) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              text,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _scanBluetoothDevices(BuildContext context) async {
    BluetoothPrinterProvider printerPvd = context.read<BluetoothPrinterProvider>();
    if (await Permission.bluetoothConnect.request().isDenied) return;
    if (!(await printerPvd.isOn)) throw Exception("Bluetooth being turned off.");
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) => const FindDevicesWidget(),
      ).then((value) => printerPvd.stopScan());
    }
  }
}
