import 'package:flutter/material.dart';
import 'product_list_screen.dart'; // Import screen baru

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kasir UMKM"), centerTitle: true),
      body: GridView.count(
        padding: const EdgeInsets.all(20),
        crossAxisCount: 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        children: [
          _buildMenuCard(
            context,
            icon: Icons.point_of_sale,
            title: "Kasir",
            color: Colors.blue,
            onTap: () {
              // Navigasi ke Kasir (Nanti Phase 3)
            },
          ),
          _buildMenuCard(
            context,
            icon: Icons.inventory_2,
            title: "Produk",
            color: Colors.orange,
            onTap: () {
              // --- NAVIGASI KE SINI ---
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProductListScreen(),
                ),
              );
            },
          ),
          _buildMenuCard(
            context,
            icon: Icons.people,
            title: "Pelanggan",
            color: Colors.green,
            onTap: () {
              // Navigasi ke Pelanggan (Nanti)
            },
          ),
          _buildMenuCard(
            context,
            icon: Icons.bar_chart,
            title: "Laporan",
            color: Colors.purple,
            onTap: () {
              // Navigasi ke Laporan (Nanti)
            },
          ),
        ],
      ),
    );
  }

  // ... (Bagian widget _buildMenuCard ke bawah biarkan sama seperti sebelumnya)
  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
