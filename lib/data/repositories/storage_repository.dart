import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageRepository {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload book cover image
  Future<String> uploadBookCover(String bookId, File imageFile) async {
    try {
      final ref = _storage.ref().child('book_covers/$bookId.jpg');
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      rethrow;
    }
  }

  // Delete book cover image
  Future<void> deleteBookCover(String bookId) async {
    try {
      final ref = _storage.ref().child('book_covers/$bookId.jpg');
      await ref.delete();
    } catch (e) {
      rethrow;
    }
  }
}

