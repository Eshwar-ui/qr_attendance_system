/// QR Attendance System
/// A Flutter application for managing student attendance using QR codes.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_attendance_system/data/classes_provider.dart';
import 'package:qr_attendance_system/data/attendance_provider.dart';
import 'package:qr_attendance_system/features/authentication/firabse_auth_servise.dart';
import 'package:qr_attendance_system/firebase_options.dart';
import 'package:qr_attendance_system/screens/admin/admin_dashboard.dart';
import 'package:qr_attendance_system/screens/admin/faculty_signin_screen.dart';
import 'package:qr_attendance_system/screens/admin/student_management.dart';
import 'package:qr_attendance_system/screens/admin/student_signin.dart';
import 'package:qr_attendance_system/screens/admin/statistics_screen.dart';
import 'package:qr_attendance_system/screens/auth/login_screen.dart';
import 'package:qr_attendance_system/screens/faculty/add_class_screen.dart';
import 'package:qr_attendance_system/screens/faculty/faculty_dashboard.dart';
import 'package:qr_attendance_system/screens/student/student_app.dart';
import 'package:qr_attendance_system/screens/student/student_profile.dart';
import 'package:qr_attendance_system/screens/student/student_dashboard.dart';

/// Entry point of the application
void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with platform-specific options
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Run the app with provider setup
  runApp(
    MultiProvider(
      providers: [
        // Authentication provider for managing user state
        ChangeNotifierProvider(create: (_) => FirebaseAuthProvider()),
        // Provider for managing classes data
        ChangeNotifierProvider(create: (_) => ClassesProvider()),
        // Provider for managing attendance data
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

/// Root widget of the application
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR Attendance System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      // Set initial screen to login
      home: const LoginScreen(),
      // Define named routes for navigation
      routes: {
        // Auth Routes
        '/login': (context) => const LoginScreen(),

        // Student Routes
        '/studentApp': (context) => const StudentApp(),
        '/studentDashboard': (context) => const StudentDashboard(),
        '/studentProfile': (context) => const StudentProfile(),

        // Admin Routes
        '/adminDashboard': (context) => const AdminDashboard(),
        '/facultyRegister': (context) => const FacultyRegisterScreen(),
        '/studentManagement': (context) => const StudentManagementScreen(),
        '/studentSignin': (context) => const StudentSignIn(),
        '/statistics': (context) => const StatisticsScreen(),
        '/classMonitoring': (context) => const ClassMonitoring(),
        '/facultyManagement': (context) => const FacultyManagement(),

        // Faculty Routes
        '/facultyDashboard': (context) => const FacultyDashboard(),
        '/addClass': (context) => const AddClassScreen(),
      },
    );
  }
}
