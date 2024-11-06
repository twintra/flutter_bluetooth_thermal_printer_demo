import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';

import '../bluetooth.printer.provider.dart';

class FindDevicesWidget extends StatefulWidget {
  const FindDevicesWidget({super.key});

  @override
  State<FindDevicesWidget> createState() => _FindDeviceWidgetState();
}

class _FindDeviceWidgetState extends State<FindDevicesWidget> {
  @override
  void initState() {
    super.initState();
    context.read<BluetoothPrinterProvider>().startScan(timeout: null);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.all(12),
      content: FractionallySizedBox(
        heightFactor: 0.7,
        child: SingleChildScrollView(
          child: Column(
            children: [
              FutureBuilder(
                future: _displayConnectedDevicesList(),
                builder: (context, snapshot) => snapshot.data ?? const SizedBox(),
              ),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "อุปกรณ์ที่ค้นพบใหม่",
                  textAlign: TextAlign.start,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              _displayDiscoveredDevicesList(),
            ],
          ),
        ),
      ),
    );
  }

  Future<Widget> _displayConnectedDevicesList() async {
    BluetoothPrinterProvider pvd = context.watch<BluetoothPrinterProvider>();
    List<BluetoothDevice> devices = pvd.connectedDevices;
    BluetoothDevice? selectedPrinter = await pvd.selectedPrinter;

    List<Widget> list = [
      devices.isEmpty
          ? const SizedBox()
          : const SizedBox(
              width: double.infinity,
              child: Text(
                "อุปกรณ์ที่เชื่อมต่อในขณะนี้",
                textAlign: TextAlign.start,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
      ...devices.map((device) {
        if (device.platformName.isEmpty) return const SizedBox();
        bool isDeviceUsing = selectedPrinter != null && device.remoteId.str == selectedPrinter.remoteId.str;
        return Container(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                flex: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(device.platformName),
                    Text(device.remoteId.str),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    isDeviceUsing
                        ? InkWell(
                            onTap: () async {
                              await pvd.stopCommunication();
                            },
                            child: Container(
                                padding: const EdgeInsets.all(10),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  "หยุดใช้งานเครื่อง",
                                  textAlign: TextAlign.center,
                                )),
                          )
                        : InkWell(
                            onTap: () async {
                              await pvd.startCommunication(device);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                "เริ่มใช้งานเครื่อง",
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () async {
                        await pvd.disconnect(device);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "ตัดการเชื่อมต่อ",
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    ];

    return Column(
      children: list,
    );
  }

  Widget _displayDiscoveredDevicesList() {
    BluetoothPrinterProvider pvd = context.watch<BluetoothPrinterProvider>();
    List<ScanResult> scanResult = pvd.scanResults;
    List<Widget> list = scanResult.map((e) {
      BluetoothDevice device = e.device;
      // check if name not empty;
      if (device.platformName.isEmpty) return const SizedBox();
      // check if not in connected devices list;
      int existAt = pvd.connectedDevices.indexWhere((element) => device.platformName == element.platformName);
      if (existAt >= 0) return const SizedBox();
      return ListTile(
        onTap: () {
          pvd.toggleConnect(device);
        },
        title: Text(device.platformName),
        subtitle: Text(device.remoteId.str),
      );
    }).toList();
    return Column(children: list);
  }
}
