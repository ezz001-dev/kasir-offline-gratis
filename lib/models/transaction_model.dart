class TransactionModel {
  final int? id;
  final int totalAmount;
  final int discount;
  final int tax;
  final String paymentMethod; // 'CASH', 'QRIS', 'DEBT'
  final String transactionDate;

  // Fitur Piutang & Pelanggan
  final int? customerId;
  final bool isDebt; // 1 = Utang, 0 = Lunas
  final int amountPaid; // Jumlah yang dibayarkan saat itu
  final int debtAmount; // Sisa utang
  final String? dueDate; // Tanggal jatuh tempo (jika ada)

  TransactionModel({
    this.id,
    required this.totalAmount,
    this.discount = 0,
    this.tax = 0,
    required this.paymentMethod,
    required this.transactionDate,
    this.customerId,
    this.isDebt = false,
    required this.amountPaid,
    this.debtAmount = 0,
    this.dueDate,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> json) =>
      TransactionModel(
        id: json['id'],
        totalAmount: json['total_amount'],
        discount: json['discount'] ?? 0,
        tax: json['tax'] ?? 0,
        paymentMethod: json['payment_method'],
        transactionDate: json['transaction_date'],
        customerId: json['customer_id'],
        isDebt: json['is_debt'] == 1, // SQLite menyimpan bool sebagai 0/1
        amountPaid: json['amount_paid'] ?? 0,
        debtAmount: json['debt_amount'] ?? 0,
        dueDate: json['due_date'],
      );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'total_amount': totalAmount,
      'discount': discount,
      'tax': tax,
      'payment_method': paymentMethod,
      'transaction_date': transactionDate,
      'customer_id': customerId,
      'is_debt': isDebt ? 1 : 0,
      'amount_paid': amountPaid,
      'debt_amount': debtAmount,
      'due_date': dueDate,
    };
  }
}

class TransactionItem {
  final int? id;
  final int? transactionId;
  final int productId;
  final int quantity;
  final int
  price; // Harga saat transaksi terjadi (penting jika harga produk berubah nanti)
  final int subtotal;

  TransactionItem({
    this.id,
    this.transactionId,
    required this.productId,
    required this.quantity,
    required this.price,
    required this.subtotal,
  });

  factory TransactionItem.fromMap(Map<String, dynamic> json) => TransactionItem(
    id: json['id'],
    transactionId: json['transaction_id'],
    productId: json['product_id'],
    quantity: json['quantity'],
    price: json['price'],
    subtotal: json['subtotal'],
  );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transaction_id': transactionId,
      'product_id': productId,
      'quantity': quantity,
      'price': price,
      'subtotal': subtotal,
    };
  }
}
