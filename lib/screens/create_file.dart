// screens/create_file.dart
import 'package:flutter/material.dart';
import '../services/api.dart';

class CreateFileScreen extends StatefulWidget {
  final int userId;

  // FIX: Added super.key — StatefulWidget was missing it
  const CreateFileScreen(this.userId, {super.key});

  @override
  State<CreateFileScreen> createState() => _CreateFileScreenState();
}

class _CreateFileScreenState extends State<CreateFileScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _createFile() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = await createFile(
        _titleController.text,
        _contentController.text,
        widget.userId,
      );

      // FIX: mounted check before using BuildContext after any await —
      // the widget may have been disposed while the network call was in flight
      if (!mounted) return;

      setState(() => _isLoading = false);

      if (data['success'] == true) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Access Code'),
            content: Text(data['code'] as String? ?? 'No code returned'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${data['error'] ?? 'Unknown error'}'),
          ),
        );
      }
    } catch (e) {
      // FIX: same mounted guard in the catch block
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exception: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create File')), // FIX: added const
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(labelText: 'Content'),
              maxLines: 5,
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _createFile,
                    child: const Text('Create'),
                  ),
          ],
        ),
      ),
    );
  }
}