import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_attendance_system/features/authentication/firabse_auth_servise.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'package:qr_attendance_system/data/model.dart';
import 'package:intl/intl.dart';
import 'package:qr_attendance_system/screens/student/student_profile.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard>
    with WidgetsBindingObserver {
  int currentIndex = 0;
  bool _isScanning = false;
  MobileScannerController? _scannerController;
  Timer? _scannerInitTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cleanupScanner();
    _scannerInitTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _cleanupScanner();
    } else if (state == AppLifecycleState.resumed && _isScanning) {
      _reinitializeScanner();
    }
  }

  void _cleanupScanner() {
    _scannerController?.dispose();
    _scannerController = null;
    _scannerInitTimer?.cancel();
    _scannerInitTimer = null;
  }

  void _reinitializeScanner() {
    _cleanupScanner();
    if (!mounted) return;

    // Delay scanner initialization to avoid frame drops
    _scannerInitTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted && _isScanning) {
        _scannerController = MobileScannerController();
        setState(() {});
      }
    });
  }

  Future<void> _startScanning() async {
    final status = await Permission.camera.request();
    if (!mounted) return;

    if (status.isGranted) {
      setState(() {
        _isScanning = true;
      });
      _reinitializeScanner();
    } else {
      _showMessage('Camera permission is required to scan QR codes');
      openAppSettings();
    }
  }

  void _stopScanning() {
    if (!mounted) return;
    setState(() {
      _isScanning = false;
    });
    _cleanupScanner();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<FirebaseAuthProvider>(
      context,
      listen: false,
    );
    final studentId = authProvider.user?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        actions: [
          IconButton(
            onPressed: () {
              authProvider.signOut();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              });
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
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

          final studentData = snapshot.data?.data() as Map<String, dynamic>?;
          final attendedClasses =
              studentData?['attendedClassIds'] as List? ?? [];

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('classes')
                .snapshots(),
            builder: (context, classSnapshot) {
              if (classSnapshot.hasError) {
                return Center(child: Text('Error: ${classSnapshot.error}'));
              }

              if (classSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final totalClasses = classSnapshot.data?.docs.length ?? 0;
              final attendancePercentage = totalClasses > 0
                  ? (attendedClasses.length / totalClasses * 100)
                        .toStringAsFixed(1)
                  : '0';

              return Scaffold(
                body: Column(
                  children: [
                    // Attendance Statistics Card

                    // QR Scanner
                    if (_isScanning)
                      Expanded(
                        child: _scannerController == null
                            ? const Center(child: CircularProgressIndicator())
                            : Stack(
                                // fit: StackFit.expand,
                                children: [
                                  MobileScanner(
                                    controller: _scannerController!,
                                    onDetect: (capture) {
                                      if (!mounted || !_isScanning) return;

                                      final List<Barcode> barcodes =
                                          capture.barcodes;
                                      for (final barcode in barcodes) {
                                        final value = barcode.rawValue;
                                        if (value != null && value.isNotEmpty) {
                                          // Stop scanning before handling the code
                                          _stopScanning();
                                          _handleQRCode(value);
                                          break;
                                        }
                                      }
                                    },
                                    errorBuilder: (context, error, child) {
                                      return Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.error,
                                              color: Colors.red,
                                              size: 48,
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              'Scanner error: ${error.errorCode ?? 'Unknown error'}',
                                              style: const TextStyle(
                                                color: Colors.red,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 16),
                                            ElevatedButton(
                                              onPressed: _reinitializeScanner,
                                              child: const Text('Retry'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                  Positioned(
                                    top: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      color: Colors.black54,
                                      padding: const EdgeInsets.all(16),
                                      child: const Text(
                                        'Scan QR Code to mark attendance',
                                        style: TextStyle(color: Colors.white),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 16,
                                    right: 16,
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.flip_camera_android,
                                        color: Colors.white,
                                      ),
                                      onPressed: () =>
                                          _scannerController!.switchCamera(),
                                    ),
                                  ),
                                ],
                              ),
                      ),

                    Card(
                      margin: const EdgeInsets.all(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Attendance',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                Text(
                                  '$attendancePercentage%',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        color: _getAttendanceColor(
                                          double.parse(attendancePercentage),
                                        ),
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: double.parse(attendancePercentage) / 100,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _getAttendanceColor(
                                  double.parse(attendancePercentage),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${attendedClasses.length} of $totalClasses classes attended',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Attended Classes List
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'Attended Classes',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('classes')
                                  .where(
                                    FieldPath.documentId,
                                    whereIn: attendedClasses.isEmpty
                                        ? ['']
                                        : attendedClasses,
                                  )
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.hasError) {
                                  return Center(
                                    child: Text('Error: ${snapshot.error}'),
                                  );
                                }

                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }

                                final classes = snapshot.data?.docs ?? [];

                                if (classes.isEmpty) {
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.class_outlined,
                                          size: 64,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No classes attended yet',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                return ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: classes.length,
                                  itemBuilder: (context, index) {
                                    final classData =
                                        classes[index].data()
                                            as Map<String, dynamic>;
                                    final startTime = DateTime.parse(
                                      classData['startTime'],
                                    );
                                    final endTime = DateTime.parse(
                                      classData['endTime'],
                                    );

                                    return Card(
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withOpacity(0.1),
                                          child: Icon(
                                            Icons.class_,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
                                        ),
                                        title: Text(classData['className']),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(classData['subject']),
                                            Text(
                                              '${DateFormat('MMM d, y').format(startTime)} • ${DateFormat('h:mm a').format(startTime)} - ${DateFormat('h:mm a').format(endTime)}',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                        trailing: Text(
                                          'By ${classData['facultyName']}',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // floatingActionButton: FloatingActionButton(
                //   shape: CircleBorder(),
                //   onPressed: _isScanning ? _stopScanning : _startScanning,
                //   child: Icon(
                //     _isScanning ? Icons.close : Icons.qr_code_scanner,
                //   ),
                // ),
                // floatingActionButtonLocation:
                //     FloatingActionButtonLocation.centerDocked,
              );
            },
          );
        },
      ),
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: _isScanning ? _stopScanning : _startScanning,
      //   icon: Icon(_isScanning ? Icons.close : Icons.qr_code_scanner),
      //   label: Text(_isScanning ? 'Cancel' : 'Scan QR'),
      // ),
      // floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Color _getAttendanceColor(double percentage) {
    if (percentage >= 75) {
      return Colors.green;
    } else if (percentage >= 60) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  Future<void> _handleQRCode(String classId) async {
    if (!mounted) return;

    try {
      final authProvider = Provider.of<FirebaseAuthProvider>(
        context,
        listen: false,
      );
      final studentId = authProvider.user?.uid;

      if (studentId == null) {
        _showMessage('User not authenticated');
        return;
      }

      // First, get class details outside the transaction
      final classDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .get();

      if (!classDoc.exists) {
        _showMessage('Invalid QR Code');
        return;
      }

      final classData = classDoc.data()!;
      final startTime = DateTime.parse(classData['startTime']);
      final endTime = DateTime.parse(classData['endTime']);
      final now = DateTime.now();

      if (now.isBefore(startTime)) {
        _showMessage('Class has not started yet');
        return;
      }

      if (now.isAfter(endTime)) {
        _showMessage('Class has ended');
        return;
      }

      // Check if attendance is already marked before starting transaction
      final existingClassDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .get();

      final existingAttendedStudents = List<String>.from(
        existingClassDoc.data()?['attendedStudentIds'] ?? [],
      );

      if (existingAttendedStudents.contains(studentId)) {
        _showMessage(
          'You have already marked attendance for this class',
          isSuccess: true,
        );
        setState(() {
          _isScanning = false;
        });
        return;
      }

      // Perform the transaction
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // Read operations first
        final classRef = FirebaseFirestore.instance
            .collection('classes')
            .doc(classId);
        final studentRef = FirebaseFirestore.instance
            .collection('students')
            .doc(studentId);

        final classSnapshot = await transaction.get(classRef);
        final studentSnapshot = await transaction.get(studentRef);

        // Validate data after reads
        if (!classSnapshot.exists) {
          throw Exception('Class not found');
        }
        if (!studentSnapshot.exists) {
          throw Exception('Student not found');
        }

        // Get current attendance lists
        final attendedStudents = List<String>.from(
          classSnapshot.data()!['attendedStudentIds'] ?? [],
        );
        final attendedClasses = List<String>.from(
          studentSnapshot.data()!['attendedClassIds'] ?? [],
        );

        // After all reads and validations, perform writes
        attendedStudents.add(studentId);
        if (!attendedClasses.contains(classId)) {
          attendedClasses.add(classId);
        }

        // Perform all writes after reads
        transaction.update(classRef, {'attendedStudentIds': attendedStudents});
        transaction.update(studentRef, {'attendedClassIds': attendedClasses});
      });

      _showMessage('Attendance marked successfully', isSuccess: true);
      setState(() {
        _isScanning = false;
      });
    } catch (e) {
      String errorMessage = e.toString().replaceAll('Exception: ', '');

      if (errorMessage.contains('permission-denied')) {
        errorMessage = 'You do not have permission to mark attendance.';
      } else if (errorMessage.contains('not-found')) {
        errorMessage = 'Class or student record not found.';
      } else if (errorMessage.contains('network')) {
        errorMessage = 'Network error. Please check your connection.';
      }
      _showMessage(errorMessage);
    }
  }

  void _showMessage(
    String message, {
    bool isError = true,
    bool isSuccess = false,
  }) {
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isSuccess
              ? Colors.green
              : (isError ? Colors.red : Colors.blue),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(8),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    });
  }
}
