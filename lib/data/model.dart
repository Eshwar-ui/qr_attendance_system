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
  final String facultyName;
  final DateTime createdAt;
  final DateTime startTime;
  final DateTime endTime;
  final List<String> attendedStudentIds;

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

  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  String get status {
    final now = DateTime.now();
    if (now.isBefore(startTime)) {
      return 'Upcoming';
    } else if (now.isAfter(endTime)) {
      return 'Completed';
    } else {
      return 'Active';
    }
  }
}
