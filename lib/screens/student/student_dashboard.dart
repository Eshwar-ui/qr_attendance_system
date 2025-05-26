import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_attendance_system/features/authentication/firabse_auth_servise.dart';

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<FirebaseAuthProvider>(
      context,
      listen: false,
    );
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            Text(
              'Student Dashboard',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            IconButton(
              onPressed: () {
                authProvider.signOut();
                Navigator.pushReplacementNamed(context, '/login');
              },
              icon: Icon(Icons.logout, size: 50),
            ),
          ],
        ),
      ),
    );
  }
}
