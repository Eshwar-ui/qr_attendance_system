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

  /// Adds the student ID to the attendedStudentIds array for the given class
  /// and adds the class ID to the attendedClassIds array for the student
  ///
  /// Call this when the student scans a QR code to mark attendance.
  Future<void> markAttendance(String classId, String studentId) async {
    try {
      // Use a batch write to update both documents atomically
      final batch = _firestore.batch();
      
      // Update class document
      final classRef = _firestore.collection('classes').doc(classId);
      batch.update(classRef, {
        'attendedStudentIds': FieldValue.arrayUnion([studentId]),
      });
      
      // Update student document
      final studentRef = _firestore.collection('students').doc(studentId);
      batch.update(studentRef, {
        'attendedClassIds': FieldValue.arrayUnion([classId]),
      });
      
      // Commit the batch
      await batch.commit();
      
      print('Attendance marked for student $studentId in class $classId');
    } catch (e) {
      print('Error in markAttendance: $e');
      _error = 'Failed to mark attendance: $e';
      notifyListeners();
      rethrow; // Re-throw so the UI can handle the error
    }
  }

  /// Removes a student from a class attendance list
  ///
  /// Parameters:
  /// - classId: ID of the class to remove student from
  /// - studentId: ID of the student to remove
  ///
  /// This method removes the student from the class's attendedStudentIds
  /// and removes the class from the student's attendedClassIds
  Future<void> removeStudentFromClass(String classId, String studentId) async {
    try {
      // Use a batch write to update both documents atomically
      final batch = _firestore.batch();
      
      // Update class document - remove student from attendedStudentIds
      final classRef = _firestore.collection('classes').doc(classId);
      batch.update(classRef, {
        'attendedStudentIds': FieldValue.arrayRemove([studentId]),
      });
      
      // Update student document - remove class from attendedClassIds
      final studentRef = _firestore.collection('students').doc(studentId);
      batch.update(studentRef, {
        'attendedClassIds': FieldValue.arrayRemove([classId]),
      });
      
      // Commit the batch
      await batch.commit();
      
      print('Student $studentId removed from class $classId');
    } catch (e) {
      print('Error in removeStudentFromClass: $e');
      _error = 'Failed to remove student from class: $e';
      notifyListeners();
      rethrow; // Re-throw so the UI can handle the error
    }
  }

  /// Searches for a student by roll number
  ///
  /// Parameters:
  /// - rollNumber: The roll number to search for
  ///
  /// Returns the student data if found, null otherwise
  Future<Student?> searchStudentByRollNumber(String rollNumber) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('students')
          .where('rollNumber', isEqualTo: rollNumber.trim())
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final doc = snapshot.docs.first;
      return Student.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      print('Error searching student: $e');
      _error = 'Failed to search student: $e';
      notifyListeners();
      return null;
    }
  }

  /// Manually adds a student to a class (opposite of removeStudentFromClass)
  ///
  /// Parameters:
  /// - classId: ID of the class to add student to
  /// - studentId: ID of the student to add
  ///
  /// This method adds the student to the class's attendedStudentIds
  /// and adds the class to the student's attendedClassIds
  Future<void> addStudentToClass(String classId, String studentId) async {
    try {
      // Use a batch write to update both documents atomically
      final batch = _firestore.batch();
      
      // Update class document - add student to attendedStudentIds
      final classRef = _firestore.collection('classes').doc(classId);
      batch.update(classRef, {
        'attendedStudentIds': FieldValue.arrayUnion([studentId]),
      });
      
      // Update student document - add class to attendedClassIds
      final studentRef = _firestore.collection('students').doc(studentId);
      batch.update(studentRef, {
        'attendedClassIds': FieldValue.arrayUnion([classId]),
      });
      
      // Commit the batch
      await batch.commit();
      
      print('Student $studentId added to class $classId');
    } catch (e) {
      print('Error in addStudentToClass: $e');
      _error = 'Failed to add student to class: $e';
      notifyListeners();
      rethrow; // Re-throw so the UI can handle the error
    }
  }

  /// Clears any error message and notifies listeners
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
