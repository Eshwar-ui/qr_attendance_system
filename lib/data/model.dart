/* user models 
    - Student
      - student name
      - age
      - grade

    - Faculty
      - faculty name
      - department
      - email

    - Class
      - class name
      - subject
      - start time
      - end time
*/

class Student {
  final String id;
  final String name;
  final String email;
  final String rollNumber;
  final List<String> attendedClassIds;

  Student({
    required this.id,
    required this.name,
    required this.email,
    required this.rollNumber,
    this.attendedClassIds = const [],
  });

  factory Student.fromMap(Map<String, dynamic> map, String docId) {
    return Student(
      id: docId,
      name: map['name'],
      email: map['email'],
      rollNumber: map['rollNumber'],
      attendedClassIds: List<String>.from(map['attendedClassIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'rollNumber': rollNumber,
      'attendedClassIds': attendedClassIds,
    };
  }
}

class Faculty {
  final String id;
  final String name;
  final String email;
  final List<String> createdClassIds;

  Faculty({
    required this.id,
    required this.name,
    required this.email,
    this.createdClassIds = const [],
  });

  factory Faculty.fromMap(Map<String, dynamic> map, String docId) {
    return Faculty(
      id: docId,
      name: map['name'],
      email: map['email'],
      createdClassIds: List<String>.from(map['createdClassIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'email': email, 'createdClassIds': createdClassIds};
  }
}

class ClassModel {
  final String id;
  final String className;
  final String subject;
  final String facultyId;
  final DateTime createdAt;
  final List<String> attendedStudentIds;

  ClassModel({
    required this.id,
    required this.className,
    required this.subject,
    required this.facultyId,
    required this.createdAt,
    this.attendedStudentIds = const [],
  });

  factory ClassModel.fromMap(Map<String, dynamic> map, String docId) {
    return ClassModel(
      id: docId,
      className: map['className'],
      subject: map['subject'],
      facultyId: map['facultyId'],
      createdAt: DateTime.parse(map['createdAt']),
      attendedStudentIds: List<String>.from(map['attendedStudentIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'className': className,
      'subject': subject,
      'facultyId': facultyId,
      'createdAt': createdAt.toIso8601String(),
      'attendedStudentIds': attendedStudentIds,
    };
  }
}
