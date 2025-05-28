/// Provides attendance management functionality throughout the app
/// Manages the state of attended students and handles Firestore operations
/// related to attendance tracking.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_attendance_system/data/model.dart';

/// Provider class for managing attendance-related operations
class AttendanceProvider with ChangeNotifier {
  /// Firebase Firestore instance for database operations
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// List of students who have marked attendance
  List<Student> _attendedStudents = [];

  /// Loading state indicator
  bool _isLoading = false;

  /// Error message if any operation fails
  String? _error;

  /// Getter for attended students list
  List<Student> get attendedStudents => _attendedStudents;

  /// Getter for loading state
  bool get isLoading => _isLoading;

  /// Getter for error message
  String? get error => _error;

  /// Fetches the details of students who have marked attendance
  ///
  /// Parameters:
  /// - studentIds: List of student IDs who have marked attendance
  ///
  /// Updates the [_attendedStudents] list with student details
  /// Notifies listeners of any changes in the state
  Future<void> fetchAttendedStudents(List<String> studentIds) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (studentIds.isEmpty) {
        _attendedStudents = [];
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Fetch student documents from Firestore
      final QuerySnapshot snapshot = await _firestore
          .collection('students')
          .where(FieldPath.documentId, whereIn: studentIds)
          .get();

      // Convert documents to Student objects
      _attendedStudents = snapshot.docs.map((doc) {
        return Student.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      // Sort students alphabetically by name
      _attendedStudents.sort((a, b) => a.name.compareTo(b.name));

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error fetching attended students: $e');
      _error = 'Failed to load attended students: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clears any error message and notifies listeners
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
