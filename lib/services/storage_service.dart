import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadEventPoster(File file, {String? eventId}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anon';
    final name = eventId ?? DateTime.now().millisecondsSinceEpoch.toString();
    final ext = p.extension(file.path).isEmpty ? '.jpg' : p.extension(file.path);
    final ref = _storage.ref().child('events/$name/poster_$uid$ext');

    final metadata = SettableMetadata(
      contentType: _contentType(ext),
      customMetadata: {'uploadedBy': uid},
    );

    await ref.putFile(file, metadata);
    return ref.getDownloadURL();
  }

  Future<String> uploadProfilePhoto(File file, String uid) async {
    final ext = p.extension(file.path).isEmpty ? '.jpg' : p.extension(file.path);
    final ref = _storage.ref().child('users/$uid/avatar$ext');

    final metadata = SettableMetadata(
      contentType: _contentType(ext),
      customMetadata: {'uploadedBy': uid},
    );

    await ref.putFile(file, metadata);
    return ref.getDownloadURL();
  }

  String _contentType(String ext) {
    switch (ext.toLowerCase()) {
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  /// No-op safe check for unsupported platforms in tests.
  bool get isSupported => !kIsWeb;
}
