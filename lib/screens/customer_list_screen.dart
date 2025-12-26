import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/customer_model.dart';
import '../providers/customer_provider.dart';

class CustomerListScreen extends StatefulWidget {
  final bool
  isPicker; // Jika true, berfungsi sebagai pemilih pelanggan saat checkout
  const CustomerListScreen({super.key, this.isPicker = false});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CustomerProvider>(context, listen: false).getCustomers();
    });
  }

  void _showAddCustomerDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Tambah Pelanggan"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Nama Lengkap"),
            ),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: "No. HP (Opsional)"),
            ),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(labelText: "Alamat (Opsional)"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                final newCust = Customer(
                  name: nameController.text,
                  phone: phoneController.text,
                  address: addressController.text,
                );
                Provider.of<CustomerProvider>(
                  context,
                  listen: false,
                ).addCustomer(newCust);
                Navigator.pop(ctx);
              }
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Data Pelanggan")),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCustomerDialog,
        child: const Icon(Icons.person_add),
      ),
      body: Consumer<CustomerProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading)
            return const Center(child: CircularProgressIndicator());

          if (provider.customers.isEmpty) {
            return const Center(child: Text("Belum ada data pelanggan"));
          }

          return ListView.builder(
            itemCount: provider.customers.length,
            itemBuilder: (ctx, i) {
              final cust = provider.customers[i];
              return ListTile(
                leading: CircleAvatar(child: Text(cust.name[0].toUpperCase())),
                title: Text(
                  cust.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(cust.phone ?? "-"),
                onTap: widget.isPicker
                    ? () =>
                          Navigator.pop(
                            context,
                            cust,
                          ) // Return customer jika mode picker
                    : null, // Nanti bisa tambah detail/edit
              );
            },
          );
        },
      ),
    );
  }
}
