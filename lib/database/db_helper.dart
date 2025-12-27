import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product_model.dart';
import '../models/customer_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(
      'toko_kasir_v2.db',
    ); // Nama file bisa tetap atau ganti
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // Ubah version menjadi 2
    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  // Logic Upgrade Database (Migrasi)
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Tambahkan kolom image_path jika update dari versi 1
      await db.execute('ALTER TABLE products ADD COLUMN image_path TEXT');
    }
  }

  Future _createDB(Database db, int version) async {
    // Tabel Produk (Updated dengan image_path)
    await db.execute('''
    CREATE TABLE products (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      barcode TEXT,
      name TEXT NOT NULL,
      price INTEGER NOT NULL,
      cost_price INTEGER NOT NULL DEFAULT 0,
      stock INTEGER NOT NULL DEFAULT 0,
      image_path TEXT
    )
    ''');

    await db.execute('''
    CREATE TABLE customers (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      phone TEXT,
      address TEXT
    )
    ''');

    await db.execute('''
    CREATE TABLE transactions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      customer_id INTEGER,
      total_amount INTEGER NOT NULL,
      discount INTEGER DEFAULT 0,
      tax INTEGER DEFAULT 0,
      payment_method TEXT NOT NULL,
      transaction_date TEXT NOT NULL,
      is_debt INTEGER DEFAULT 0,
      amount_paid INTEGER DEFAULT 0,
      debt_amount INTEGER DEFAULT 0,
      due_date TEXT,
      FOREIGN KEY (customer_id) REFERENCES customers (id)
    )
    ''');

    await db.execute('''
    CREATE TABLE transaction_items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      transaction_id INTEGER NOT NULL,
      product_id INTEGER NOT NULL,
      quantity INTEGER NOT NULL,
      price INTEGER NOT NULL,
      subtotal INTEGER NOT NULL,
      FOREIGN KEY (transaction_id) REFERENCES transactions (id),
      FOREIGN KEY (product_id) REFERENCES products (id)
    )
    ''');
  }

  // --- CRUD OPERATIONS (Biarkan sama, hanya pastikan Model Product sudah terupdate) ---

  Future<int> createProduct(Product product) async {
    final db = await instance.database;
    return await db.insert('products', product.toMap());
  }

  Future<List<Product>> readProducts({int limit = 20, int offset = 0}) async {
    final db = await instance.database;
    final result = await db.query(
      'products',
      orderBy: 'name ASC',
      limit: limit,
      offset: offset,
    );
    return result.map((json) => Product.fromMap(json)).toList();
  }

  Future<List<Product>> searchProducts(String query) async {
    final db = await instance.database;
    final result = await db.query(
      'products',
      where: 'name LIKE ? OR barcode = ?',
      whereArgs: ['%$query%', query],
    );
    return result.map((json) => Product.fromMap(json)).toList();
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    final db = await instance.database;
    final result = await db.query(
      'products',
      where: 'barcode = ?',
      whereArgs: [barcode],
    );
    if (result.isNotEmpty) return Product.fromMap(result.first);
    return null;
  }

  Future<int> updateProduct(Product product) async {
    final db = await instance.database;
    return db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await instance.database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // --- Customer CRUD (Tetap sama) ---
  Future<int> createCustomer(Customer customer) async {
    final db = await instance.database;
    return await db.insert('customers', customer.toMap());
  }

  Future<List<Customer>> readAllCustomers() async {
    final db = await instance.database;
    final result = await db.query('customers', orderBy: 'name ASC');
    return result.map((json) => Customer.fromMap(json)).toList();
  }
}
