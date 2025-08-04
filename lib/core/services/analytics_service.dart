import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Student analytics
  Future<Map<String, dynamic>> getStudentAnalytics(String studentId) async {
    final attendanceQuery = await _firestore
        .collection('attendance')
        .where('studentId', isEqualTo: studentId)
        .get();

    final classesQuery = await _firestore
        .collection('classes')
        .get();

    final totalClasses = classesQuery.docs.length;
    final attendedClasses = attendanceQuery.docs.length;
    final attendancePercentage = totalClasses > 0 
        ? (attendedClasses / totalClasses * 100).round() 
        : 0;

    // Weekly attendance trend
    final weeklyData = await _getWeeklyAttendance(studentId);
    
    // Subject-wise attendance
    final subjectData = await _getSubjectWiseAttendance(studentId);

    return {
      'totalClasses': totalClasses,
      'attendedClasses': attendedClasses,
      'attendancePercentage': attendancePercentage,
      'weeklyTrend': weeklyData,
      'subjectWise': subjectData,
      'streak': await _getAttendanceStreak(studentId),
    };
  }

  // Faculty analytics
  Future<Map<String, dynamic>> getFacultyAnalytics(String facultyId) async {
    final classesQuery = await _firestore
        .collection('classes')
        .where('facultyId', isEqualTo: facultyId)
        .get();

    final totalClasses = classesQuery.docs.length;
    int totalStudentsMarked = 0;
    final Map<String, int> dailyAttendance = {};

    for (var classDoc in classesQuery.docs) {
      final attendanceQuery = await _firestore
          .collection('attendance')
          .where('classId', isEqualTo: classDoc.id)
          .get();

      totalStudentsMarked += attendanceQuery.docs.length;

      // Group by date
      for (var attendance in attendanceQuery.docs) {
        final date = DateFormat('yyyy-MM-dd').format(
          (attendance.data()['timestamp'] as Timestamp).toDate()
        );
        dailyAttendance[date] = (dailyAttendance[date] ?? 0) + 1;
      }
    }

    return {
      'totalClasses': totalClasses,
      'totalStudentsMarked': totalStudentsMarked,
      'averageAttendancePerClass': totalClasses > 0 
          ? (totalStudentsMarked / totalClasses).round() 
          : 0,
      'dailyTrend': dailyAttendance,
      'topAttendingStudents': await _getTopAttendingStudents(facultyId),
    };
  }

  // Admin analytics
  Future<Map<String, dynamic>> getAdminAnalytics() async {
    final studentsQuery = await _firestore.collection('students').get();
    final facultyQuery = await _firestore.collection('faculty').get();
    final classesQuery = await _firestore.collection('classes').get();
    final attendanceQuery = await _firestore.collection('attendance').get();

    final totalStudents = studentsQuery.docs.length;
    final totalFaculty = facultyQuery.docs.length;
    final totalClasses = classesQuery.docs.length;
    final totalAttendanceRecords = attendanceQuery.docs.length;

    // Department-wise statistics
    final departmentStats = <String, Map<String, int>>{};
    for (var student in studentsQuery.docs) {
      final branch = student.data()['branch'] ?? 'Unknown';
      departmentStats[branch] ??= {'students': 0, 'attendance': 0};
      departmentStats[branch]!['students'] = 
          (departmentStats[branch]!['students'] ?? 0) + 1;
    }

    // Add attendance data to department stats
    for (var attendance in attendanceQuery.docs) {
      final studentDoc = await _firestore
          .collection('students')
          .doc(attendance.data()['studentId'])
          .get();
      
      if (studentDoc.exists) {
        final branch = studentDoc.data()?['branch'] ?? 'Unknown';
        departmentStats[branch] ??= {'students': 0, 'attendance': 0};
        departmentStats[branch]!['attendance'] = 
            (departmentStats[branch]!['attendance'] ?? 0) + 1;
      }
    }

    return {
      'totalStudents': totalStudents,
      'totalFaculty': totalFaculty,
      'totalClasses': totalClasses,
      'totalAttendanceRecords': totalAttendanceRecords,
      'departmentStats': departmentStats,
      'dailyAttendanceTrend': await _getDailyAttendanceTrend(),
      'lowAttendanceStudents': await _getLowAttendanceStudents(),
    };
  }

  Future<List<Map<String, dynamic>>> _getWeeklyAttendance(String studentId) async {
    final now = DateTime.now();
    final weekData = <Map<String, dynamic>>[];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final attendanceQuery = await _firestore
          .collection('attendance')
          .where('studentId', isEqualTo: studentId)
          .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
          .where('timestamp', isLessThan: endOfDay)
          .get();

      weekData.add({
        'date': DateFormat('E').format(date),
        'count': attendanceQuery.docs.length,
      });
    }

    return weekData;
  }

  Future<Map<String, int>> _getSubjectWiseAttendance(String studentId) async {
    final attendanceQuery = await _firestore
        .collection('attendance')
        .where('studentId', isEqualTo: studentId)
        .get();

    final subjectCount = <String, int>{};

    for (var attendance in attendanceQuery.docs) {
      final classDoc = await _firestore
          .collection('classes')
          .doc(attendance.data()['classId'])
          .get();

      if (classDoc.exists) {
        final subject = classDoc.data()?['subject'] ?? 'Unknown';
        subjectCount[subject] = (subjectCount[subject] ?? 0) + 1;
      }
    }

    return subjectCount;
  }

  Future<int> _getAttendanceStreak(String studentId) async {
    final attendanceQuery = await _firestore
        .collection('attendance')
        .where('studentId', isEqualTo: studentId)
        .orderBy('timestamp', descending: true)
        .get();

    if (attendanceQuery.docs.isEmpty) return 0;

    int streak = 0;
    DateTime? lastDate;

    for (var doc in attendanceQuery.docs) {
      final timestamp = (doc.data()['timestamp'] as Timestamp).toDate();
      final date = DateTime(timestamp.year, timestamp.month, timestamp.day);

      if (lastDate == null) {
        lastDate = date;
        streak = 1;
      } else {
        final difference = lastDate.difference(date).inDays;
        if (difference == 1) {
          streak++;
          lastDate = date;
        } else {
          break;
        }
      }
    }

    return streak;
  }

  Future<List<Map<String, dynamic>>> _getTopAttendingStudents(String facultyId) async {
    // Implementation for getting top attending students for a faculty
    final classesQuery = await _firestore
        .collection('classes')
        .where('facultyId', isEqualTo: facultyId)
        .get();

    final studentAttendance = <String, int>{};

    for (var classDoc in classesQuery.docs) {
      final attendanceQuery = await _firestore
          .collection('attendance')
          .where('classId', isEqualTo: classDoc.id)
          .get();

      for (var attendance in attendanceQuery.docs) {
        final studentId = attendance.data()['studentId'];
        studentAttendance[studentId] = (studentAttendance[studentId] ?? 0) + 1;
      }
    }

    // Sort and get top 5
    final sortedStudents = studentAttendance.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topStudents = <Map<String, dynamic>>[];
    for (var entry in sortedStudents.take(5)) {
      final studentDoc = await _firestore
          .collection('students')
          .doc(entry.key)
          .get();
      
      if (studentDoc.exists) {
        topStudents.add({
          'name': studentDoc.data()?['name'] ?? 'Unknown',
          'rollNumber': studentDoc.data()?['rollNumber'] ?? 'Unknown',
          'attendanceCount': entry.value,
        });
      }
    }

    return topStudents;
  }

  Future<Map<String, int>> _getDailyAttendanceTrend() async {
    final now = DateTime.now();
    final dailyTrend = <String, int>{};

    for (int i = 29; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final attendanceQuery = await _firestore
          .collection('attendance')
          .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
          .where('timestamp', isLessThan: endOfDay)
          .get();

      dailyTrend[DateFormat('MM-dd').format(date)] = attendanceQuery.docs.length;
    }

    return dailyTrend;
  }

  Future<List<Map<String, dynamic>>> _getLowAttendanceStudents() async {
    final studentsQuery = await _firestore.collection('students').get();
    final lowAttendanceStudents = <Map<String, dynamic>>[];

    for (var student in studentsQuery.docs) {
      final analytics = await getStudentAnalytics(student.id);
      if (analytics['attendancePercentage'] < 75) {
        lowAttendanceStudents.add({
          'name': student.data()['name'],
          'rollNumber': student.data()['rollNumber'],
          'attendancePercentage': analytics['attendancePercentage'],
        });
      }
    }

    return lowAttendanceStudents;
  }
}
