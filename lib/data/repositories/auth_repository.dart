import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Check if email is verified
  Stream<bool> checkEmailVerification(String uid) async* {
    yield await _isEmailVerified(uid);
    yield* _auth.userChanges().asyncMap((user) async {
      if (user != null && user.uid == uid) {
        return _isEmailVerified(uid);
      }
      return false;
    });
  }

  Future<bool> _isEmailVerified(String uid) async {
    final user = _auth.currentUser;
    if (user != null && user.uid == uid) {
      await user.reload();
      return user.emailVerified;
    }
    return false;
  }

  // Sign up
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String name,
    required String university,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      ).timeout(Duration(seconds: 30));

      // Send email verification (non-blocking)
      userCredential.user?.sendEmailVerification().catchError((e) {
        print('Email verification error: $e');
      });

      // Try to create user profile in Firestore (non-blocking)
      _createUserProfile(userCredential.user?.uid, email, name, university);

      return userCredential;
    } catch (e) {
      print('Signup error: $e');
      rethrow;
    }
  }

  // Create user profile asynchronously
  void _createUserProfile(String? uid, String email, String name, String university) async {
    // Disabled for now - Firestore not configured
    print('Profile creation skipped - Firestore not ready');
  }

  // Sign in
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      ).timeout(Duration(seconds: 30));

      return userCredential;
    } catch (e) {
      print('Signin error: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Resend verification email
  Future<void> resendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.sendEmailVerification();
    }
  }

  // Get user profile
  Future<UserModel?> getUserProfile(String uid) async {
    // Return dummy profile for now
    return UserModel(
      uid: uid,
      email: _auth.currentUser?.email ?? '',
      name: 'User',
      university: 'University',
      createdAt: DateTime.now(),
    );
  }

  // Stream user profile
  Stream<UserModel?> streamUserProfile(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromJson(doc.data()!) : null);
  }
}

