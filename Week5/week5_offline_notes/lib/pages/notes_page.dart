import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/note.dart';
import '../providers/note_providers.dart';
import '../pages/settings_page.dart';
import '../widgets/note_form_dialog.dart';

class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesProvider);
    final dirtyAsync = ref.watch(dirtyCountProvider);
    final actions = ref.read(noteActionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan Offline'),
        actions: [
          // Badge jumlah catatan dirty
          dirtyAsync.when(
            data: (count) => count > 0
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Chip(
                      label: Text('$count belum sync'),
                      backgroundColor: Colors.orange.shade100,
                      labelStyle:
                          const TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          IconButton(
            tooltip: 'Pengaturan',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
          ),
        ],
      ),
      body: notesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Gagal memuat catatan:\n$e',
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => ref.invalidate(notesProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
        data: (notes) => notes.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.note_add_outlined,
                        size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'Belum ada catatan.\nTekan + untuk menambah.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: notes.length,
                itemBuilder: (context, index) =>
                    _NoteListItem(note: notes[index], actions: actions),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context, actions),
        tooltip: 'Tambah catatan',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showForm(BuildContext context, NoteActions actions,
      [Note? note]) async {
    final result = await showDialog<({String title, String body})>(
      context: context,
      builder: (_) => NoteFormDialog(
        initialTitle: note?.title ?? '',
        initialBody: note?.body ?? '',
      ),
    );
    if (result == null) return;
    if (note == null) {
      await actions.add(result.title, result.body);
    } else {
      await actions.update(note, result.title, result.body);
    }
  }
}

class _NoteListItem extends StatelessWidget {
  const _NoteListItem({required this.note, required this.actions});

  final Note note;
  final NoteActions actions;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(note.title),
      subtitle: note.body.isNotEmpty ? Text(note.body, maxLines: 2) : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Badge dirty
          if (note.dirty)
            const Tooltip(
              message: 'Belum tersinkron ke server',
              child: Icon(Icons.sync_problem, size: 18, color: Colors.orange),
            ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () => _openEdit(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Hapus',
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      onTap: () => _openEdit(context),
    );
  }

  Future<void> _openEdit(BuildContext context) async {
    final result = await showDialog<({String title, String body})>(
      context: context,
      builder: (_) => NoteFormDialog(
        initialTitle: note.title,
        initialBody: note.body,
      ),
    );
    if (result == null) return;
    await actions.update(note, result.title, result.body);
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus catatan?'),
        content: Text('"${note.title}" akan dihapus permanen.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok == true && note.id != null) {
      await actions.delete(note.id!);
    }
  }
}
