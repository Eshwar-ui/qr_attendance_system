/// Firebase Authentication Service Provider
/// Manages user authentication state and operations throughout the app.
/// Provides methods for login, logout, and user role management.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Provider class for managing authentication state and operations
class FirebaseAuthProvider with ChangeNotifier {
  /// Firebase Authentication instance
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Firebase Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Current user's role (student, faculty, or admin)
  String? _userRole;

  /// Current user's display name
  String? _userName;

  /// Error message if any operation fails
  String? _error;

  /// Getter for current user's role
  String? get userRole => _userRole;

  /// Getter for current user's name
  String? get userName => _userName;

  /// Getter for error message
  String? get error => _error;

  /// Signs in a user with email and password
  ///
  /// Parameters:
  /// - email: User's email address
  /// - password: User's password
  ///
  /// Returns true if login successful, false otherwise
  /// Updates user role and name on successful login
  Future<bool> signIn(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        await _fetchUserRole(userCredential.user!.uid);
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Login failed: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Signs out the current user
  ///
  /// Clears user role and name
  /// Returns true if logout successful, false otherwise
  Future<bool> signOut() async {
    try {
      await _auth.signOut();
      _userRole = null;
      _userName = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Logout failed: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Fetches the user's role and name from Firestore
  ///
  /// Parameters:
  /// - uid: User's unique identifier
  ///
  /// Updates _userRole and _userName based on Firestore data
  Future<void> _fetchUserRole(String uid) async {
    try {
      // Check admin collection first
      var adminDoc = await _firestore.collection('admins').doc(uid).get();
      if (adminDoc.exists) {
        _userRole = 'admin';
        _userName = adminDoc.data()?['name'];
        notifyListeners();
        return;
      }

      // Check faculty collection
      var facultyDoc = await _firestore.collection('faculty').doc(uid).get();
      if (facultyDoc.exists) {
        _userRole = 'faculty';
        _userName = facultyDoc.data()?['name'];
        notifyListeners();
        return;
      }

      // Check students collection
      var studentDoc = await _firestore.collection('students').doc(uid).get();
      if (studentDoc.exists) {
        _userRole = 'student';
        _userName = studentDoc.data()?['name'];
        notifyListeners();
        return;
      }

      // No role found
      _error = 'User role not found';
      notifyListeners();
    } catch (e) {
      _error = 'Error fetching user role: ${e.toString()}';
      notifyListeners();
    }
  }
}
