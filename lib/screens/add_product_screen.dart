import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/product_model.dart';
import '../providers/product_provider.dart';
import '../widgets/barcode_scanner_simple.dart';

class AddProductScreen extends StatefulWidget {
  final Product? product;

  const AddProductScreen({super.key, this.product});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _priceController = TextEditingController();
  final _costController = TextEditingController();
  final _stockController = TextEditingController();

  File? _selectedImage; // Menyimpan file gambar yang dipilih sementara

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _barcodeController.text = widget.product!.barcode ?? '';
      _priceController.text = widget.product!.price.toString();
      _costController.text = widget.product!.costPrice.toString();
      _stockController.text = widget.product!.stock.toString();

      // Load gambar existing
      if (widget.product!.imagePath != null) {
        _selectedImage = File(widget.product!.imagePath!);
      }
    }
  }

  // Fungsi Pilih Gambar
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 600,
    ); // Compress size

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // Fungsi Simpan Gambar ke Direktori Aplikasi (Supaya permanen)
  Future<String?> _saveImagePermanent(File imageFile) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = path.basename(imageFile.path);
      final savedImage = await imageFile.copy('${appDir.path}/$fileName');
      return savedImage.path;
    } catch (e) {
      debugPrint("Gagal simpan gambar: $e");
      return null;
    }
  }

  void _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      String? savedImagePath;

      // Logic simpan gambar jika ada perubahan
      if (_selectedImage != null) {
        // Cek apakah gambar baru atau lama
        // Jika path gambar sama dengan yang di DB, tidak perlu save ulang
        if (widget.product?.imagePath != _selectedImage!.path) {
          savedImagePath = await _saveImagePermanent(_selectedImage!);
        } else {
          savedImagePath = _selectedImage!.path;
        }
      }

      final newProduct = Product(
        id: widget.product?.id,
        name: _nameController.text,
        barcode: _barcodeController.text.isEmpty
            ? null
            : _barcodeController.text,
        price: int.parse(_priceController.text),
        costPrice: int.parse(_costController.text),
        stock: int.parse(_stockController.text),
        imagePath: savedImagePath, // Path gambar disimpan di DB
      );

      final provider = Provider.of<ProductProvider>(context, listen: false);

      if (widget.product == null) {
        await provider.addProduct(newProduct);
      } else {
        await provider.editProduct(newProduct);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produk berhasil disimpan')),
        );
      }
    }
  }

  // ... (Scan Barcode & Dispose methods sama seperti sebelumnya)
  Future<void> _scanBarcode() async {
    final scannedCode = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SimpleBarcodeScannerPage()),
    );
    if (scannedCode != null)
      setState(() => _barcodeController.text = scannedCode);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _priceController.dispose();
    _costController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Tambah Produk' : 'Edit Produk'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Image Picker Area ---
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (ctx) => SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.camera_alt),
                            title: const Text('Ambil Foto (Kamera)'),
                            onTap: () {
                              Navigator.pop(ctx);
                              _pickImage(ImageSource.camera);
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.photo_library),
                            title: const Text('Pilih dari Galeri'),
                            onTap: () {
                              Navigator.pop(ctx);
                              _pickImage(ImageSource.gallery);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade400),
                    image: _selectedImage != null
                        ? DecorationImage(
                            image: FileImage(_selectedImage!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _selectedImage == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo,
                              size: 50,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Tambah Foto Produk",
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 20),

              // --- Barcode ---
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _barcodeController,
                      decoration: const InputDecoration(
                        labelText: 'Barcode (Opsional)',
                        prefixIcon: Icon(Icons.qr_code),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _scanBarcode,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Icon(Icons.camera_alt),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Produk',
                  prefixIcon: Icon(Icons.local_offer_outlined),
                ),
                validator: (value) => value!.isEmpty ? 'Wajib isi' : null,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Harga Jual',
                        prefixIcon: Padding(
                          padding: EdgeInsets.all(12),
                          child: Text(
                            "Rp",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      validator: (value) => value!.isEmpty ? 'Wajib isi' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _costController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Harga Modal',
                        prefixIcon: Padding(
                          padding: EdgeInsets.all(12),
                          child: Text(
                            "Rp",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      validator: (value) => value!.isEmpty ? 'Wajib isi' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Stok Awal',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
                validator: (value) => value!.isEmpty ? 'Wajib isi' : null,
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _saveProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'SIMPAN PRODUK',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
