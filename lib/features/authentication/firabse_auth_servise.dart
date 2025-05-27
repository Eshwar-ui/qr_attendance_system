import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FirebaseAuthProvider with ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  User? _user;
  User? get user => _user;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  FirebaseAuthProvider() {
    _firebaseAuth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _user = credential.user;
      _errorMessage = null;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseError(e);
      // Show snackbar with error message
      if (e.code == 'wrong-password' || e.code == 'user-not-found') {
        ScaffoldMessenger.of(
          _firebaseAuth.app.toString() as BuildContext,
        ).showSnackBar(
          SnackBar(
            content: Text(_errorMessage ?? 'Authentication failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    _user = null;
    notifyListeners();
  }

  void _onAuthStateChanged(User? firebaseUser) {
    _user = firebaseUser;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-email':
        return 'Invalid email format.';
      default:
        return 'Authentication failed: ${e.message}';
    }
  }
}
