// ignore_for_file: avoid_print, deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:async';
import 'package:qr_attendance_system/features/authentication/firabse_auth_servise.dart';
import 'package:qr_attendance_system/screens/faculty/add_class_screen.dart';
import 'package:qr_attendance_system/screens/faculty/class_attendance_screen.dart';
import 'package:qr_attendance_system/data/model.dart';
import 'package:qr_attendance_system/screens/auth/login_screen.dart';
import 'package:qr_attendance_system/data/classes_provider.dart';

class FacultyDashboard extends StatefulWidget {
  final String? facultyId;
  const FacultyDashboard({super.key, this.facultyId});

  @override
  State<FacultyDashboard> createState() => _FacultyDashboardState();
}

class _FacultyDashboardState extends State<FacultyDashboard>
    with WidgetsBindingObserver {
  int currentIndex = 0;
  bool _isDisposed = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _isDisposed = false;
    WidgetsBinding.instance.addObserver(this);
    _initializeData();
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_isDisposed) {
      _refreshClasses();
    }
  }

  Future<void> _initializeData() async {
    if (_isDisposed || !mounted) return;

    try {
      final authProvider = Provider.of<FirebaseAuthProvider>(
        context,
        listen: false,
      );

      final facultyDoc = await FirebaseFirestore.instance
          .collection('faculty')
          .doc(authProvider.user?.uid)
          .get();

      final facultyName = facultyDoc.data()?['name'] as String?;

      if (facultyName == null || facultyName.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Unable to identify faculty. Please try logging in again.',
              ),
            ),
          );
        }
        return;
      }

      // Set up periodic refresh
      _refreshTimer?.cancel();
      _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
        if (!_isDisposed && mounted) {
          _refreshClasses();
        }
      });

      if (mounted) {
        final classesProvider = Provider.of<ClassesProvider>(
          context,
          listen: false,
        );
        await classesProvider.fetchUserClasses(facultyName);
      }
    } catch (e) {
      print('Initialization error: $e');
      if (!_isDisposed && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to initialize: $e')));
      }
    }
  }

  void _refreshClasses() {
    if (_isDisposed || !mounted) return;

    final authProvider = Provider.of<FirebaseAuthProvider>(
      context,
      listen: false,
    );
    FirebaseFirestore.instance
        .collection('faculty')
        .doc(authProvider.user?.uid)
        .get()
        .then((facultyDoc) {
          final facultyName = facultyDoc.data()?['name'] as String?;
          if (facultyName != null && mounted) {
            final classesProvider = Provider.of<ClassesProvider>(
              context,
              listen: false,
            );
            classesProvider.fetchUserClasses(facultyName);
          }
        })
        .catchError((error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to refresh classes: $error')),
            );
          }
        });
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(8),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: _refreshClasses,
        ),
      ),
    );
  }

  Widget _buildCurrentClassCard(List<ClassModel> classes) {
    if (_isDisposed || !mounted) return const SizedBox.shrink();
    if (classes.isEmpty) {
      print('No classes available to display');
      return const SizedBox.shrink();
    }

    try {
      // Get current time
      final now = DateTime.now();
      print('Current time: $now');

      // Find the first active or upcoming class
      ClassModel? currentClass;
      for (var classModel in classes) {
        print(
          'Checking class: ${classModel.className}, Status: ${classModel.classStatus}',
        );
        if (classModel.classStatus == 'Active' ||
            classModel.classStatus == 'Upcoming') {
          currentClass = classModel;
          print(
            'Found current class: ${currentClass.className} (${currentClass.classStatus})',
          );
          break;
        }
      }

      if (currentClass == null) {
        print('No active or upcoming classes found');
        return const SizedBox.shrink();
      }

      final bool isUpcoming = currentClass.classStatus == 'Upcoming';
      final bool isActive = currentClass.classStatus == 'Active';
      final statusColor = isActive ? Colors.green : Colors.orange;

      return Card(
        margin: const EdgeInsets.all(16),
        elevation: 4,
        child: InkWell(
          onTap: () {
            if (!_isDisposed && mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ClassAttendanceScreen(classData: currentClass!),
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isActive ? 'Active Class' : 'Upcoming Class',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusColor),
                      ),
                      child: Text(
                        currentClass.classStatus,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  currentClass.className,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  currentClass.subject,
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.access_time, color: Colors.grey[600], size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${_formatTime(currentClass.startTime)} - ${_formatTime(currentClass.endTime)}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (isActive)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: currentClass.id,
                      version: QrVersions.auto,
                      size: 200,
                      backgroundColor: Colors.white,
                      errorStateBuilder: (context, error) => const Center(
                        child: Text(
                          'Error generating QR code',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.schedule, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(
                          'Class starts at ${_formatTime(currentClass.startTime)}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  isActive
                      ? 'Scan to mark attendance'
                      : 'QR code will be available when class starts',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                if (isActive)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${currentClass.attendedStudentIds.length} students present',
                        style: const TextStyle(
                          color: Colors.purple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.purple),
                    ],
                  ),
                const SizedBox(height: 8),
                Text(
                  'Created on ${currentClass.createdAt.toString().split(' ')[0]}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e, stackTrace) {
      print('Error in _buildCurrentClassCard: $e');
      print('Stack trace: $stackTrace');
      return Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Error displaying class',
                style: TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 8),
              Text('Error: $e', style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _refreshClasses,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
  }

  String _formatTime(DateTime dateTime) {
    try {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '--:--';
    }
  }

  Widget _buildClassList(List<ClassModel> classes) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: classes.length,
      itemBuilder: (context, index) {
        final classData = classes[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ClassAttendanceScreen(classData: classData),
                ),
              );
            },
            title: Text(classData.className),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(classData.subject),
                Text(
                  '${_formatTime(classData.startTime)} - ${_formatTime(classData.endTime)}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: classData.classStatus == 'Active'
                        ? Colors.green.withOpacity(0.1)
                        : classData.classStatus == 'Upcoming'
                        ? Colors.orange.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: classData.classStatus == 'Active'
                          ? Colors.green
                          : classData.classStatus == 'Upcoming'
                          ? Colors.orange
                          : Colors.red,
                    ),
                  ),
                  child: Text(
                    classData.classStatus,
                    style: TextStyle(
                      fontSize: 12,
                      color: classData.classStatus == 'Active'
                          ? Colors.green
                          : classData.classStatus == 'Upcoming'
                          ? Colors.orange
                          : Colors.red,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${classData.attendedStudentIds.length} students',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<FirebaseAuthProvider>(
      context,
      listen: false,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Faculty Dashboard'),
        actions: [
          IconButton(
            onPressed: _refreshClasses,
            icon: const Icon(Icons.refresh, size: 24),
          ),
          IconButton(
            onPressed: () async {
              try {
                await authProvider.signOut();
                if (!mounted) return;

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              } catch (e) {
                _showError('Failed to sign out. Please try again.');
              }
            },
            icon: const Icon(Icons.logout, size: 24),
          ),
        ],
      ),
      body: Consumer<ClassesProvider>(
        builder: (context, classesProvider, child) {
          print(
            'Consumer rebuilding. Loading: ${classesProvider.isLoading}, Error: ${classesProvider.error}',
          );

          if (classesProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (classesProvider.error != null) {
            print('Error from provider: ${classesProvider.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      classesProvider.error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _refreshClasses,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final classes = classesProvider.classes;
          print('Number of classes from provider: ${classes.length}');

          if (classes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'No classes created yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final facultyDoc = await FirebaseFirestore.instance
                          .collection('faculty')
                          .doc(authProvider.user?.uid)
                          .get();
                      final facultyName = facultyDoc.data()?['name'] as String?;

                      if (!mounted) return;

                      if (facultyName != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddClassScreen(),
                          ),
                        ).then(
                          (_) => _refreshClasses(),
                        ); // Refresh after adding a class
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create Your First Class'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              _refreshClasses();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildCurrentClassCard(classes),
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'All Classes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                  ),
                  _buildClassList(classes),
                ],
              ),
            ),
          );
        },
      ),

      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 10.0,
        child: BottomNavigationBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          currentIndex: currentIndex,
          onTap: (index) {
            setState(() {
              currentIndex = index;
            });
          },
          iconSize: 24,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Dashboard'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        shape: const CircleBorder(),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddClassScreen()),
          );
          final facultyDoc = await FirebaseFirestore.instance
              .collection('faculty')
              .doc(authProvider.user?.uid)
              .get();
          final facultyName = facultyDoc.data()?['name'] as String?;

          if (!mounted) return;

          if (facultyName != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddClassScreen()),
            ).then((_) => _refreshClasses()); // Refresh after adding a class
          }
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
