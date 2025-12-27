import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
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
    // Auto scan saat halaman dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PrinterProvider>(context, listen: false).scanDevices();
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
                              ? "Terhubung ke: ${printer.selectedDevice?.name}"
                              : "Printer belum terhubung",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (printer.isConnected)
                          const Text(
                            "Siap mencetak struk",
                            style: TextStyle(fontSize: 12, color: Colors.green),
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

              // Tombol Scan & Loading
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Daftar Perangkat Bluetooth",
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
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.bluetooth_searching,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            const Text("Tidak ada perangkat ditemukan"),
                            TextButton(
                              onPressed: () async {
                                // Cek apakah bluetooth mati
                                if (!await printer.isBluetoothOn) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Mohon nyalakan Bluetooth HP Anda",
                                      ),
                                    ),
                                  );
                                } else {
                                  printer.scanDevices();
                                }
                              },
                              child: const Text("Cek Bluetooth"),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: printer.devices.length,
                        itemBuilder: (context, index) {
                          final device = printer.devices[index];
                          final isSelected =
                              printer.selectedDevice?.address == device.address;

                          return ListTile(
                            leading: const Icon(Icons.print),
                            title: Text(device.name ?? "Unknown Device"),
                            subtitle: Text(device.address ?? "-"),
                            trailing: isSelected
                                ? const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  )
                                : ElevatedButton(
                                    onPressed: () => printer.connect(device),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue.shade50,
                                      foregroundColor: Colors.blue,
                                    ),
                                    child: const Text("Sambung"),
                                  ),
                            onTap: () => printer.connect(device),
                          );
                        },
                      ),
              ),

              // Tombol Test Print (Hanya muncul jika connect)
              if (printer.isConnected)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        // Test Print Sederhana (Manual Byte)
                        // \x1B\x40 = Initialize
                        // \x0A = Line Feed
                        printer.printBytes([
                          0x1B,
                          0x40,
                          ...("TEST PRINT BERHASIL\n".codeUnits),
                          ...("-------------------\n".codeUnits),
                          ...("Cek Printer OK\n\n\n".codeUnits),
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
