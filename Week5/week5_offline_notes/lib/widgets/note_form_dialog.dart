import 'package:flutter/material.dart';

class NoteFormDialog extends StatefulWidget {
  const NoteFormDialog({super.key, this.initialTitle = '', this.initialBody = ''});

  final String initialTitle;
  final String initialBody;

  @override
  State<NoteFormDialog> createState() => _NoteFormDialogState();
}

class _NoteFormDialogState extends State<NoteFormDialog> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _bodyCtrl;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.initialTitle);
    _bodyCtrl = TextEditingController(text: widget.initialBody);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialTitle.isEmpty ? 'Catatan baru' : 'Edit catatan'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: 'Judul'),
            autofocus: true,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _bodyCtrl,
            decoration: const InputDecoration(labelText: 'Isi'),
            maxLines: 4,
            textInputAction: TextInputAction.done,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () {
            final title = _titleCtrl.text.trim();
            if (title.isEmpty) return;
            // Kembalikan hasil sebagai record Dart 3
            Navigator.of(context).pop((
              title: title,
              body: _bodyCtrl.text.trim(),
            ));
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
