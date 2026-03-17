// screens/register.dart
import 'package:flutter/material.dart';
import '../services/api.dart';

// FIX: Was StatelessWidget with TextEditingControllers — that causes memory leaks
// because controllers are never disposed. Converted to StatefulWidget.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key}); // FIX: added super.key

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    // FIX: Controllers are now properly disposed — no memory leak
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _register() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final data = await register(email, password);

    // FIX: mounted check is mandatory after any await before touching context
    if (!mounted) return;

    setState(() => _isLoading = false);

    // FIX: was calling SnackBar AFTER Navigator.pop() — the widget was already
    // removed from the tree so context was invalid. Now we show the snackbar
    // FIRST, then pop.
    if (data['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration successful! Please log in.'),
        ),
      );
      Navigator.pop(context);
    } else {
      // FIX: added error handling for failed registration
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${data['error'] ?? 'Registration failed'}'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')), // FIX: added const
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _register,
                    child: const Text('Register'),
                  ),
          ],
        ),
      ),
    );
  }
}