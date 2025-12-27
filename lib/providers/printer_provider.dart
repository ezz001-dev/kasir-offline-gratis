import 'package:flutter/material.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:flutter/services.dart';

class PrinterProvider with ChangeNotifier {
  // Menggunakan library print_bluetooth_thermal
  List<BluetoothInfo> _devices = [];
  String? _connectedMacAddress; // Kita simpan MAC Address untuk cek status
  bool _isConnected = false;
  bool _isLoading = false;

  // Getter
  List<BluetoothInfo> get devices => _devices;
  bool get isConnected => _isConnected;
  bool get isLoading => _isLoading;
  String? get connectedMacAddress => _connectedMacAddress;

  // 1. Scan Perangkat Bluetooth
  Future<void> scanDevices() async {
    _isLoading = true;
    notifyListeners();

    try {
      final List<BluetoothInfo> result =
          await PrintBluetoothThermal.pairedBluetooths;
      _devices = result;
    } catch (e) {
      debugPrint("Error scan devices: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 2. Koneksi ke Printer
  Future<void> connect(String macAddress) async {
    _isLoading = true;
    notifyListeners();

    try {
      final bool result = await PrintBluetoothThermal.connect(
        macPrinterAddress: macAddress,
      );
      _isConnected = result;
      if (result) {
        _connectedMacAddress = macAddress;
      }
    } catch (e) {
      debugPrint("Error connect: $e");
      _isConnected = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 3. Putus Koneksi
  Future<void> disconnect() async {
    await PrintBluetoothThermal.disconnect;
    _isConnected = false;
    _connectedMacAddress = null;
    notifyListeners();
  }

  // 4. Fungsi Print Generic (Menerima List Bytes)
  Future<void> printBytes(List<int> bytes) async {
    if (!_isConnected) return;
    try {
      await PrintBluetoothThermal.writeBytes(bytes);
    } catch (e) {
      debugPrint("Print Error: $e");
    }
  }

  // Cek Status Koneksi (Refresh)
  Future<void> checkConnection() async {
    _isConnected = await PrintBluetoothThermal.connectionStatus;
    notifyListeners();
  }
}
