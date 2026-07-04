import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class StorageService {
  final _client = Supabase.instance.client;

  // ─── Upload PDF (version Bytes pour Web) ─────────────────
  Future<String> uploadPDFBytes({
    required String userId,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    try {
      final safeFileName = _sanitizeFileName(fileName);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath = '$userId/${safeFileName}_$timestamp.pdf';

      print('📤 Uploading bytes to: $storagePath');
      print('📁 File size: ${fileBytes.length} bytes');

      // Upload des bytes
      await _client.storage
          .from(SupabaseConfig.bucketPdfs)
          .uploadBinary(
        storagePath,
        fileBytes,
        fileOptions: const FileOptions(
          cacheControl: '3600',
          upsert: true,
          contentType: 'application/pdf',
        ),
      );

      print('✅ Upload successful');

      // Récupérer l'URL publique
      final publicUrl = _client.storage
          .from(SupabaseConfig.bucketPdfs)
          .getPublicUrl(storagePath);

      print('🔗 Public URL: $publicUrl');

      return publicUrl;
    } catch (e) {
      print('❌ Upload error: $e');
      throw Exception('Erreur lors de l\'upload du PDF: $e');
    }
  }

  // ─── Upload PDF (version File pour Mobile) ──────────────
  Future<String> uploadPDFFile({
    required String userId,
    required dynamic pdfFile,
    required String fileName,
  }) async {
    try {
      final safeFileName = _sanitizeFileName(fileName);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath = '$userId/${safeFileName}_$timestamp.pdf';

      await _client.storage
          .from(SupabaseConfig.bucketPdfs)
          .upload(
        storagePath,
        pdfFile,
        fileOptions: const FileOptions(
          cacheControl: '3600',
          upsert: true,
        ),
      );

      final publicUrl = _client.storage
          .from(SupabaseConfig.bucketPdfs)
          .getPublicUrl(storagePath);

      return publicUrl;
    } catch (e) {
      throw Exception('Erreur lors de l\'upload du PDF: $e');
    }
  }

  // ─── Nettoyer le nom de fichier ──────────────────────────
  String _sanitizeFileName(String fileName) {
    return fileName
        .replaceAll(RegExp(r'[^\w\s\-\.]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();
  }
}