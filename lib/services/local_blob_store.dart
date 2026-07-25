import 'dart:convert';
import 'dart:typed_data';
import 'package:sembast/sembast.dart';
import 'sembast_db.dart';

/// Stores raw file bytes (PDFs, cover PNGs) inside the browser's
/// IndexedDB via sembast, base64-encoded since sembast records must
/// be JSON-safe. Nothing here ever leaves the browser: no upload, no
/// external URL, no server-side storage bucket.
class LocalBlobStore {
  static final _blobsStore = stringMapStoreFactory.store('blobs');

  Future<String> savePdf({required Uint8List bytes, required String uuid}) async {
    final db = await SembastDb.instance();
    final key = 'pdf:$uuid';
    await _blobsStore.record(key).put(db, {'data': base64Encode(bytes)});
    return key;
  }

  Future<String> saveCover({required Uint8List bytes, required String uuid}) async {
    final db = await SembastDb.instance();
    final key = 'cover:$uuid';
    await _blobsStore.record(key).put(db, {'data': base64Encode(bytes)});
    return key;
  }

  Future<Uint8List?> getBytes(String key) async {
    final db = await SembastDb.instance();
    final record = await _blobsStore.record(key).get(db);
    if (record == null) return null;
    return base64Decode(record['data'] as String);
  }

  Future<void> delete(String key) async {
    final db = await SembastDb.instance();
    await _blobsStore.record(key).delete(db);
  }

  /// Approximate stored size in bytes (decoded, not the base64 length).
  int approximateSize(Uint8List bytes) => bytes.length;
}
