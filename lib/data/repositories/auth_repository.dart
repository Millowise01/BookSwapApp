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
    try {
      final user = _auth.currentUser;
      if (user != null && user.uid == uid) {
        await user.reload().timeout(Duration(seconds: 3));
        return user.emailVerified;
      }
      return false;
    } catch (e) {
      print('Email verification check error: $e');
      return false;
    }
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

      // Send email verification
      try {
        await userCredential.user?.sendEmailVerification();
        print('Verification email sent to: ${userCredential.user?.email}');
      } catch (e) {
        print('Email verification error: $e');
        // Continue anyway - user can request resend
      }

      // Create user profile in Firestore (with timeout)
      try {
        await _firestore.collection('users').doc(userCredential.user?.uid).set({
          'uid': userCredential.user?.uid,
          'email': email,
          'name': name,
          'university': university,
          'createdAt': FieldValue.serverTimestamp(),
        }).timeout(Duration(seconds: 5));
      } catch (e) {
        print('Profile creation error: $e');
        // Continue anyway - profile can be created later
      }

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
      ).timeout(Duration(seconds: 10));

      // Reload user to get latest verification status
      await userCredential.user?.reload();
      
      // Check email verification
      if (!userCredential.user!.emailVerified) {
        await signOut(); // Sign out unverified user
        throw FirebaseAuthException(
          code: 'email-not-verified',
          message: 'Please verify your email before signing in. Check your inbox and spam folder.',
        );
      }

      print('User signed in successfully: ${userCredential.user?.email}');
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
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        print('Verification email resent to: ${user.email}');
      }
    } catch (e) {
      print('Resend verification error: $e');
      rethrow;
    }
  }

  // Get user profile
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      return null;
    }
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

