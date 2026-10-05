import 'package:flutter/material.dart';
import '../data/local/note.dart';

class NoteTile extends StatelessWidget {
  const NoteTile({
    super.key,
    required this.note,
    required this.onTap,
    required this.onDelete,
  });

  final Note note;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(note.title),
      subtitle: note.body.isNotEmpty ? Text(note.body, maxLines: 2) : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Badge "belum tersinkron" bila note.dirty
          if (note.dirty)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Chip(
                label: const Text('belum tersinkron'),
                backgroundColor: Colors.orange.shade100,
                labelStyle: const TextStyle(fontSize: 10, color: Colors.black87),
                visualDensity: VisualDensity.compact,
              ),
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Hapus',
            onPressed: onDelete,
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}

