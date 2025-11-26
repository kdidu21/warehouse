import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vaxiwarehouse/pages/messages.dart';
import 'package:vaxiwarehouse/pages/salesorder.dart';

void main() {
  runApp(const VaxiWarehouseApp());
}

class VaxiWarehouseApp extends StatelessWidget {
  const VaxiWarehouseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Vaxi Warehouse',
      home: MainNavigationPage(),
    );
  }
}

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    ClinicBookingsPage(), // Sales Orders
    MessagesPage(), // Messages
  ];

  String? defaultPrinterAddress; // Store the default printer

  @override
  void initState() {
    super.initState();
    _loadDefaultPrinter();
  }

  
  Future<void> _loadDefaultPrinter() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      defaultPrinterAddress = prefs.getString('default_printer');
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Print helper for default printer
  Future<void> printToDefault(String text) async {
    if (defaultPrinterAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No default printer selected')),
      );
      return;
    }

    const MethodChannel channel = MethodChannel('printer_channel');
    try {
      final bool connected = await channel.invokeMethod(
        'connectPrinter',
        {'address': defaultPrinterAddress},
      );
      if (connected) {
        await channel.invokeMethod('printText', {'text': text});
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Printed successfully!')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to connect')));
      }
    } catch (e) {
      print("Error printing: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: 'Sales Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message_outlined),
            activeIcon: Icon(Icons.message),
            label: 'Messages',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Open Bluetooth Printers Page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>BluetoothPrintersPage(
                onSelectDefaultPrinter: (address) async {
                  setState(() => defaultPrinterAddress = address);
                  SharedPreferences prefs = await SharedPreferences.getInstance();
                  await prefs.setString('default_printer', address);
                },
              ),
            ),
          );
        },
        child: const Icon(Icons.print),
      ),
    );
  }
}

/// -------------------
/// BLUETOOTH PRINTERS PAGE
/// -------------------

class BluetoothPrintersPage extends StatefulWidget {
  final Function(String)? onSelectDefaultPrinter;

  const BluetoothPrintersPage({super.key, this.onSelectDefaultPrinter});

  @override
  State<BluetoothPrintersPage> createState() => _BluetoothPrintersPageState();
}

class _BluetoothPrintersPageState extends State<BluetoothPrintersPage> {
  static const MethodChannel _channel = MethodChannel('printer_channel');

  List<Map<String, String>> devices = [];
  bool isScanning = false;

  Future<void> askPermissions() async {
      await [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.bluetoothAdvertise,
        Permission.locationWhenInUse
      ].request();
    }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await askPermissions();  // THIS WILL NOW RUN
    scanPrinters();          // Now scanning works
  }


  Future<void> scanPrinters() async {
    setState(() => isScanning = true);
    try {
      final List result = await _channel.invokeMethod('scanPrinters');
      final List<Map<String, String>> devicesList = result
          .map<Map<String, String>>((item) {
            final map = Map<Object?, Object?>.from(item);
            return map.map(
              (key, value) => MapEntry(key.toString(), value.toString()),
            );
          })
          .toList();
      setState(() {
        devices = devicesList;
      });
    } catch (e) {
      print("Error scanning: $e");
    }
    setState(() => isScanning = false);
  }

  Future<void> connectAndPrint(String address) async {
    try {
      final bool connected =
          await _channel.invokeMethod('connectPrinter', {'address': address});
      if (connected) {
        await _channel.invokeMethod('printText', {'text': 'Hello from Flutter!'});
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Printed successfully!')));
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Failed to connect')));
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Printers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: isScanning ? null : scanPrinters,
          ),
        ],
      ),
      body: isScanning
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: devices.length,
              itemBuilder: (context, index) {
                final device = devices[index];
                return ListTile(
                  title: Text(device['name'] ?? 'Unknown'),
                  subtitle: Text(device['address'] ?? ''),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        child: const Text('Set Default'),
                        onPressed: () async {
                          widget.onSelectDefaultPrinter?.call(device['address']!);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${device['name']} set as default'),
                            ),
                          );

                        },
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        child: const Text('Print'),
                        onPressed: () => connectAndPrint(device['address']!),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
