import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import '../models/customer_model.dart'; // Import Model Customer
import 'customer_list_screen.dart'; // Import Screen untuk pilih customer

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  // Fungsi Payment Dialog
  void _showPaymentDialog(CartProvider cart) {
    final amountController = TextEditingController();

    // State lokal untuk dialog
    bool isDebt = false;
    Customer? selectedCustomer;
    int inputAmount = 0; // Uang yang diterima / DP

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            // Hitung kembalian atau sisa utang
            int changeOrDebt = 0;
            if (isDebt) {
              changeOrDebt = cart.totalAmount - inputAmount; // Sisa Utang
            } else {
              changeOrDebt = inputAmount - cart.totalAmount; // Kembalian
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "Pembayaran",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // --- PILIH PELANGGAN (Wajib jika Hutang) ---
                  InkWell(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const CustomerListScreen(isPicker: true),
                        ),
                      );
                      if (result != null && result is Customer) {
                        setStateModal(() {
                          selectedCustomer = result;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                        color: selectedCustomer != null
                            ? Colors.blue.shade50
                            : Colors.white,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.person,
                            color: selectedCustomer != null
                                ? Colors.blue
                                : Colors.grey,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              selectedCustomer != null
                                  ? selectedCustomer!.name
                                  : "Pilih Pelanggan (Opsional)",
                              style: TextStyle(
                                fontWeight: selectedCustomer != null
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: selectedCustomer != null
                                    ? Colors.blue.shade800
                                    : Colors.grey,
                              ),
                            ),
                          ),
                          if (selectedCustomer != null)
                            IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              onPressed: () {
                                setStateModal(() => selectedCustomer = null);
                              },
                            )
                          else
                            const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.grey,
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- OPSI KASBON ---
                  Row(
                    children: [
                      Switch(
                        value: isDebt,
                        onChanged: (val) {
                          setStateModal(() {
                            isDebt = val;
                            // Jika pindah ke utang, validasi customer nanti di tombol bayar
                          });
                        },
                      ),
                      const Text("Catat sebagai Kasbon / Utang"),
                    ],
                  ),
                  const Divider(),

                  // --- INPUT NOMINAL ---
                  // Total Tagihan
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Total Tagihan",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _currencyFormat.format(cart.totalAmount),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: isDebt
                          ? "Bayar DP (Opsional)"
                          : "Uang Diterima",
                      prefixText: "Rp ",
                      border: const OutlineInputBorder(),
                      helperText: isDebt ? "Biarkan 0 jika tidak ada DP" : null,
                    ),
                    onChanged: (val) {
                      setStateModal(() {
                        inputAmount = int.tryParse(val) ?? 0;
                      });
                    },
                  ),
                  const SizedBox(height: 10),

                  // --- INFO KEMBALIAN / SISA UTANG ---
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDebt
                          ? Colors.orange.shade50
                          : (changeOrDebt >= 0
                                ? Colors.green.shade50
                                : Colors.red.shade50),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isDebt ? "Sisa Utang:" : "Kembalian:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDebt
                                ? Colors.orange.shade900
                                : Colors.black87,
                          ),
                        ),
                        Text(
                          _currencyFormat.format(
                            isDebt ? changeOrDebt : changeOrDebt,
                          ),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isDebt
                                ? Colors.orange.shade900
                                : (changeOrDebt >= 0
                                      ? Colors.green.shade800
                                      : Colors.red.shade800),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // --- TOMBOL PROSES ---
                  ElevatedButton(
                    onPressed: () async {
                      // Validasi Dasar
                      if (isDebt && selectedCustomer == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Harap pilih pelanggan untuk transaksi Kasbon!",
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      if (!isDebt && inputAmount < cart.totalAmount) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Uang tunai kurang!"),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      // 1. Proses Checkout
                      bool success = await cart.processCheckout(
                        paymentAmount: inputAmount,
                        paymentMethod: isDebt ? 'DEBT' : 'CASH',
                        customerId: selectedCustomer?.id,
                        isDebt: isDebt,
                      );

                      if (success) {
                        // 2. Refresh Stok
                        if (mounted) {
                          Provider.of<ProductProvider>(
                            context,
                            listen: false,
                          ).getProducts(isRefresh: true);
                          Navigator.pop(context); // Tutup Modal
                          Navigator.pop(context); // Tutup Layar Cart

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isDebt
                                    ? "Kasbon berhasil dicatat!"
                                    : "Transaksi Lunas Berhasil!",
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: isDebt ? Colors.orange : Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      isDebt ? "SIMPAN UTANG" : "BAYAR SEKARANG",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Keranjang Belanja")),
      body: Consumer<CartProvider>(
        builder: (context, cart, _) {
          if (cart.items.isEmpty) {
            return const Center(child: Text("Keranjang kosong"));
          }

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: cart.items.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (ctx, i) {
                    final item = cart.items[i];
                    return Row(
                      children: [
                        // Nama Produk & Harga
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.product.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _currencyFormat.format(item.product.price),
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Counter Qty
                        IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            color: Colors.red,
                          ),
                          onPressed: () => cart.decreaseQty(i),
                        ),
                        Text(
                          "${item.quantity}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle_outline,
                            color: Colors.green,
                          ),
                          onPressed: () => cart.increaseQty(i),
                        ),

                        // Subtotal
                        SizedBox(
                          width: 80,
                          child: Text(
                            _currencyFormat.format(item.subtotal),
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Bottom Action
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Total Tagihan",
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          _currencyFormat.format(cart.totalAmount),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _showPaymentDialog(cart),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          "LANJUT PEMBAYARAN",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
