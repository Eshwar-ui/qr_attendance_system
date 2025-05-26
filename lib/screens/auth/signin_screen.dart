import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FacultyRegisterScreen extends StatefulWidget {
  const FacultyRegisterScreen({super.key});

  @override
  State<FacultyRegisterScreen> createState() => _FacultyRegisterScreenState();
}

class _FacultyRegisterScreenState extends State<FacultyRegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final staffIdController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final regCodeController = TextEditingController();

  bool isLoading = false;

  Future<void> registerFaculty() async {
    if (!_formKey.currentState!.validate()) return;

    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
      return;
    }

    const allowedRegCode = "TEACHER2024"; // ✅ Hardcoded valid registration code

    final enteredRegCode = regCodeController.text.trim();

    if (enteredRegCode != allowedRegCode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid registration code")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      await FirebaseFirestore.instance
          .collection('faculty')
          .doc(credential.user!.uid)
          .set({
            'uid': credential.user!.uid,
            'name': nameController.text.trim(),
            'staffId': staffIdController.text.trim(),
            'phone': phoneController.text.trim(),
            'email': emailController.text.trim(),
            'regCode': enteredRegCode,
            'createdAt': FieldValue.serverTimestamp(),
          });

      Navigator.pushReplacementNamed(context, '/facultyDashboard');

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Registration successful!")));
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Registration failed")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget _buildInputField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: (val) =>
            val == null || val.trim().isEmpty ? "Required" : null,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Text(
                  "FACULTY REGISTRATION",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(height: 30),

                _buildInputField(nameController, "Full Name", Icons.person),
                _buildInputField(staffIdController, "Staff ID", Icons.badge),
                _buildInputField(
                  phoneController,
                  "Phone Number",
                  Icons.phone,
                  keyboardType: TextInputType.phone,
                ),
                _buildInputField(
                  emailController,
                  "Email ID",
                  Icons.email,
                  keyboardType: TextInputType.emailAddress,
                ),
                _buildInputField(
                  passwordController,
                  "Create Password",
                  Icons.lock,
                  obscureText: true,
                ),
                _buildInputField(
                  confirmPasswordController,
                  "Confirm Password",
                  Icons.lock,
                  obscureText: true,
                ),
                _buildInputField(
                  regCodeController,
                  "Registration Code",
                  Icons.code,
                ),

                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: isLoading ? null : registerFaculty,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 16,
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("REGISTER", style: TextStyle(fontSize: 16)),
                ),

                const SizedBox(height: 12),
                TextButton(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, '/login'),
                  child: const Text.rich(
                    TextSpan(
                      text: "Already registered? ",
                      children: [
                        TextSpan(
                          text: "Login now",
                          style: TextStyle(
                            color: Colors.purple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
