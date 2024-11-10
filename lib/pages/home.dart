import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_printer_demo/library/bluetooth_printer_x/bluetooth.printer.x.provider.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // BluetoothPrinterProvider pvd = context.watch<BluetoothPrinterProvider>();
    BluetoothPrinterXProvider pvd = context.watch<BluetoothPrinterXProvider>();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () async {
                await pvd.showScanDeviceDialog(context);
              },
              child: const Text("Settings"),
            ),
            pvd.isConnected
                ? ElevatedButton(
                    onPressed: () async {
                      int bw = 2; //border width
                      int padding = 10; //border width

                      List<String> tslpCommands = [
                        "SIZE 76 mm, 100 mm",
                        "GAP 2 mm",
                        "CLS",
                        "CODEPAGE 857",
                        "BAR 0, $padding, 575, 400",
                        "ERASE $bw, ${padding + bw}, 200, 200", // bar code box
                        "ERASE ${bw + 200 + bw}, ${padding + bw}, 300, 52", // item label box
                        "ERASE ${bw + 200 + bw + 300 + bw}, ${padding + bw}, 67, 52 ", // some number box
                        "ERASE ${bw + 200 + bw}, ${padding + bw + 52 + bw}, 369, 45", // case mask box
                        "ERASE ${bw + 200 + bw}, ${padding + bw + 52 + bw + 45 + bw}, 369, 45", // case no. box
                        "ERASE ${bw + 200 + bw}, ${padding + bw + 52 + bw + 45 + bw + 45 + bw}, 369, 52", // receive date box
                        "ERASE $bw, ${padding + bw + 200 + bw}, 571, 72", // item no. box
                        "ERASE $bw, ${padding + bw + 200 + bw + 72 + bw}, 571, 60", // item name box
                        "ERASE $bw, ${padding + bw + 200 + bw + 72 + bw + 60 + bw}, 502, 58", // qty/package box
                        "ERASE ${bw + 200 + bw + 300 + bw}, ${padding + bw + 200 + bw + 72 + bw + 60 + bw}, 67, 58", // qty/package box
                        // "BARCODE ${bw + 20}, ${bw + 20}, \"128\", 160, 1, 0, 1, 1, \"test\"",
                        // "BITMAP 200,200,2,16,0, -????? ",
                        "TEXT ${bw + 200 + bw + 5}, ${padding + bw + 20}, \"3\", 0, 1, 1, \"Item Label\" ",
                        "TEXT ${bw + 200 + bw + 300 + bw + 15}, ${padding + bw + 30}, \"1\", 0, 1, 1, \"0\" ",
                        "TEXT ${bw + 200 + bw + 5}, ${padding + bw + 52 + bw + 25}, \"1\", 0, 1, 1, \"Case Mark : BF05E1\" ",
                        "TEXT ${bw + 200 + bw + 5}, ${padding + bw + 52 + bw + 45 + bw + 25}, \"1\", 0, 1, 1, \"Case No. : 001005\" ",
                        "TEXT ${bw + 200 + bw + 5}, ${padding + bw + 52 + bw + 45 + bw + 45 + bw + 10}, \"1\", 0, 1, 1, \"Receive Date : 15/07/2024\" ",
                        "TEXT ${bw + 20}, ${padding + bw + 200 + bw + 50}, \"1\", 0, 1, 1, \"Item No:\" ",
                        "TEXT ${bw + 20 + 80}, ${padding + bw + 200 + bw + 32}, \"4\", 0, 1, 1, \"16S-F5120-10-WN-80\" ",
                        "TEXT ${bw + 20}, ${padding + bw + 200 + bw + 72 + bw + 30}, \"1\", 0, 1, 1, \"Item Name:\" ",
                        "TEXT ${bw + 20 + 105}, ${padding + bw + 200 + bw + 72 + bw + 20}, \"3\", 0, 1, 1, \"PLATE ASSY.\" ",
                        "TEXT ${bw + 20}, ${padding + bw + 200 + bw + 72 + bw + 60 + bw + 30}, \"1\", 0, 1, 1, \"Qty/Package : 16\" ",

                        "TEXT ${bw + 200 + bw + 300 + bw + 15}, ${padding + bw + 200 + bw + 72 + bw + 60 + bw + 20}, \"1\", 0, 1, 1, \"Re.\" ",
                        "PRINT 1, 1",
                      ];
                      List<int> data = await pvd.getByteFromTSPL(tslpCommands);
                      if (!context.mounted) return;
                      await pvd.printReceipt(context, data: data);
                    },
                    child: const Text("Test print"),
                  )
                : const SizedBox(),

            // ElevatedButton(
            //   onPressed: () async {
            //     await pvd.showSetting(context);
            //   },
            //   child: const Text("Settings"),
            // ),
            // StreamBuilder<bool>(
            //   stream: pvd.isCommunicating.asStream(),
            //   builder: (context, snapshot) {
            //     if (snapshot.hasData) {
            //       bool isCommunicating = snapshot.data ?? false;
            //       if (isCommunicating) {
            //         return ElevatedButton(
            //           onPressed: () async {
            //             List<int> data = await pvd.receipt(
            //               context,
            //               title: "title",
            //               name: "name",
            //               serviceCode: "001",
            //               queueBefore: 0,
            //             );
            //             if (!context.mounted) return;
            //             await pvd.printReceipt(context, data: data);
            //           },
            //           child: const Text("Test print"),
            //         );
            //       } else {
            //         return const SizedBox();
            //       }
            //     } else if (snapshot.hasError) {
            //       return Center(child: Text("${snapshot.error}"));
            //     } else {
            //       return const Center(child: CircularProgressIndicator());
            //     }
            //   },
            // ),
          ],
        ),
      ),
    );
  }
}
