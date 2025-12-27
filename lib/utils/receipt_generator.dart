import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../providers/cart_provider.dart';

class ReceiptGenerator {
  static final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static Future<List<int>> generateReceipt(
    TransactionModel transaction,
    List<CartItem> items, {
    String shopName = "TOKO UMKM", // Default
    String address = "-", // Default
    String phone = "-", // Default
  }) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    List<int> bytes = [];

    // --- HEADER DINAMIS ---
    bytes += generator.reset();
    bytes += generator.text(
      shopName,
      styles: const PosStyles(
        align: PosAlign.center,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
        bold: true,
      ),
    );

    if (address.isNotEmpty) {
      bytes += generator.text(
        address,
        styles: const PosStyles(align: PosAlign.center),
      );
    }
    if (phone.isNotEmpty && phone != "-") {
      bytes += generator.text(
        "Telp: $phone",
        styles: const PosStyles(align: PosAlign.center),
      );
    }
    bytes += generator.feed(1);

    bytes += generator.text(
      'Tgl : ${DateFormat('dd-MM-yyyy HH:mm').format(DateTime.parse(transaction.transactionDate))}',
    );
    bytes += generator.text('No  : #${transaction.id}');
    if (transaction.customerName != null) {
      bytes += generator.text('Plgn: ${transaction.customerName}');
    }
    bytes += generator.hr(ch: '-');

    // --- LIST ITEM ---
    for (var item in items) {
      bytes += generator.text(
        item.product.name,
        styles: const PosStyles(bold: true),
      );

      bytes += generator.row([
        PosColumn(
          text:
              '${item.quantity} x ${_currencyFormat.format(item.product.price)}',
          width: 8,
          styles: const PosStyles(align: PosAlign.left),
        ),
        PosColumn(
          text: _currencyFormat.format(item.subtotal),
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }

    bytes += generator.hr(ch: '-');

    // --- TOTAL ---
    bytes += generator.row([
      PosColumn(text: 'Total', width: 6, styles: const PosStyles(bold: true)),
      PosColumn(
        text: _currencyFormat.format(transaction.totalAmount),
        width: 6,
        styles: const PosStyles(
          align: PosAlign.right,
          bold: true,
          height: PosTextSize.size2,
        ),
      ),
    ]);

    // --- PAYMENT INFO ---
    if (transaction.isDebt) {
      bytes += generator.text(
        'Metode: KASBON/HUTANG',
        styles: const PosStyles(align: PosAlign.right),
      );
      bytes += generator.text(
        'Bayar (DP): ${_currencyFormat.format(transaction.amountPaid)}',
        styles: const PosStyles(align: PosAlign.right),
      );
      bytes += generator.text(
        'Sisa Utang: ${_currencyFormat.format(transaction.debtAmount)}',
        styles: const PosStyles(align: PosAlign.right),
      );
    } else {
      bytes += generator.text(
        'Metode: TUNAI',
        styles: const PosStyles(align: PosAlign.right),
      );
      bytes += generator.text(
        'Bayar: ${_currencyFormat.format(transaction.amountPaid)}',
        styles: const PosStyles(align: PosAlign.right),
      );
      int change = transaction.amountPaid - transaction.totalAmount;
      bytes += generator.text(
        'Kembali: ${_currencyFormat.format(change)}',
        styles: const PosStyles(align: PosAlign.right),
      );
    }

    // --- FOOTER ---
    bytes += generator.feed(1);
    bytes += generator.text(
      'Terima Kasih',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.text(
      'Barang yang sudah dibeli',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      'tidak dapat ditukar/dikembalikan',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.feed(2);
    bytes += generator.cut();

    return bytes;
  }
}
