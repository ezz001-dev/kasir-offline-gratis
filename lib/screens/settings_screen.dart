import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/printer_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Cek koneksi dulu, lalu scan
      final printer = Provider.of<PrinterProvider>(context, listen: false);
      printer.checkConnection();
      printer.scanDevices();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pengaturan Printer")),
      body: Consumer<PrinterProvider>(
        builder: (context, printer, child) {
          return Column(
            children: [
              // Header Status
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.blue.shade50,
                child: Row(
                  children: [
                    Icon(
                      printer.isConnected ? Icons.print : Icons.print_disabled,
                      color: printer.isConnected ? Colors.green : Colors.grey,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          printer.isConnected
                              ? "Printer Terhubung"
                              : "Printer belum terhubung",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (printer.isConnected)
                          Text(
                            "MAC: ${printer.connectedMacAddress ?? '-'}",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                            ),
                          ),
                      ],
                    ),
                    const Spacer(),
                    if (printer.isConnected)
                      TextButton(
                        onPressed: () => printer.disconnect(),
                        child: const Text(
                          "Putus",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Tombol Scan
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Daftar Perangkat Paired",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (printer.isLoading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: () => printer.scanDevices(),
                        icon: const Icon(Icons.refresh),
                        label: const Text("Scan Ulang"),
                      ),
                  ],
                ),
              ),

              // List Perangkat
              Expanded(
                child: printer.devices.isEmpty
                    ? const Center(
                        child: Text(
                          "Tidak ada perangkat bluetooth tersimpan.\nPastikan Anda sudah pairing di setting HP.",
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        itemCount: printer.devices.length,
                        itemBuilder: (context, index) {
                          final device = printer.devices[index];
                          final isConnected =
                              printer.connectedMacAddress == device.macAdress;

                          return ListTile(
                            leading: const Icon(Icons.bluetooth),
                            title: Text(device.name),
                            subtitle: Text(device.macAdress),
                            trailing: isConnected
                                ? const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  )
                                : ElevatedButton(
                                    onPressed: () =>
                                        printer.connect(device.macAdress),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue.shade50,
                                      foregroundColor: Colors.blue,
                                    ),
                                    child: const Text("Sambung"),
                                  ),
                            onTap: () => printer.connect(device.macAdress),
                          );
                        },
                      ),
              ),

              // Tombol Test Print
              if (printer.isConnected)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        // Test Print
                        printer.printBytes([
                          0x1B, 0x40, // Init
                          ...("TEST PRINT OK\n\n\n".codeUnits),
                        ]);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.grey.shade800,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.receipt),
                      label: const Text("Tes Print Struk"),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
