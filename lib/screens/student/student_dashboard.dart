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

  Widget _buildAttendanceCard(double percentage, int attended, int total) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.8),
              Theme.of(context).primaryColor,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Attendance Overview',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$percentage%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: percentage / 100,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Classes Attended',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$attended/$total',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                _buildAttendanceStatus(percentage),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceStatus(double percentage) {
    String status;
    Color color;
    IconData icon;

    if (percentage >= 75) {
      status = 'Excellent';
      color = Colors.green;
      icon = Icons.check_circle;
    } else if (percentage >= 60) {
      status = 'Average';
      color = Colors.orange;
      icon = Icons.warning;
    } else {
      status = 'Poor';
      color = Colors.red;
      icon = Icons.error;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Text(
            status,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassList(List<QueryDocumentSnapshot> classes) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: classes.length,
      itemBuilder: (context, index) {
        final classData = classes[index].data() as Map<String, dynamic>;
        final startTime = DateTime.parse(classData['startTime']);
        final endTime = DateTime.parse(classData['endTime']);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.class_,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
            ),
            title: Text(
              classData['className'],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  classData['subject'],
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.schedule, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      '${DateFormat('MMM d, y').format(startTime)} • ${DateFormat('h:mm a').format(startTime)} - ${DateFormat('h:mm a').format(endTime)}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'By ${classData['facultyName']}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green),
                  ),
                  child: const Text(
                    'Attended',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
    final studentId = authProvider.user?.uid ?? '';

    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('students')
            .doc(studentId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    style: TextStyle(color: Colors.red.shade400),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
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
              final percentage = totalClasses > 0
                  ? (attendedClasses.length / totalClasses * 100)
                  : 0.0;

              return RefreshIndicator(
                onRefresh: () async {
                  setState(() {});
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: _buildAttendanceCard(
                          double.parse(percentage.toStringAsFixed(1)),
                          attendedClasses.length,
                          totalClasses,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Attended Classes',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_isScanning) ...[
                        SizedBox(
                          height: 300,
                          child: _scannerController == null
                              ? const Center(child: CircularProgressIndicator())
                              : _buildScannerWidget(),
                        ),
                      ],
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.5,
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
                                  mainAxisAlignment: MainAxisAlignment.center,
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
                                    const SizedBox(height: 8),
                                    Text(
                                      'Scan QR code to mark your attendance',
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return _buildClassList(classes);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildScannerWidget() {
    return Stack(
      children: [
        MobileScanner(
          controller: _scannerController!,
          onDetect: (capture) {
            if (!mounted || !_isScanning) return;
            final List<Barcode> barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              final value = barcode.rawValue;
              if (value != null && value.isNotEmpty) {
                _stopScanning();
                _handleQRCode(value);
                break;
              }
            }
          },
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).primaryColor, width: 2),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            color: Colors.black54,
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Scan QR Code',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.flip_camera_android,
                    color: Colors.white,
                  ),
                  onPressed: () => _scannerController?.switchCamera(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
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
