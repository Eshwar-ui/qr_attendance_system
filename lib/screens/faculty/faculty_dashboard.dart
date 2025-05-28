// ignore_for_file: avoid_print, deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_attendance_system/screens/faculty/faculty_profile.dart';
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
  int _currentIndex = 0;
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
      final now = DateTime.now();
      print('Current time: $now');

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

      return Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.8),
              Theme.of(context).primaryColor,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).primaryColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
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
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isActive ? 'Active Class' : 'Upcoming Class',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: statusColor.withOpacity(0.5),
                          ),
                        ),
                        child: Text(
                          currentClass.classStatus,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    currentClass.className,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentClass.subject,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time,
                          color: Colors.white.withOpacity(0.9),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_formatTime(currentClass.startTime)} - ${_formatTime(currentClass.endTime)}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (isActive)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            QrImageView(
                              data: currentClass.id,
                              version: QrVersions.auto,
                              size: 200,
                              backgroundColor: Colors.white,
                              errorStateBuilder: (context, error) =>
                                  const Center(
                                    child: Text(
                                      'Error generating QR code',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Scan to mark attendance',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.people,
                                    size: 16,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${currentClass.attendedStudentIds.length} students present',
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 48,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Class starts at ${_formatTime(currentClass.startTime)}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'QR code will be available when class starts',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
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
        final statusColor = classData.classStatus == 'Active'
            ? Colors.green
            : classData.classStatus == 'Upcoming'
            ? Colors.orange
            : Colors.red;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ClassAttendanceScreen(classData: classData),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.class_,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              classData.className,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              classData.subject,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: statusColor),
                        ),
                        child: Text(
                          classData.classStatus,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_formatTime(classData.startTime)} - ${_formatTime(classData.endTime)}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.people,
                              size: 16,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${classData.attendedStudentIds.length}',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return Consumer<ClassesProvider>(
          builder: (context, classesProvider, child) {
            if (classesProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (classesProvider.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
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
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddClassScreen(),
                        ),
                      ).then((_) => _refreshClasses()),
                      icon: const Icon(Icons.add),
                      label: const Text('Create Your First Class'),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async => _refreshClasses(),
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
        );
      case 1:
        return const FacultyProfileScreen();
      default:
        return const Center(child: Text('Unknown page'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<FirebaseAuthProvider>(
      context,
      listen: false,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentIndex == 0 ? 'Faculty Dashboard' : 'Faculty Profile',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (_currentIndex == 0)
            IconButton(
              onPressed: () async {
                try {
                  await authProvider.signOut();
                  if (!mounted) return;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                } catch (e) {
                  _showError('Failed to sign out. Please try again.');
                }
              },
              icon: const Icon(Icons.logout, size: 24),
            ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: Container(
        height: 70,
        decoration: BoxDecoration(color: Colors.transparent),
        child: BottomAppBar(
          color: Theme.of(context).primaryColor,
          shape: const CircularNotchedRectangle(),
          notchMargin: 10.0,
          elevation: 8,
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: Colors.transparent,
              // gradient: LinearGradient(
              //   colors: [
              //     Theme.of(context).primaryColor.withOpacity(0.8),
              //     Theme.of(context).primaryColor,
              //   ],
              //   begin: Alignment.topLeft,
              //   end: Alignment.bottomRight,
              // ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home, 'Dashboard'),
                _buildNavItem(1, Icons.person, 'Profile'),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              shape: const CircleBorder(),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddClassScreen()),
              ).then((_) => _refreshClasses()),
              elevation: 4,
              child: const Icon(Icons.add),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : Colors.white.withOpacity(0.7),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
