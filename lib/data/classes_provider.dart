/// Provides class management functionality throughout the app
/// Manages the state of classes and handles Firestore operations
/// related to class creation, fetching, and attendance tracking.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_attendance_system/data/model.dart';

/// Provider class for managing class-related operations
class ClassesProvider with ChangeNotifier {
  /// Firebase Firestore instance for database operations
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// List of classes managed by this provider
  List<ClassModel> _classes = [];

  /// Loading state indicator
  bool _isLoading = false;

  /// Error message if any operation fails
  String? _error;

  /// Getter for classes list
  List<ClassModel> get classes => _classes;

  /// Getter for loading state
  bool get isLoading => _isLoading;

  /// Getter for error message
  String? get error => _error;

  /// Fetches all classes for a specific faculty member
  ///
  /// Parameters:
  /// - facultyName: Name of the faculty member whose classes to fetch
  ///
  /// Updates the [_classes] list with class details and sorts them by status
  /// Notifies listeners of any changes in the state
  Future<void> fetchUserClasses(String facultyName) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Fetch classes from Firestore
      final QuerySnapshot snapshot = await _firestore
          .collection('classes')
          .where('facultyName', isEqualTo: facultyName)
          .get();

      _classes = [];

      // Convert documents to ClassModel objects
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final classModel = ClassModel.fromMap(data, doc.id);
          _classes.add(classModel);
        } catch (e) {
          print('Error processing class document ${doc.id}: $e');
          continue;
        }
      }

      // Sort classes by status and start time
      _classes.sort((a, b) {
        // First priority: Active classes
        if (a.classStatus == 'Active' && b.classStatus != 'Active') return -1;
        if (b.classStatus == 'Active' && a.classStatus != 'Active') return 1;

        // Second priority: Upcoming classes
        if (a.classStatus == 'Upcoming' && b.classStatus == 'Completed')
          return -1;
        if (b.classStatus == 'Upcoming' && a.classStatus == 'Completed')
          return 1;

        // If same status, sort by start time
        return a.startTime.compareTo(b.startTime);
      });

      // Debug logging
      print('Fetched ${_classes.length} classes:');
      for (var cls in _classes) {
        print(
          'Class: ${cls.className}, Status: ${cls.classStatus}, Start: ${cls.startTime}',
        );
      }

      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      print('Error in fetchUserClasses: $e');
      _error = 'Failed to fetch classes: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Generates a unique QR code string for a class
  ///
  /// Parameters:
  /// - classId: ID of the class to generate QR code for
  ///
  /// Returns a unique string combining class ID and timestamp
  String generateQRCode(String classId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '$classId-$timestamp';
  }

  /// Retrieves the list of students who have marked attendance for a class
  ///
  /// Parameters:
  /// - classId: ID of the class to get attendance for
  ///
  /// Returns a list of student IDs who have marked attendance
  Future<List<String>> getAttendedStudents(String classId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection('classes')
          .doc(classId)
          .get();

      if (!doc.exists) {
        throw Exception('Class not found');
      }

      final data = doc.data() as Map<String, dynamic>;
      final List<String> attendedStudentIds = List<String>.from(
        data['attendedStudentIds'] ?? [],
      );

      return attendedStudentIds;
    } catch (e) {
      _error = 'Failed to fetch attended students: $e';
      notifyListeners();
      return [];
    }
  }

  /// Clears any error message and notifies listeners
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
