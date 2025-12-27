import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart'; // Untuk Exit App
import '../providers/printer_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/backup_helper.dart'; // Import Backup Helper

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // ... (Controller dan initState biarkan SAMA seperti sebelumnya)
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      _nameController.text = settings.shopName;
      _addressController.text = settings.shopAddress;
      _phoneController.text = settings.shopPhone;

      final printer = Provider.of<PrinterProvider>(context, listen: false);
      printer.checkConnection();
      printer.scanDevices();
    });
  }

  void _saveShopInfo() {
    Provider.of<SettingsProvider>(context, listen: false).saveSettings(
      _nameController.text,
      _addressController.text,
      _phoneController.text,
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Info Toko Disimpan!")));
    FocusScope.of(context).unfocus();
  }

  // Logic Restore UI
  void _performRestore() async {
    bool success = await BackupHelper.restoreBackup(context);
    if (success && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text("Restore Berhasil"),
          content: const Text(
            "Data berhasil dipulihkan.\nSilakan restart aplikasi agar perubahan diterapkan dengan benar.",
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                // Keluar aplikasi (agar user buka ulang dan DB reload fresh)
                SystemNavigator.pop();
              },
              child: const Text("Tutup Aplikasi"),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pengaturan")),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- BAGIAN 1: INFO TOKO ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Identitas Toko",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: "Nama Toko",
                      prefixIcon: Icon(Icons.store),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: "Alamat",
                      prefixIcon: Icon(Icons.location_on),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: "No. Telepon",
                      prefixIcon: Icon(Icons.phone),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveShopInfo,
                      child: const Text("SIMPAN IDENTITAS"),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(thickness: 4, color: Colors.white),

            // --- BAGIAN 2: DATA & KEAMANAN (FITUR BARU) ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Data & Keamanan",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => BackupHelper.createBackup(context),
                          icon: const Icon(Icons.upload_file),
                          label: const Text("Backup Data"),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _performRestore,
                          icon: const Icon(Icons.download),
                          label: const Text("Restore Data"),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            foregroundColor: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "* Backup akan menyimpan Database & Gambar Produk ke dalam satu file ZIP.",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(thickness: 4, color: Colors.white),

            // --- BAGIAN 3: PRINTER (Biarkan SAMA PERSIS dengan sebelumnya) ---
            Consumer<PrinterProvider>(
              builder: (context, printer, child) {
                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.blue.shade50,
                      child: Row(
                        children: [
                          Icon(
                            printer.isConnected
                                ? Icons.print
                                : Icons.print_disabled,
                            color: printer.isConnected
                                ? Colors.green
                                : Colors.grey,
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
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
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
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Perangkat Bluetooth",
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
                              label: const Text("Scan"),
                            ),
                        ],
                      ),
                    ),
                    // ... (List Printer code sama seperti sebelumnya)
                    printer.devices.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Center(
                              child: Text(
                                "Tidak ada perangkat bluetooth tersimpan.\nPastikan Anda sudah pairing di setting HP.",
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: printer.devices.length,
                            itemBuilder: (context, index) {
                              final device = printer.devices[index];
                              final isConnected =
                                  printer.connectedMacAddress ==
                                  device.macAdress;
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
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
