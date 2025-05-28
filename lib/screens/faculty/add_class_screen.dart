// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_attendance_system/data/model.dart';
import 'package:qr_attendance_system/features/authentication/firabse_auth_servise.dart';
import 'package:uuid/uuid.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';

class AddClassScreen extends StatefulWidget {
  const AddClassScreen({super.key});

  @override
  State<AddClassScreen> createState() => _AddClassScreenState();
}

class _AddClassScreenState extends State<AddClassScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _classNameController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  bool _isLoading = false;

  DateTime _startTime = DateTime.now();
  DateTime _endTime = DateTime.now().add(const Duration(hours: 1));

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        // Keep the same time but update the date
        _startTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _startTime.hour,
          _startTime.minute,
        );
        _endTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _endTime.hour,
          _endTime.minute,
        );
      });
    }
  }

  Future<void> _selectStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startTime),
    );
    if (picked != null) {
      setState(() {
        _startTime = DateTime(
          _startTime.year,
          _startTime.month,
          _startTime.day,
          picked.hour,
          picked.minute,
        );
        // Ensure end time is after start time
        if (_endTime.isBefore(_startTime)) {
          _endTime = _startTime.add(const Duration(hours: 1));
        }
      });
    }
  }

  Future<void> _selectEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_endTime),
    );
    if (picked != null) {
      final newEndTime = DateTime(
        _endTime.year,
        _endTime.month,
        _endTime.day,
        picked.hour,
        picked.minute,
      );
      if (newEndTime.isBefore(_startTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("End time must be after start time")),
        );
        return;
      }
      setState(() {
        _endTime = newEndTime;
      });
    }
  }

  String _formatTimeOfDay(DateTime dateTime) {
    final time = TimeOfDay.fromDateTime(dateTime);
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
  }

  Future<void> _createClass() async {
    if (_isLoading) return; // Prevent double submission
    if (!_formKey.currentState!.validate()) return;

    if (_endTime.isBefore(_startTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("End time must be after start time")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get faculty name from Firestore using Provider
      final authProvider = Provider.of<FirebaseAuthProvider>(
        context,
        listen: false,
      );
      final facultyDoc = await FirebaseFirestore.instance
          .collection('faculty')
          .doc(authProvider.user?.uid)
          .get();

      final facultyName = facultyDoc.data()?['name'] as String?;
      if (facultyName == null) {
        throw Exception('Faculty name not found');
      }

      final classId = const Uuid().v4();

      final newClass = ClassModel(
        id: classId,
        className: _classNameController.text.trim(),
        subject: _subjectController.text.trim(),
        facultyName: facultyName,
        createdAt: DateTime.now(),
        startTime: _startTime,
        endTime: _endTime,
      );

      await FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .set(newClass.toMap());

      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => GeneratedQRScreen(classId: classId)),
      );

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Class created and QR generated")),
      );
    } catch (e) {
      print('Error creating class: $e'); // Add debug print
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error creating class: $e")));
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Class & Generate QR")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _classNameController,
                      decoration: const InputDecoration(
                        labelText: "Class Name",
                        border: OutlineInputBorder(),
                      ),
                      enabled: !_isLoading,
                      validator: (value) =>
                          value!.isEmpty ? "Enter class name" : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _subjectController,
                      decoration: const InputDecoration(
                        labelText: "Subject",
                        border: OutlineInputBorder(),
                      ),
                      enabled: !_isLoading,
                      validator: (value) =>
                          value!.isEmpty ? "Enter subject" : null,
                    ),
                    const SizedBox(height: 24),
                    ListTile(
                      title: const Text("Date"),
                      subtitle: Text(_formatDate(_startTime)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: _isLoading ? null : _selectDate,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            title: const Text("Start Time"),
                            subtitle: Text(_formatTimeOfDay(_startTime)),
                            trailing: const Icon(Icons.access_time),
                            onTap: _isLoading ? null : _selectStartTime,
                          ),
                        ),
                        Expanded(
                          child: ListTile(
                            title: const Text("End Time"),
                            subtitle: Text(_formatTimeOfDay(_endTime)),
                            trailing: const Icon(Icons.access_time),
                            onTap: _isLoading ? null : _selectEndTime,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _createClass,
                        icon: _isLoading
                            ? Container(
                                width: 24,
                                height: 24,
                                padding: const EdgeInsets.all(2.0),
                                child: const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                            : const Icon(Icons.qr_code),
                        label: Text(
                          _isLoading
                              ? "Creating Class..."
                              : "Create Class & Generate QR",
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.purple.withOpacity(
                            0.6,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GeneratedQRScreen extends StatelessWidget {
  final String classId;

  const GeneratedQRScreen({super.key, required this.classId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("QR Code for Class")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Scan this QR to mark attendance",
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 16),
            QrImageView(data: classId, version: QrVersions.auto, size: 300),
            const SizedBox(height: 12),
            // Text("Class ID: $classId"),
          ],
        ),
      ),
    );
  }
}
