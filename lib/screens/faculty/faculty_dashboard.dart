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

class FacultyDashboard extends StatefulWidget {
  final String? facultyId;
  const FacultyDashboard({super.key, this.facultyId});

  @override
  State<FacultyDashboard> createState() => _FacultyDashboardState();
}

class _FacultyDashboardState extends State<FacultyDashboard>
    with WidgetsBindingObserver {
  int currentIndex = 0;
  StreamSubscription<QuerySnapshot>? _classesSubscription;
  List<ClassModel> _classes = [];
  bool _isLoading = true;
  String? _error;
  String? _facultyId;
  Timer? _refreshTimer;
  bool _isDisposed = false;

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
    _classesSubscription?.cancel();
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
      setState(() {
        _isLoading = true;
        _error = null;
      });

      await Future.delayed(
        const Duration(milliseconds: 100),
      ); // Give time for widget to fully mount

      if (!mounted) return;

      final authProvider = Provider.of<FirebaseAuthProvider>(
        context,
        listen: false,
      );

      _facultyId = widget.facultyId ?? authProvider.user?.uid;

      if (_facultyId == null || _facultyId!.isEmpty) {
        if (mounted) {
          setState(() {
            _error = 'Unable to identify faculty. Please try logging in again.';
            _isLoading = false;
          });
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
        _subscribeToClasses();
      }
    } catch (e) {
      print('Initialization error: $e');
      if (!_isDisposed && mounted) {
        setState(() {
          _error = 'Failed to initialize. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  void _refreshClasses() {
    if (_isDisposed || !mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Add slight delay to prevent rapid refreshes
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!_isDisposed) {
        _subscribeToClasses();
      }
    });
  }

  void _subscribeToClasses() {
    if (_isDisposed || !mounted) return;

    try {
      _classesSubscription?.cancel();

      if (_facultyId == null || _facultyId!.isEmpty) {
        setState(() {
          _error = 'Unable to identify faculty. Please try logging in again.';
          _isLoading = false;
        });
        return;
      }

      // Query classes created by this faculty
      final query = FirebaseFirestore.instance
          .collection('classes')
          .where('createdBy', isEqualTo: _facultyId)
          .orderBy('createdAt', descending: true);

      _classesSubscription = query.snapshots().listen(
        (snapshot) {
          if (_isDisposed || !mounted) return;

          try {
            final classes = snapshot.docs.map((doc) {
              final data = doc.data();
              return ClassModel.fromMap(data, doc.id);
            }).toList();

            if (mounted) {
              setState(() {
                _classes = classes;
                _isLoading = false;
                _error = null;
              });
            }
          } catch (e) {
            print('Error processing classes: $e');
            if (mounted) {
              setState(() {
                _error = 'Error loading class data. Please try again.';
                _isLoading = false;
              });
            }
          }
        },
        onError: (error) {
          print('Firestore subscription error: $error');
          if (_isDisposed || !mounted) return;

          String errorMessage;
          if (error.toString().contains('permission-denied')) {
            errorMessage = 'Access denied. Please verify your credentials.';
          } else if (error.toString().contains('unavailable')) {
            errorMessage = 'Network error. Please check your connection.';
          } else {
            errorMessage = 'Failed to load classes. Please try again.';
          }

          if (mounted) {
            setState(() {
              _error = errorMessage;
              _isLoading = false;
            });
          }
        },
        cancelOnError: true,
      );
    } catch (e) {
      print('Subscription setup error: $e');
      if (_isDisposed || !mounted) return;

      setState(() {
        _error = 'Failed to load classes. Please try again.';
        _isLoading = false;
      });
    }
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

  Widget _buildCurrentClassCard(ClassModel classData) {
    if (_isDisposed) return const SizedBox.shrink();

    try {
      final bool isUpcoming = classData.status == 'Upcoming';
      final bool isActive = classData.status == 'Active';

      if (!isActive && !isUpcoming) {
        return const SizedBox.shrink();
      }

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
                      ClassAttendanceScreen(classData: classData),
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
                        classData.status,
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
                  classData.className,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  classData.subject,
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.access_time, color: Colors.grey[600], size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${_formatTime(classData.startTime)} - ${_formatTime(classData.endTime)}',
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
                      data: classData.id,
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
                          'Class starts at ${_formatTime(classData.startTime)}',
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
                        '${classData.attendedStudentIds.length} students present',
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
                  'Created on ${classData.createdAt.toString().split(' ')[0]}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
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
                    color: classData.status == 'Active'
                        ? Colors.green.withOpacity(0.1)
                        : classData.status == 'Upcoming'
                        ? Colors.orange.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: classData.status == 'Active'
                          ? Colors.green
                          : classData.status == 'Upcoming'
                          ? Colors.orange
                          : Colors.red,
                    ),
                  ),
                  child: Text(
                    classData.status,
                    style: TextStyle(
                      fontSize: 12,
                      color: classData.status == 'Active'
                          ? Colors.green
                          : classData.status == 'Upcoming'
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      _error!,
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
            )
          : _classes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'No classes created yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AddClassScreen(facultyId: _facultyId!),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create Your First Class'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                _refreshClasses();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_classes.isNotEmpty) ...[
                      _buildCurrentClassCard(_classes[0]),
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
                      _buildClassList(_classes),
                    ],
                  ],
                ),
              ),
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
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddClassScreen(facultyId: _facultyId!),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
