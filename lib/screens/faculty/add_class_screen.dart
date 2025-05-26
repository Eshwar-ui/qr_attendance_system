import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_attendance_system/data/model.dart';
import 'package:uuid/uuid.dart';
import 'package:qr_flutter/qr_flutter.dart';

class AddClassScreen extends StatefulWidget {
  final String facultyId;

  const AddClassScreen({super.key, required this.facultyId});

  @override
  State<AddClassScreen> createState() => _AddClassScreenState();
}

class _AddClassScreenState extends State<AddClassScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _classNameController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();

  String? generatedClassId;

  Future<void> _createClass() async {
    if (!_formKey.currentState!.validate()) return;

    final classId = const Uuid().v4();

    final newClass = ClassModel(
      id: classId,
      className: _classNameController.text.trim(),
      subject: _subjectController.text.trim(),
      facultyId: widget.facultyId,
      createdAt: DateTime.now(),
    );

    await FirebaseFirestore.instance
        .collection('classes')
        .doc(classId)
        .set(newClass.toMap());

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => GeneratedQRScreen(classId: classId)),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Class created and QR generated")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Class & Generate QR")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _classNameController,
                    decoration: const InputDecoration(labelText: "Class Name"),
                    validator: (value) =>
                        value!.isEmpty ? "Enter class name" : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _subjectController,
                    decoration: const InputDecoration(labelText: "Subject"),
                    validator: (value) =>
                        value!.isEmpty ? "Enter subject" : null,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _createClass,
                    icon: const Icon(Icons.qr_code),
                    label: const Text("Create Class & Generate QR"),
                  ),
                ],
              ),
            ),
          ],
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
            const Text("Scan this QR to mark attendance"),
            const SizedBox(height: 16),
            QrImageView(data: classId, version: QrVersions.auto, size: 250),
            const SizedBox(height: 12),
            Text("Class ID: $classId"),
          ],
        ),
      ),
    );
  }
}
