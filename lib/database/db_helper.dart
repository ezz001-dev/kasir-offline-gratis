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
    _database = await _initDB('toko_kasir_v2.db'); // Nama file sama, versi naik
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // Update versi ke 3
    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE products ADD COLUMN image_path TEXT');
    }
    if (oldVersion < 3) {
      // Migrasi Versi 3: Buat tabel debt_history
      await db.execute('''
      CREATE TABLE debt_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        amount_paid INTEGER NOT NULL,
        FOREIGN KEY (transaction_id) REFERENCES transactions (id)
      )
      ''');
    }
  }

  Future _createDB(Database db, int version) async {
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

    // Tabel baru untuk V3
    await db.execute('''
    CREATE TABLE debt_history (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      transaction_id INTEGER NOT NULL,
      date TEXT NOT NULL,
      amount_paid INTEGER NOT NULL,
      FOREIGN KEY (transaction_id) REFERENCES transactions (id)
    )
    ''');
  }

  // --- METHODS UNTUK DEBT HISTORY ---

  Future<int> addDebtHistory(int transactionId, int amount, String date) async {
    final db = await instance.database;
    return await db.insert('debt_history', {
      'transaction_id': transactionId,
      'date': date,
      'amount_paid': amount,
    });
  }

  Future<List<Map<String, dynamic>>> getDebtHistory(int transactionId) async {
    final db = await instance.database;
    return await db.query(
      'debt_history',
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
      orderBy: 'date DESC',
    );
  }

  // ... (Sisa method CRUD lainnya biarkan sama seperti sebelumnya) ...
  // Paste ulang method createProduct, readProducts, dll disini jika Anda copy-paste full file.
  // Untuk menghemat ruang, saya asumsikan bagian bawah file ini sama dengan versi sebelumnya.

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

  Future<int> createCustomer(Customer customer) async {
    final db = await instance.database;
    return await db.insert('customers', customer.toMap());
  }

  Future<List<Customer>> readAllCustomers() async {
    final db = await instance.database;
    final result = await db.query('customers', orderBy: 'name ASC');
    return result.map((json) => Customer.fromMap(json)).toList();
  }

  // 1. Dapatkan Path Database
  Future<String> get dbPath async {
    final path = await getDatabasesPath();
    return join(path, 'toko_kasir_v2.db');
  }

  // 2. Tutup Koneksi (Wajib dipanggil sebelum Restore)
  Future<void> close() async {
    final db = await instance.database;
    db.close();
    _database = null;
  }
}
