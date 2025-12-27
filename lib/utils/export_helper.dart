import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../database/db_helper.dart';

class ExportHelper {
  static Future<void> exportTransactionReport() async {
    final db = await DatabaseHelper.instance.database;

    // 1. Ambil Data Transaksi Full dengan Nama Customer
    final result = await db.rawQuery('''
      SELECT t.*, c.name as customer_name 
      FROM transactions t
      LEFT JOIN customers c ON t.customer_id = c.id
      ORDER BY t.transaction_date DESC
    ''');

    final transactions = result
        .map((json) => TransactionModel.fromMap(json))
        .toList();

    // 2. Siapkan Header CSV
    List<List<dynamic>> rows = [];
    rows.add([
      "ID Transaksi",
      "Tanggal",
      "Jam",
      "Metode Pembayaran",
      "Pelanggan",
      "Total Belanja",
      "Status",
      "Sisa Utang",
    ]);

    // 3. Isi Data
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: '',
      decimalDigits: 0,
    );

    for (var t in transactions) {
      final dt = DateTime.parse(t.transactionDate);
      rows.add([
        t.id,
        DateFormat('dd/MM/yyyy').format(dt),
        DateFormat('HH:mm').format(dt),
        t.paymentMethod,
        t.customerName ?? "Umum",
        currencyFormat.format(t.totalAmount),
        t.isDebt ? "KASBON" : "LUNAS",
        t.isDebt ? currencyFormat.format(t.debtAmount) : "0",
      ]);
    }

    // 4. Konversi ke String CSV
    String csvData = const ListToCsvConverter().convert(rows);

    // 5. Simpan ke File Temporary
    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        "Laporan_Penjualan_${DateFormat('ddMMyyyy_HHmm').format(DateTime.now())}.csv";
    final path = "${directory.path}/$fileName";

    final file = File(path);
    await file.writeAsString(csvData);

    // 6. Share File (Solusi Export Paling Aman di Android Terbaru)
    // User bisa pilih mau simpan ke Drive, kirim WA, atau Email
    await Share.shareXFiles([XFile(path)], text: 'Laporan Penjualan Toko');
  }
}
