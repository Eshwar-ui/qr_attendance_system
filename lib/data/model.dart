/// Data models for the QR Attendance System
/// This file contains the core data structures used throughout the application.

/// Student Model
/// Represents a student in the system with all their academic and personal details.
class Student {
  /// Unique identifier for the student (matches Firebase Auth UID)
  final String id;

  /// Full name of the student
  final String name;

  /// Student's email address (used for authentication)
  final String email;

  /// Unique roll number assigned to the student
  final String rollNumber;

  /// Student's branch/department (e.g., CSE, ECE)
  final String branch;

  /// Current year of study (1-4)
  final String year;

  /// Class section (A, B, C, D)
  final String section;

  /// Current semester (1-8)
  final String semester;

  /// Contact phone number
  final String phone;

  /// Residential address
  final String address;

  /// List of class IDs where the student has marked attendance
  final List<String> attendedClassIds;

  /// Creates a new Student instance
  Student({
    required this.id,
    required this.name,
    required this.email,
    required this.rollNumber,
    required this.branch,
    required this.year,
    required this.section,
    required this.semester,
    required this.phone,
    required this.address,
    this.attendedClassIds = const [],
  });

  /// Creates a Student instance from a Firestore document
  factory Student.fromMap(Map<String, dynamic> map, String docId) {
    return Student(
      id: docId,
      name: map['name'],
      email: map['email'],
      rollNumber: map['rollNumber'],
      branch: map['branch'],
      year: map['year'] ?? '1',
      section: map['section'] ?? 'A',
      semester: map['semester'] ?? '1',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      attendedClassIds: List<String>.from(map['attendedClassIds'] ?? []),
    );
  }

  /// Converts the Student instance to a map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'rollNumber': rollNumber,
      'branch': branch,
      'year': year,
      'section': section,
      'semester': semester,
      'phone': phone,
      'address': address,
      'attendedClassIds': attendedClassIds,
    };
  }
}

/// Faculty Model
/// Represents a faculty member in the system
class Faculty {
  /// Unique identifier for the faculty member (matches Firebase Auth UID)
  final String id;

  /// Full name of the faculty member
  final String name;

  /// Faculty's email address (used for authentication)
  final String email;

  /// List of class IDs created by this faculty member
  final List<String> createdClassIds;

  /// Creates a new Faculty instance
  Faculty({
    required this.id,
    required this.name,
    required this.email,
    this.createdClassIds = const [],
  });

  /// Creates a Faculty instance from a Firestore document
  factory Faculty.fromMap(Map<String, dynamic> map, String docId) {
    return Faculty(
      id: docId,
      name: map['name'],
      email: map['email'],
      createdClassIds: List<String>.from(map['createdClassIds'] ?? []),
    );
  }

  /// Converts the Faculty instance to a map for Firestore storage
  Map<String, dynamic> toMap() {
    return {'name': name, 'email': email, 'createdClassIds': createdClassIds};
  }
}

/// Class Model
/// Represents a class session with attendance tracking
class ClassModel {
  /// Unique identifier for the class
  final String id;

  /// Name/title of the class
  final String className;

  /// Subject being taught
  final String subject;

  /// Name of the faculty member teaching the class
  final String facultyName;

  /// When the class was created in the system
  final DateTime createdAt;

  /// When the class session starts
  final DateTime startTime;

  /// When the class session ends
  final DateTime endTime;

  /// List of student IDs who have marked attendance
  final List<String> attendedStudentIds;

  /// Creates a new ClassModel instance
  ClassModel({
    required this.id,
    required this.className,
    required this.subject,
    required this.facultyName,
    required this.createdAt,
    required this.startTime,
    required this.endTime,
    this.attendedStudentIds = const [],
  });

  /// Creates a ClassModel instance from a Firestore document
  factory ClassModel.fromMap(Map<String, dynamic> map, String docId) {
    return ClassModel(
      id: docId,
      className: map['className'],
      subject: map['subject'],
      facultyName: map['facultyName'],
      createdAt: DateTime.parse(map['createdAt']),
      startTime: DateTime.parse(map['startTime']),
      endTime: DateTime.parse(map['endTime']),
      attendedStudentIds: List<String>.from(map['attendedStudentIds'] ?? []),
    );
  }

  /// Converts the ClassModel instance to a map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'className': className,
      'subject': subject,
      'facultyName': facultyName,
      'createdAt': createdAt.toIso8601String(),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'attendedStudentIds': attendedStudentIds,
    };
  }

  /// Determines if the class is currently active
  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  /// Gets the current status of the class (Active, Upcoming, or Completed)
  String get classStatus {
    final now = DateTime.now();
    if (now.isBefore(startTime)) return 'Upcoming';
    if (now.isAfter(endTime)) return 'Completed';
    return 'Active';
  }
}
