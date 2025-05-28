import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:qr_attendance_system/features/authentication/firabse_auth_servise.dart';

class StudentProfile extends StatelessWidget {
  const StudentProfile({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<FirebaseAuthProvider>(
      context,
      listen: false,
    );
    final studentId = authProvider.user?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Student Profile')),
      body: studentId == null
          ? const Center(child: Text('Not authenticated'))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('students')
                  .doc(studentId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text('Student profile not found'));
                }

                final studentData =
                    snapshot.data!.data() as Map<String, dynamic>;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey[300],
                          child: const Icon(Icons.person, size: 50),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildInfoCard(
                        title: 'Personal Information',
                        children: [
                          _buildInfoRow('Name', studentData['name'] ?? 'N/A'),
                          _buildInfoRow(
                            'Roll Number',
                            studentData['rollNumber'] ?? 'N/A',
                          ),
                          _buildInfoRow('Email', studentData['email'] ?? 'N/A'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildInfoCard(
                        title: 'Academic Information',
                        children: [
                          _buildInfoRow(
                            'Department',
                            studentData['department'] ?? 'N/A',
                          ),
                          _buildInfoRow(
                            'Semester',
                            studentData['semester']?.toString() ?? 'N/A',
                          ),
                          _buildInfoRow(
                            'Section',
                            studentData['section'] ?? 'N/A',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildInfoCard(
                        title: 'Contact Information',
                        children: [
                          _buildInfoRow('Phone', studentData['phone'] ?? 'N/A'),
                          _buildInfoRow(
                            'Address',
                            studentData['address'] ?? 'N/A',
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
