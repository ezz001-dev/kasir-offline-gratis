class Product {
  final int? id;
  final String? barcode;
  final String name;
  final int price;
  final int costPrice;
  final int stock;
  final String? imagePath; // <-- Field Baru

  Product({
    this.id,
    this.barcode,
    required this.name,
    required this.price,
    required this.costPrice,
    required this.stock,
    this.imagePath, // <-- Tambahkan di constructor
  });

  factory Product.fromMap(Map<String, dynamic> json) => Product(
    id: json['id'],
    barcode: json['barcode'],
    name: json['name'],
    price: json['price'],
    costPrice: json['cost_price'] ?? 0,
    stock: json['stock'],
    imagePath: json['image_path'], // <-- Mapping dari DB
  );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'barcode': barcode,
      'name': name,
      'price': price,
      'cost_price': costPrice,
      'stock': stock,
      'image_path': imagePath, // <-- Mapping ke DB
    };
  }
}
