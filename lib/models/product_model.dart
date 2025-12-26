class Product {
  final int? id;
  final String? barcode; // Kode Barcode (bisa null jika produk manual)
  final String name;
  final int price; // Harga Jual
  final int costPrice; // Harga Modal (untuk laporan laba)
  final int stock;

  Product({
    this.id,
    this.barcode,
    required this.name,
    required this.price,
    required this.costPrice,
    required this.stock,
  });

  // Konversi dari Map (Database) ke Object Dart
  factory Product.fromMap(Map<String, dynamic> json) => Product(
    id: json['id'],
    barcode: json['barcode'],
    name: json['name'],
    price: json['price'],
    costPrice: json['cost_price'] ?? 0, // Default 0 jika null
    stock: json['stock'],
  );

  // Konversi dari Object Dart ke Map (untuk disimpan ke Database)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'barcode': barcode,
      'name': name,
      'price': price,
      'cost_price': costPrice,
      'stock': stock,
    };
  }
}
