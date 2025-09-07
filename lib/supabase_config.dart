import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class Supa {
  // <<< SUBSTITUIR >>>
  static const String url = 'https://qexeyjldiyhwftrclqzx.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFleGV5amxkaXlod2Z0cmNscXp4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTcxODk2NTAsImV4cCI6MjA3Mjc2NTY1MH0.VOC73Y_mxg5xHjeklNLx1K4c9hiN7X9SYiLVCA65Nng';

  static Future<void> init() async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }

  static SupabaseClient get client => Supabase.instance.client;

  /// Helper: envia bytes para um bucket e devolve a URL pública.
  static Future<String?> uploadImageBytes({
    required String bucket,
    required String path,
    required Uint8List bytes,
    String? contentType,
  }) async {
    try {
      await client.storage.from(bucket).uploadBinary(path, bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: contentType,
          ));
      final publicUrl = client.storage.from(bucket).getPublicUrl(path);
      return publicUrl;
    } catch (_) {
      return null;
    }
  }
}
