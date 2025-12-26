class Customer {
  final int? id;
  final String name;
  final String? phone;
  final String? address;

  Customer({this.id, required this.name, this.phone, this.address});

  factory Customer.fromMap(Map<String, dynamic> json) => Customer(
    id: json['id'],
    name: json['name'],
    phone: json['phone'],
    address: json['address'],
  );

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'phone': phone, 'address': address};
  }
}
