// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_attendance_system/features/authentication/firabse_auth_servise.dart';
import 'package:qr_attendance_system/screens/admin/admin_dashboard.dart';
import 'package:qr_attendance_system/screens/faculty/faculty_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(8),
      ),
    );
  }

  Future<void> _handleLogin() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    // Basic validation
    if (email.isEmpty || password.isEmpty) {
      _showError('Please enter both email and password');
      return;
    }

    if (!email.contains('@')) {
      _showError('Please enter a valid email address');
      return;
    }

    if (password.length < 6) {
      _showError('Password must be at least 6 characters long');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<FirebaseAuthProvider>(
        context,
        listen: false,
      );

      await authProvider.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      if (authProvider.user != null) {
        if (email.endsWith('@admin.com')) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminDashboard()),
          );
        } else if (email.endsWith('@teacher.com')) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  FacultyDashboard(facultyId: authProvider.user!.uid),
            ),
          );
        } else if (email.endsWith('@student.com')) {
          Navigator.pushReplacementNamed(context, '/studentDashboard');
        } else {
          _showError(
            'Invalid email domain. Please use a valid institutional email.',
          );
        }
      } else {
        _showError(
          authProvider.errorMessage ?? 'Login failed. Please try again.',
        );
      }
    } catch (e) {
      String errorMessage;

      if (e.toString().contains('wrong-password')) {
        errorMessage = 'Incorrect password. Please try again.';
      } else if (e.toString().contains('user-not-found')) {
        errorMessage = 'No account found with this email.';
      } else if (e.toString().contains('invalid-email')) {
        errorMessage = 'Please enter a valid email address.';
      } else if (e.toString().contains('user-disabled')) {
        errorMessage =
            'This account has been disabled. Please contact support.';
      } else if (e.toString().contains('too-many-requests')) {
        errorMessage = 'Too many login attempts. Please try again later.';
      } else if (e.toString().contains('network-request-failed')) {
        errorMessage = 'Network error. Please check your internet connection.';
      } else {
        errorMessage = 'An error occurred. Please try again.';
      }

      _showError(errorMessage);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
              textInputAction: TextInputAction.done,
              enabled: !_isLoading,
              onSubmitted: (_) => _handleLogin(),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ButtonStyle(
                shape: MaterialStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                fixedSize: MaterialStateProperty.all(
                  Size(MediaQuery.of(context).size.width, 50),
                ),
              ),
              onPressed: _isLoading ? null : _handleLogin,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Login'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      // TODO: Implement forgot password functionality
                      _showError('Forgot password functionality coming soon!');
                    },
              child: const Text('Forgot Password?'),
            ),
          ],
        ),
      ),
    );
  }
}
