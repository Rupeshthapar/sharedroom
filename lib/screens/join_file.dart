// screens/join_file.dart
import 'package:flutter/material.dart';
import '../services/api.dart';
import 'view_file.dart';

// FIX: Was StatelessWidget with a TextEditingController — memory leak because
// the controller is never disposed. Converted to StatefulWidget.
class JoinFileScreen extends StatefulWidget {
  const JoinFileScreen({super.key}); // FIX: added super.key

  @override
  State<JoinFileScreen> createState() => _JoinFileScreenState();
}

class _JoinFileScreenState extends State<JoinFileScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    // FIX: controller is now properly disposed
    _codeController.dispose();
    super.dispose();
  }

  void _join() async {
    final code = _codeController.text.trim();

    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an access code.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final data = await joinFile(code);

    // FIX: mounted check after every await
    if (!mounted) return;

    setState(() => _isLoading = false);

    // FIX: was navigating blindly regardless of API result.
    // Now checks success flag before navigating; shows error on failure.
    if (data['success'] == true) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ViewFile(data)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${data['error'] ?? 'Invalid code or file not found'}'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join File')), // FIX: added const
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(labelText: 'Enter Access Code'),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 20),
            // FIX: added loading indicator — was missing entirely
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _join,
                    child: const Text('Join'),
                  ),
          ],
        ),
      ),
    );
  }
}