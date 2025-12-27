import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  String _shopName = "TOKO UMKM BERKAH";
  String _shopAddress = "Jl. Merdeka No. 45, Indonesia";
  String _shopPhone = "0812-3456-7890";
  bool _isLoading = true;

  String get shopName => _shopName;
  String get shopAddress => _shopAddress;
  String get shopPhone => _shopPhone;
  bool get isLoading => _isLoading;

  SettingsProvider() {
    loadSettings();
  }

  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    _shopName = prefs.getString('shop_name') ?? "TOKO UMKM BERKAH";
    _shopAddress =
        prefs.getString('shop_address') ?? "Jl. Merdeka No. 45, Indonesia";
    _shopPhone = prefs.getString('shop_phone') ?? "0812-3456-7890";

    _isLoading = false;
    notifyListeners();
  }

  Future<void> saveSettings(String name, String address, String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('shop_name', name);
    await prefs.setString('shop_address', address);
    await prefs.setString('shop_phone', phone);

    _shopName = name;
    _shopAddress = address;
    _shopPhone = phone;

    notifyListeners();
  }
}
