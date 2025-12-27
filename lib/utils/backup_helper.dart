import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import '../database/db_helper.dart';

class BackupHelper {
  // --- FUNGSI BACKUP (Database + Gambar -> ZIP) ---
  static Future<void> createBackup(BuildContext context) async {
    try {
      final encoder = ZipFileEncoder();

      // 1. Siapkan Folder Temporary
      final tempDir = await getTemporaryDirectory();
      final backupFileName =
          "Backup_Toko_${DateFormat('ddMMyy_HHmm').format(DateTime.now())}.zip";
      final zipPath = p.join(tempDir.path, backupFileName);

      encoder.create(zipPath);

      // 2. Tambahkan File Database
      final dbPath = await DatabaseHelper.instance.dbPath;
      final dbFile = File(dbPath);
      if (await dbFile.exists()) {
        encoder.addFile(
          dbFile,
          "toko_kasir_v2.db",
        ); // Simpan dengan nama standar
      }

      // 3. Tambahkan Gambar Produk (Jika ada)
      final appDocDir = await getApplicationDocumentsDirectory();
      final files = appDocDir.listSync();

      for (var file in files) {
        if (file is File &&
            (file.path.endsWith('.jpg') || file.path.endsWith('.png'))) {
          // Ambil nama filenya saja
          final filename = p.basename(file.path);
          encoder.addFile(
            file,
            "images/$filename",
          ); // Masukkan ke folder 'images' dalam zip
        }
      }

      encoder.close();

      // 4. Bagikan File ZIP (User bisa simpan ke Drive/WA/File Manager)
      // Ini cara paling aman di Android 11+ tanpa permission ribet
      await Share.shareXFiles([XFile(zipPath)], text: "Backup Data Toko Kasir");
    } catch (e) {
      debugPrint("Backup Error: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal membuat backup: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- FUNGSI RESTORE (ZIP -> Database + Gambar) ---
  static Future<bool> restoreBackup(BuildContext context) async {
    try {
      // 1. Pilih File Backup
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (result == null) return false; // Batal pilih

      final File zipFile = File(result.files.single.path!);

      // 2. Konfirmasi User (Karena akan menimpa data lama)
      bool confirm =
          await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text("Peringatan Restore"),
              content: const Text(
                "Tindakan ini akan MENIMPA semua data saat ini dengan data dari file backup.\n\nAplikasi akan restart setelah proses selesai.",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text("Batal"),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("TIMPA DATA"),
                ),
              ],
            ),
          ) ??
          false;

      if (!confirm) return false;

      // 3. Tutup Koneksi Database (PENTING!)
      await DatabaseHelper.instance.close();

      // 4. Ekstrak ZIP
      final bytes = zipFile.readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);

      final dbPath = await DatabaseHelper.instance.dbPath;
      final appDocDir = await getApplicationDocumentsDirectory();

      for (final file in archive) {
        if (file.isFile) {
          final data = file.content as List<int>;

          if (file.name == "toko_kasir_v2.db") {
            // Restore Database
            File(dbPath)
              ..createSync(recursive: true)
              ..writeAsBytesSync(data);
          } else if (file.name.startsWith("images/")) {
            // Restore Gambar
            final filename = p.basename(file.name);
            final imagePath = p.join(appDocDir.path, filename);
            File(imagePath)
              ..createSync(recursive: true)
              ..writeAsBytesSync(data);
          }
        }
      }

      return true; // Sukses
    } catch (e) {
      debugPrint("Restore Error: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal restore data: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }
}
