import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_attendance_system/data/model.dart';
import 'package:qr_attendance_system/features/authentication/firabse_auth_servise.dart';
import 'package:qr_attendance_system/screens/admin/faculty_signin_screen.dart';
import 'package:qr_attendance_system/screens/admin/student_management.dart';
import 'package:qr_attendance_system/screens/admin/statistics_screen.dart';
import 'package:qr_attendance_system/screens/auth/login_screen.dart';
import 'package:qr_attendance_system/screens/faculty/class_attendance_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<FirebaseAuthProvider>(
      context,
      listen: false,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            onPressed: () async {
              await authProvider.signOut();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              }
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(
                      Icons.admin_panel_settings,
                      size: 48,
                      color: Colors.purple,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Welcome, Admin',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      authProvider.user?.email ?? '',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
            // const DashboardOverview(),
            const SizedBox(height: 24),
            // Admin Actions
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.5, // Added to fix sizing
              children: [
                _buildActionCard(
                  context,
                  'View Statistics',
                  Icons.bar_chart,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StatisticsScreen(),
                      ),
                    );
                  },
                ),
                _buildActionCard(context, 'Manage Faculty', Icons.people, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FacultyManagement(),
                    ),
                  );
                }),
                _buildActionCard(context, 'Manage Students', Icons.school, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StudentManagementScreen(),
                    ),
                  );
                }),
                _buildActionCard(
                  context,
                  'Class Monitoring',
                  Icons.monitor,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ClassMonitoring(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.purple),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardOverview extends StatelessWidget {
  const DashboardOverview({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('statistics').snapshots(),
      builder: (context, snapshot) {
        return GridView.count(
          padding: const EdgeInsets.all(16),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildStatCard(
              'Total Faculty',
              '${snapshot.data?.docs.length ?? 0}',
              Icons.people,
              Colors.blue,
            ),
            _buildStatCard(
              'Total Students',
              '${snapshot.data?.docs.length ?? 0}',
              Icons.school,
              Colors.green,
            ),
            _buildStatCard(
              'Active Classes',
              '${snapshot.data?.docs.length ?? 0}',
              Icons.class_,
              Colors.orange,
            ),
            _buildStatCard(
              'Total Attendance',
              '${snapshot.data?.docs.length ?? 0}',
              Icons.check_circle,
              Colors.purple,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class FacultyManagement extends StatelessWidget {
  const FacultyManagement({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Faculty')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('faculty').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FacultyRegisterScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add New Faculty'),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: snapshot.data?.docs.length ?? 0,
                  itemBuilder: (context, index) {
                    final faculty = snapshot.data!.docs[index];
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(faculty['name'] ?? ''),
                      subtitle: Text(faculty['email'] ?? ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          // Delete faculty logic
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class StudentManagement extends StatelessWidget {
  const StudentManagement({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Students')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('students').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to student registration screen
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add New Student'),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: snapshot.data?.docs.length ?? 0,
                  itemBuilder: (context, index) {
                    final student = snapshot.data!.docs[index];
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(student['name'] ?? ''),
                      subtitle: Text(student['rollNumber'] ?? ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          // Delete student logic
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class ClassMonitoring extends StatelessWidget {
  const ClassMonitoring({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Class Monitoring')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('classes')
            .orderBy('startTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            itemCount: snapshot.data?.docs.length ?? 0,
            itemBuilder: (context, index) {
              final classData = snapshot.data!.docs[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(classData['className'] ?? ''),
                  subtitle: Text(
                    'Faculty: ${classData['facultyName'] ?? ''}',
                  ), // Changed from facultyName to faculty
                  trailing: Text(
                    DateTime.now().isAfter(
                              DateTime.parse(classData['startTime']),
                            ) &&
                            DateTime.now().isBefore(
                              DateTime.parse(classData['endTime']),
                            )
                        ? 'Active'
                        : 'Finished',
                    style: TextStyle(
                      color:
                          DateTime.now().isAfter(
                                DateTime.parse(classData['startTime']),
                              ) &&
                              DateTime.now().isBefore(
                                DateTime.parse(classData['endTime']),
                              )
                          ? Colors.green
                          : Colors.red,
                      fontSize: 15,
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ClassAttendanceScreen(
                          classData: ClassModel(
                            className: classData['className'],
                            facultyName: classData['facultyName'],
                            startTime: DateTime.parse(classData['startTime']),
                            endTime: DateTime.parse(classData['endTime']),
                            id: classData.id,
                            subject: classData['subject'] ?? '',
                            createdAt: DateTime.parse(classData['createdAt']),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
