import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // 1. Tambahkan Import ini
import '../database/db_helper.dart';
import '../models/transaction_model.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  bool _isLoading = true;

  // Data Summary
  int _todayRevenue = 0;
  int _totalTransactions = 0;
  List<TransactionModel> _recentTransactions = [];

  // Data Grafik (7 Hari Terakhir)
  List<BarChartGroupData> _weeklyChartData = [];
  double _maxChartValue = 0;

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    // 2. Tambahkan baris ini untuk inisialisasi format tanggal Indonesia
    await initializeDateFormatting('id_ID', null);

    setState(() => _isLoading = true);

    try {
      final db = await DatabaseHelper.instance.database;
      final now = DateTime.now();
      final todayStr = DateFormat('yyyy-MM-dd').format(now);

      // 1. Hitung Omset Hari Ini (Hanya yang LUNAS atau DP, Piutang tidak dihitung omset cash)
      final todayResult = await db.rawQuery('''
        SELECT SUM(amount_paid) as total 
        FROM transactions 
        WHERE date(transaction_date) LIKE '$todayStr%'
      ''');
      _todayRevenue = (todayResult.first['total'] as int?) ?? 0;

      // 2. Ambil 10 Transaksi Terakhir
      final recentResult = await db.query(
        'transactions',
        orderBy: 'transaction_date DESC',
        limit: 10,
      );
      _recentTransactions = recentResult
          .map((json) => TransactionModel.fromMap(json))
          .toList();

      // 3. Siapkan Data Grafik (7 Hari ke belakang)
      List<BarChartGroupData> chartGroups = [];
      double maxVal = 0;

      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dateStr = DateFormat('yyyy-MM-dd').format(date);

        // Query pendapatan per hari
        final dayResult = await db.rawQuery('''
          SELECT SUM(amount_paid) as total 
          FROM transactions 
          WHERE date(transaction_date) LIKE '$dateStr%'
        ''');

        final total = (dayResult.first['total'] as int?) ?? 0;
        if (total > maxVal) maxVal = total.toDouble();

        chartGroups.add(
          BarChartGroupData(
            x: 6 - i,
            barRods: [
              BarChartRodData(
                toY: total.toDouble(),
                color: Colors.blue,
                width: 16,
                borderRadius: BorderRadius.circular(4),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY:
                      (maxVal == 0 ? 1000 : maxVal) *
                      1.2, // Safety check biar tidak error division by zero
                  color: Colors.grey.shade100,
                ),
              ),
            ],
          ),
        );
      }

      if (mounted) {
        setState(() {
          _weeklyChartData = chartGroups;
          _maxChartValue = maxVal == 0 ? 1000 : maxVal * 1.2;
          _totalTransactions = _recentTransactions.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading report: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Laporan Penjualan")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- CARD RINGKASAN ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade700, Colors.blue.shade500],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Pendapatan Hari Ini",
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _currencyFormat.format(_todayRevenue),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Cash Flow masuk (termasuk DP)",
                          style: TextStyle(color: Colors.white30, fontSize: 10),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- GRAFIK MINGGUAN ---
                  const Text(
                    "Grafik 7 Hari Terakhir",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: _maxChartValue,
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              return BarTooltipItem(
                                _currencyFormat.format(rod.toY),
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                // Logic label hari
                                final now = DateTime.now();
                                final date = now.subtract(
                                  Duration(days: 6 - value.toInt()),
                                );
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    DateFormat('E', 'id_ID').format(date),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        gridData: const FlGridData(show: false),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- LIST TRANSAKSI TERAKHIR ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Riwayat Terbaru",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Tombol Lihat Semua bisa diimplementasikan nanti
                    ],
                  ),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _recentTransactions.length,
                    itemBuilder: (context, index) {
                      final trans = _recentTransactions[index];
                      final date = DateTime.parse(trans.transactionDate);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: trans.isDebt
                                ? Colors.orange.shade50
                                : Colors.green.shade50,
                            child: Icon(
                              trans.isDebt ? Icons.access_time : Icons.check,
                              color: trans.isDebt
                                  ? Colors.orange
                                  : Colors.green,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            _currencyFormat.format(trans.totalAmount),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            DateFormat(
                              'dd MMM yyyy, HH:mm',
                              'id_ID',
                            ).format(date),
                          ),
                          trailing: trans.isDebt
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text(
                                      "KASBON",
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.orange,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      "Sisa: ${_currencyFormat.format(trans.debtAmount)}",
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  ],
                                )
                              : const Text(
                                  "LUNAS",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
