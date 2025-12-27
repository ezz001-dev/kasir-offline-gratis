class TransactionModel {
  final int? id;
  final int totalAmount;
  final int discount;
  final int tax;
  final String paymentMethod;
  final String transactionDate;

  // Data Pelanggan & Utang
  final int? customerId;
  final String? customerName; // <--- FIELD BARU (Hasil Join)
  final bool isDebt;
  final int amountPaid;
  final int debtAmount;
  final String? dueDate;

  TransactionModel({
    this.id,
    required this.totalAmount,
    this.discount = 0,
    this.tax = 0,
    required this.paymentMethod,
    required this.transactionDate,
    this.customerId,
    this.customerName, // <--- Tambahkan di Constructor
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
        // Mengambil alias 'customer_name' dari query JOIN di CustomerProvider
        customerName: json['customer_name'],
        isDebt: json['is_debt'] == 1,
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
      // customerName tidak perlu disimpan ke tabel transactions,
      // karena dia milik tabel customers
    };
  }
}

class TransactionItem {
  final int? id;
  final int? transactionId;
  final int productId;
  final int quantity;
  final int price;
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

// --- CLASS BARU: DebtHistoryModel ---
class DebtHistoryModel {
  final int? id;
  final int transactionId;
  final String date;
  final int amountPaid;

  DebtHistoryModel({
    this.id,
    required this.transactionId,
    required this.date,
    required this.amountPaid,
  });

  factory DebtHistoryModel.fromMap(Map<String, dynamic> json) =>
      DebtHistoryModel(
        id: json['id'],
        transactionId: json['transaction_id'],
        date: json['date'],
        amountPaid: json['amount_paid'],
      );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transaction_id': transactionId,
      'date': date,
      'amount_paid': amountPaid,
    };
  }
}
