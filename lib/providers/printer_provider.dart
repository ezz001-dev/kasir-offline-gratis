import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/services.dart';

class PrinterProvider with ChangeNotifier {
  final BlueThermalPrinter _bluetooth = BlueThermalPrinter.instance;

  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  bool _isConnected = false;
  bool _isLoading = false;

  List<BluetoothDevice> get devices => _devices;
  BluetoothDevice? get selectedDevice => _selectedDevice;
  bool get isConnected => _isConnected;
  bool get isLoading => _isLoading;

  PrinterProvider() {
    _init();
  }

  // Cek status koneksi saat inisialisasi
  void _init() {
    _bluetooth.isConnected.then((isConnected) {
      if (isConnected == true) {
        _isConnected = true;
        notifyListeners();
      }
    });
  }

  // 1. Scan Perangkat Bluetooth
  Future<void> scanDevices() async {
    _isLoading = true;
    notifyListeners();

    try {
      List<BluetoothDevice> devices = await _bluetooth.getBondedDevices();
      _devices = devices;
    } on PlatformException catch (e) {
      debugPrint("Error scan devices: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 2. Koneksi ke Printer
  Future<void> connect(BluetoothDevice device) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_selectedDevice != null && _selectedDevice != device) {
        await _bluetooth.disconnect();
      }

      await _bluetooth.connect(device);
      _selectedDevice = device;
      _isConnected = true;
    } on PlatformException catch (e) {
      debugPrint("Error connect: $e");
      _isConnected = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 3. Putus Koneksi
  Future<void> disconnect() async {
    await _bluetooth.disconnect();
    _isConnected = false;
    _selectedDevice = null;
    notifyListeners();
  }

  // 4. Fungsi Print Generic (Menerima List Bytes)
  Future<void> printBytes(List<int> bytes) async {
    if (!_isConnected) return;
    try {
      await _bluetooth.writeBytes(Uint8List.fromList(bytes));
    } catch (e) {
      debugPrint("Print Error: $e");
    }
  }

  // Cek apakah bluetooth HP nyala
  Future<bool> get isBluetoothOn async {
    return (await _bluetooth.isOn) ?? false;
  }
}
