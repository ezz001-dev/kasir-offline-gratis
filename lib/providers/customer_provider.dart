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

  // --- DEBT / PIUTANG LOGIC ---

  // Ambil semua transaksi yang statusnya 'Utang' (is_debt=1) dan belum lunas (debt_amount > 0)
  Future<void> getDebtTransactions() async {
    _isLoading = true;
    notifyListeners();

    final db = await DatabaseHelper.instance.database;
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

  // Proses Pelunasan (Cicil atau Lunas)
  Future<void> repayDebt(int transactionId, int amountPay) async {
    final db = await DatabaseHelper.instance.database;

    // Ambil data transaksi saat ini
    final result = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [transactionId],
    );
    if (result.isEmpty) return;

    final currentTrans = TransactionModel.fromMap(result.first);

    // Hitung sisa utang baru
    int newPaid = currentTrans.amountPaid + amountPay;
    int newDebt = currentTrans.debtAmount - amountPay;

    // Update Database
    await db.update(
      'transactions',
      {
        'amount_paid': newPaid,
        'debt_amount': newDebt < 0 ? 0 : newDebt, // Prevent negative
      },
      where: 'id = ?',
      whereArgs: [transactionId],
    );

    await getDebtTransactions(); // Refresh list utang
  }
}
