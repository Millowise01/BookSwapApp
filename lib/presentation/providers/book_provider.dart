import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/repositories/book_repository.dart';
import '../../data/repositories/storage_repository.dart';
import '../../domain/models/book_model.dart';

class BookProvider with ChangeNotifier {
  final BookRepository _bookRepository = BookRepository();
  final StorageRepository _storageRepository = StorageRepository();

  final List<BookListing> _allListings = [];
  final List<BookListing> _myListings = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<BookListing> get allListings => _allListings;
  List<BookListing> get myListings => _myListings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Stream all listings
  Stream<List<BookListing>> getAllListings() {
    return _bookRepository.getAllListings();
  }

  // Stream user's listings
  Stream<List<BookListing>> getMyListings(String userId) {
    return _bookRepository.getUserListings(userId);
  }

  Future<bool> createBookListing({
    required String ownerId,
    required String ownerName,
    required String ownerEmail,
    required String title,
    required String author,
    required String swapFor,
    required String condition,
    File? imageFile,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String? coverImageUrl;

      // Create listing first to get the ID
      final book = BookListing(
        ownerId: ownerId,
        ownerName: ownerName,
        ownerEmail: ownerEmail,
        title: title,
        author: author,
        swapFor: swapFor,
        condition: condition,
        createdAt: DateTime.now(),
      );

      final listingId = await _bookRepository.createBookListing(book);

      // Upload image if provided
      if (imageFile != null) {
        try {
          coverImageUrl = await _storageRepository.uploadBookCover(
            listingId,
            imageFile,
          );

          // Update listing with image URL
          final bookWithImage = book.copyWith(
            id: listingId,
            coverImageUrl: coverImageUrl,
          );
          await _bookRepository.updateBookListing(bookWithImage);
        } catch (e) {
          // Image upload failed but book was created
          print('Image upload failed: $e');
        }
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateBookListing({
    required BookListing book,
    File? imageFile,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String? coverImageUrl = book.coverImageUrl;

      // Upload new image if provided
      if (imageFile != null && book.id != null) {
        try {
          coverImageUrl = await _storageRepository.uploadBookCover(
            book.id!,
            imageFile,
          );
        } catch (e) {
          print('Image upload failed: $e');
        }
      }

      final updatedBook = book.copyWith(
        coverImageUrl: coverImageUrl,
        updatedAt: DateTime.now(),
      );

      await _bookRepository.updateBookListing(updatedBook);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteBookListing(String listingId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _bookRepository.deleteBookListing(listingId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

