import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_printer_demo/library/bluetooth_printer/bluetooth.printer.provider.dart';
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
    BluetoothPrinterProvider pvd = context.watch<BluetoothPrinterProvider>();
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
                await pvd.showSetting(context);
              },
              child: const Text("Settings"),
            ),
            StreamBuilder<bool>(
              stream: pvd.isCommunicating.asStream(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  bool isCommunicating = snapshot.data ?? false;
                  if (isCommunicating) {
                    return ElevatedButton(
                      onPressed: () async {
                        List<int> data = await pvd.receipt(
                          context,
                          title: "title",
                          name: "name",
                          serviceCode: "001",
                          queueBefore: 0,
                        );
                        if (!context.mounted) return;
                        await pvd.printReceipt(context, data: data);
                      },
                      child: const Text("Test print"),
                    );
                  } else {
                    return const SizedBox();
                  }
                } else if (snapshot.hasError) {
                  return Center(child: Text("${snapshot.error}"));
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
