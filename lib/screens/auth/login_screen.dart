import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_attendance_system/features/authentication/firabse_auth_servise.dart';
import 'package:qr_attendance_system/screens/faculty/facilty_dashboard.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<FirebaseAuthProvider>(
      context,
      listen: false,
    );
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          spacing: 20,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            ElevatedButton(
              style: ButtonStyle(
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                fixedSize: WidgetStatePropertyAll(
                  Size(MediaQuery.of(context).size.width, 50),
                ),
              ),
              onPressed: () async {
                final email = emailController.text.trim();
                final password = passwordController.text.trim();
                await authProvider.signInWithEmailAndPassword(
                  email: email,
                  password: password,
                );

                if (authProvider.user != null) {
                  if (email.endsWith('@teacher.com')) {
                    Navigator.pushReplacementNamed(
                      context,
                      '/facultyDashboard',
                    );
                  } else if (email.endsWith('@student.com')) {
                    Navigator.pushReplacementNamed(
                      context,
                      '/studentDashboard',
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Invalid email domain')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        authProvider.errorMessage ?? 'Login failed',
                      ),
                    ),
                  );
                }
              },
              child: Text('login'),
            ),
            TextButton(onPressed: () {}, child: Text('Forgot Password?')),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/login'),
              child: const Text.rich(
                TextSpan(
                  text: "if you don't have an account, ",
                  children: [
                    TextSpan(
                      text: "Register now",
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
    );
  }
}
