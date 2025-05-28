// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_attendance_system/data/model.dart';

/// A widget that provides a form for student registration.
/// This screen allows administrators to register new students with all their details.
class StudentSignIn extends StatefulWidget {
  const StudentSignIn({super.key});

  @override
  State<StudentSignIn> createState() => _StudentSignInState();
}

class _StudentSignInState extends State<StudentSignIn> {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Text controllers for form fields
  final _nameController = TextEditingController();
  final _rollNumberController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  // Selected values for dropdown fields
  String _selectedBranch = 'CSE';
  String _selectedYear = '1';
  String _selectedSection = 'A';
  String _selectedSemester = '1';

  // Lists of options for dropdown fields
  final List<String> _branches = ['CSE', 'ECE', 'EEE', 'MECH', 'CIVIL'];
  final List<String> _years = ['1', '2', '3', '4'];
  final List<String> _sections = ['A', 'B', 'C', 'D'];
  final List<String> _semesters = ['1', '2', '3', '4', '5', '6', '7', '8'];

  // Loading state for the form
  bool _isLoading = false;

  /// Handles the student registration process.
  /// Creates a new user in Firebase Auth and stores student details in Firestore.
  /// Shows success/error messages and navigates back to management screen on success.
  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Create email from student's name (e.g., johnsmith@student.com)
      final email =
          '${_nameController.text.toLowerCase().replaceAll(' ', '')}@student.com';

      // Create authentication account
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: email,
            password: _passwordController.text,
          );

      // Create student object with all details
      final student = Student(
        id: userCredential.user!.uid,
        name: _nameController.text.trim(),
        email: email,
        rollNumber: _rollNumberController.text.trim(),
        branch: _selectedBranch,
        year: _selectedYear,
        section: _selectedSection,
        semester: _selectedSemester,
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
      );

      // Store student data in Firestore
      await FirebaseFirestore.instance
          .collection('students')
          .doc(userCredential.user!.uid)
          .set(student.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created successfully!')),
        );
        Navigator.pop(context); // Return to student management screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Builds a reusable form input field with consistent styling and validation.
  ///
  /// Parameters:
  /// - controller: Controls the text input
  /// - label: Display label for the field
  /// - icon: Icon shown before the input
  /// - obscureText: Whether to hide the input (for passwords)
  /// - keyboardType: Type of keyboard to show
  /// - maxLines: Maximum number of lines for the input
  Widget _buildInputField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool obscureText = false,
    TextInputType? keyboardType,
    int? maxLines,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        maxLines: maxLines ?? 1,
        validator: (val) =>
            val == null || val.trim().isEmpty ? "Required" : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  /// Builds a reusable dropdown form field with consistent styling.
  ///
  /// Parameters:
  /// - label: Display label for the dropdown
  /// - value: Currently selected value
  /// - items: List of available options
  /// - onChanged: Callback when selection changes
  /// - icon: Icon shown before the dropdown
  Widget _buildDropdownField(
    String label,
    String value,
    List<String> items,
    void Function(String?) onChanged,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: Icon(icon),
        ),
        items: items.map((item) {
          return DropdownMenuItem(value: item, child: Text(item));
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Registration')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Personal Information
              _buildInputField(_nameController, 'Full Name', Icons.person),
              _buildInputField(
                _rollNumberController,
                'Roll Number',
                Icons.badge,
              ),
              _buildInputField(
                _phoneController,
                'Phone Number',
                Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              _buildInputField(
                _addressController,
                'Address',
                Icons.location_on,
                maxLines: 3,
              ),

              // Academic Information
              _buildDropdownField(
                'Branch',
                _selectedBranch,
                _branches,
                (value) => setState(() => _selectedBranch = value!),
                Icons.school,
              ),
              Row(
                children: [
                  Expanded(
                    child: _buildDropdownField(
                      'Year',
                      _selectedYear,
                      _years,
                      (value) => setState(() => _selectedYear = value!),
                      Icons.calendar_today,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDropdownField(
                      'Section',
                      _selectedSection,
                      _sections,
                      (value) => setState(() => _selectedSection = value!),
                      Icons.group,
                    ),
                  ),
                ],
              ),
              _buildDropdownField(
                'Semester',
                _selectedSemester,
                _semesters,
                (value) => setState(() => _selectedSemester = value!),
                Icons.schedule,
              ),

              // Authentication
              _buildInputField(
                _passwordController,
                'Password',
                Icons.lock,
                obscureText: true,
              ),

              // Submit Button
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _signUp,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Register Student',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Cleans up resources when the widget is disposed
  @override
  void dispose() {
    _nameController.dispose();
    _rollNumberController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
