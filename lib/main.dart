import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_attendance_system/features/authentication/firabse_auth_servise.dart';
import 'package:qr_attendance_system/firebase_options.dart';
import 'package:qr_attendance_system/screens/admin/admin_dashboard.dart';
import 'package:qr_attendance_system/screens/auth/login_screen.dart';
import 'package:qr_attendance_system/screens/faculty/faculty_dashboard.dart';
import 'package:qr_attendance_system/screens/student/student_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FirebaseAuthProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: LoginScreen(),
      routes: {
        '/login': (context) => LoginScreen(),
        '/studentDashboard': (context) => StudentDashboard(),
        '/adminDashboard': (context) => AdminDashboard(),
        '/facultyDashboard': (context) => FacultyDashboard(facultyId: ''),
        '/facultyManagement': (context) => const FacultyManagement(),
        '/studentManagement': (context) => const StudentManagement(),
      },
    );
  }
}
