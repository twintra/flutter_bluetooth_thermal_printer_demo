import 'package:flutter/material.dart';
import '../bluetooth.printer.x.plugin.dart';
import '../bluetooth.printer.x.provider.dart';
import 'package:provider/provider.dart';

class ScanDeviceDialog extends StatefulWidget {
  const ScanDeviceDialog({super.key});

  @override
  State<ScanDeviceDialog> createState() => _ScanDeviceDialogState();
}

class _ScanDeviceDialogState extends State<ScanDeviceDialog> {
  @override
  void initState() {
    BluetoothPrinterXProvider pvd = context.read<BluetoothPrinterXProvider>();
    pvd.startScan();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    BluetoothPrinterXProvider pvd = context.watch<BluetoothPrinterXProvider>();
    return AlertDialog(
      content: FractionallySizedBox(
        heightFactor: 0.8,
        child: pvd.connectionState == DeviceConnectionState.STATE_CONNECTED
            ? Center(
                child: GestureDetector(
                  onTap: pvd.disconnect,
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    decoration:
                        BoxDecoration(color: Colors.red.withOpacity(0.5), borderRadius: BorderRadius.circular(20)),
                    child: const Text("Disconnect"),
                  ),
                ),
              )
            : Column(
                children: [
                  const Text("Found devices"),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: pvd.scanResults
                            .map((e) => e.name == "-"
                                ? const SizedBox()
                                : ListTile(
                                    onTap: pvd.connectionState == DeviceConnectionState.STATE_CONNECTED
                                        ? null
                                        : () async {
                                            await pvd.connect(e.remoteId);
                                          },
                                    title: Text(e.name),
                                    subtitle: Text(e.remoteId),
                                  ))
                            .toList(),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
