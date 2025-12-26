import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/product_model.dart';

class ProductProvider with ChangeNotifier {
  List<Product> _products = [];
  bool _isLoading = false;
  bool _hasMore = true; // Untuk cek apakah masih ada data di halaman berikutnya
  int _page = 1;
  final int _limit = 20; // Load 20 produk per scroll

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;

  // Load produk awal atau refresh
  Future<void> getProducts({bool isRefresh = false}) async {
    if (isRefresh) {
      _page = 1;
      _hasMore = true;
      _products.clear();
    }

    if (!_hasMore) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Hitung offset berdasarkan halaman saat ini
      final offset = (_page - 1) * _limit;
      final newProducts = await DatabaseHelper.instance.readProducts(
        limit: _limit,
        offset: offset,
      );

      if (newProducts.length < _limit) {
        _hasMore = false; // Data habis
      }

      _products.addAll(newProducts);
      _page++;
    } catch (e) {
      debugPrint("Error loading products: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cari produk (Search)
  Future<void> searchProduct(String query) async {
    _isLoading = true;
    notifyListeners();

    if (query.isEmpty) {
      await getProducts(isRefresh: true); // Reset ke list awal
    } else {
      _products = await DatabaseHelper.instance.searchProducts(query);
      _hasMore = false; // Disable pagination saat search mode
    }

    _isLoading = false;
    notifyListeners();
  }

  // Tambah Produk Baru
  Future<void> addProduct(Product product) async {
    await DatabaseHelper.instance.createProduct(product);
    await getProducts(isRefresh: true); // Refresh list dari awal
  }

  // Update Produk
  Future<void> editProduct(Product product) async {
    await DatabaseHelper.instance.updateProduct(product);

    // Update data di memory list tanpa refresh database agar lebih cepat
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      _products[index] = product;
      notifyListeners();
    }
  }

  // Hapus Produk
  Future<void> deleteProduct(int id) async {
    await DatabaseHelper.instance.deleteProduct(id);
    _products.removeWhere((p) => p.id == id);
    notifyListeners();
  }
}
