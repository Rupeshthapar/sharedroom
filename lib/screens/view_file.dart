// screens/view_file.dart
import 'package:flutter/material.dart';

class ViewFile extends StatelessWidget {
  final Map<String, dynamic> data;

  // FIX: Added super.key — was missing entirely, breaks widget identity tracking
  const ViewFile(this.data, {super.key});

  @override
  Widget build(BuildContext context) {
    // FIX: Added null-safe fallbacks — the API could omit any of these fields
    // and the original code would throw a null cast exception at runtime.
    final title = data['title'] as String? ?? 'Untitled';
    final content = data['content'] as String? ?? 'No content';
    final ownerId = data['owner_id']?.toString() ?? 'Unknown';

    return Scaffold(
      appBar: AppBar(title: const Text('View File')), // FIX: added const
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Title: $title',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            Text('Content: $content'),
            const SizedBox(height: 10),
            Text('Owner ID: $ownerId'),
          ],
        ),
      ),
    );
  }
}