import 'package:flutter/material.dart';
import '../models/customer_model.dart';
import '../models/transaction_model.dart';
import '../database/db_helper.dart';

class CustomerProvider with ChangeNotifier {
  List<Customer> _customers = [];
  List<TransactionModel> _debtTransactions = [];
  bool _isLoading = false;

  List<Customer> get customers => _customers;
  List<TransactionModel> get debtTransactions => _debtTransactions;
  bool get isLoading => _isLoading;

  // --- CUSTOMER CRUD ---
  Future<void> getCustomers() async {
    _isLoading = true;
    notifyListeners();
    try {
      _customers = await DatabaseHelper.instance.readAllCustomers();
    } catch (e) {
      debugPrint("Error loading customers: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addCustomer(Customer customer) async {
    await DatabaseHelper.instance.createCustomer(customer);
    await getCustomers();
  }

  // --- DEBT LOGIC ---

  Future<void> getDebtTransactions() async {
    _isLoading = true;
    notifyListeners();

    final db = await DatabaseHelper.instance.database;
    // Ambil transaksi yang belum lunas
    final result = await db.rawQuery('''
      SELECT t.*, c.name as customer_name 
      FROM transactions t
      LEFT JOIN customers c ON t.customer_id = c.id
      WHERE t.is_debt = 1 AND t.debt_amount > 0
      ORDER BY t.transaction_date DESC
    ''');

    _debtTransactions = result
        .map((json) => TransactionModel.fromMap(json))
        .toList();
    _isLoading = false;
    notifyListeners();
  }

  // Ambil history pembayaran per transaksi
  Future<List<DebtHistoryModel>> getTransactionHistory(
    int transactionId,
  ) async {
    final data = await DatabaseHelper.instance.getDebtHistory(transactionId);
    return data.map((json) => DebtHistoryModel.fromMap(json)).toList();
  }

  // Proses Bayar Cicilan
  Future<void> repayDebt(int transactionId, int amountPay) async {
    final db = await DatabaseHelper.instance.database;

    // Gunakan Transaction agar atomik (Update + Insert History)
    await db.transaction((txn) async {
      // 1. Ambil data saat ini
      final result = await txn.query(
        'transactions',
        where: 'id = ?',
        whereArgs: [transactionId],
      );
      if (result.isEmpty) return;

      final currentTrans = TransactionModel.fromMap(result.first);

      // 2. Hitung nilai baru
      int newPaid = currentTrans.amountPaid + amountPay;
      int newDebt = currentTrans.debtAmount - amountPay;
      if (newDebt < 0) newDebt = 0;

      // 3. Update Tabel Transaksi
      await txn.update(
        'transactions',
        {'amount_paid': newPaid, 'debt_amount': newDebt},
        where: 'id = ?',
        whereArgs: [transactionId],
      );

      // 4. Catat ke Tabel Histori
      await txn.insert('debt_history', {
        'transaction_id': transactionId,
        'date': DateTime.now().toIso8601String(),
        'amount_paid': amountPay,
      });
    });

    await getDebtTransactions(); // Refresh list utang
  }
}
