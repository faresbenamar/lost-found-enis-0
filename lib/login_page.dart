import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  String? error;

  Future<void> login() async {
    final email = emailController.text.trim();
    if (!email.endsWith('@enis.tn')) {
      setState(() => error = 'Email must end with @enis.tn');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userEmail', email);

    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lost & Found ENIS')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Enter your ENIS email to continue',
                style: TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'ENIS Email',
                hintText: 'example@enis.tn',
                border: OutlineInputBorder(),
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: login,
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}