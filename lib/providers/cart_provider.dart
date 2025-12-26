import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../models/transaction_model.dart';
import '../database/db_helper.dart';
import 'package:intl/intl.dart';

// Kita butuh model sederhana untuk item di dalam keranjang
class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  int get subtotal => product.price * quantity;
}

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  // Hitung Total Belanja
  int get totalAmount {
    return _items.fold(0, (sum, item) => sum + item.subtotal);
  }

  // Hitung Total Item
  int get totalItems {
    return _items.fold(0, (sum, item) => sum + item.quantity);
  }

  // Tambah ke Keranjang (by Product Object)
  void addToCart(Product product) {
    // Cek apakah produk sudah ada di keranjang?
    final index = _items.indexWhere((item) => item.product.id == product.id);

    if (index != -1) {
      // Jika ada, tambah quantity
      _items[index].quantity++;
    } else {
      // Jika belum, masukkan baru
      _items.add(CartItem(product: product));
    }
    notifyListeners();
  }

  // Tambah ke Keranjang (by Barcode) - Logic untuk Scanner
  Future<bool> addToCartByBarcode(String barcode) async {
    final product = await DatabaseHelper.instance.getProductByBarcode(barcode);
    if (product != null) {
      addToCart(product);
      return true; // Berhasil ditemukan
    }
    return false; // Produk tidak ada
  }

  // Kurangi Quantity
  void decreaseQty(int index) {
    if (_items[index].quantity > 1) {
      _items[index].quantity--;
    } else {
      // Jika sisa 1 dikurangi, tanya user atau hapus langsung?
      // Di sini kita hapus langsung
      _items.removeAt(index);
    }
    notifyListeners();
  }

  // Tambah Quantity Manual
  void increaseQty(int index) {
    // Opsional: Cek stok database dulu sebelum nambah
    // if (_items[index].quantity < _items[index].product.stock) ...
    _items[index].quantity++;
    notifyListeners();
  }

  // Hapus Item
  void removeItem(int index) {
    _items.removeAt(index);
    notifyListeners();
  }

  // Reset Keranjang
  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  // PROSES CHECKOUT (Simpan ke Database)
  Future<bool> processCheckout({
    required int paymentAmount,
    required String paymentMethod,
    int? customerId,
    bool isDebt = false,
  }) async {
    try {
      final db = await DatabaseHelper.instance.database;

      // Gunakan Transaction agar atomik (semua sukses atau semua gagal)
      await db.transaction((txn) async {
        final date = DateTime.now().toIso8601String();

        // 1. Simpan Header Transaksi
        final transactionId = await txn.insert('transactions', {
          'customer_id': customerId,
          'total_amount': totalAmount,
          'discount': 0, // Nanti dikembangkan
          'tax': 0, // Nanti dikembangkan
          'payment_method': paymentMethod,
          'transaction_date': date,
          'is_debt': isDebt ? 1 : 0,
          'amount_paid': paymentAmount,
          'debt_amount': isDebt ? (totalAmount - paymentAmount) : 0,
        });

        // 2. Simpan Detail Item & Kurangi Stok
        for (var item in _items) {
          await txn.insert('transaction_items', {
            'transaction_id': transactionId,
            'product_id': item.product.id,
            'quantity': item.quantity,
            'price': item.product.price, // Harga saat transaksi
            'subtotal': item.subtotal,
          });

          // Kurangi Stok
          await txn.rawUpdate(
            'UPDATE products SET stock = stock - ? WHERE id = ?',
            [item.quantity, item.product.id],
          );
        }
      });

      clearCart(); // Kosongkan keranjang setelah sukses
      return true;
    } catch (e) {
      debugPrint("Checkout Error: $e");
      return false;
    }
  }
}
