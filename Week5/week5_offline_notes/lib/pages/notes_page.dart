import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/local/note.dart';
import '../data/sync.dart';
import '../providers/note_providers.dart';
import '../pages/posts_page.dart';
import '../pages/settings_page.dart';
import '../widgets/note_form_dialog.dart';
import '../widgets/note_tile.dart';

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
            tooltip: 'Posts (cache-first)',
            icon: const Icon(Icons.article_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PostsPage()),
            ),
          ),
          IconButton(
            tooltip: 'Sinkronkan',
            icon: const Icon(Icons.sync),
            onPressed: () async {
              // Ambil messenger sebelum await agar tidak pakai BuildContext async
              final messenger = ScaffoldMessenger.of(context);
              try {
                final count = await ref.read(noteActionsProvider).sync();
                messenger.showSnackBar(SnackBar(
                  content: Text(count == 0
                      ? 'Semua catatan sudah tersinkron'
                      : '$count catatan berhasil disinkronkan'),
                ));
              } on OfflineException catch (e) {
                messenger.showSnackBar(SnackBar(content: Text(e.message)));
              }
            },
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
            : ListView.separated(
                itemCount: notes.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final note = notes[index];
                  return NoteTile(
                    note: note,
                    onTap: () => context.push('/note/${note.id}'),
                    onDelete: () => _confirmDelete(context, actions, note),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context, actions),
        tooltip: 'Tambah catatan',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showForm(BuildContext context, NoteActions actions) async {
    final result = await showDialog<({String title, String body})>(
      context: context,
      builder: (_) => const NoteFormDialog(
        initialTitle: '',
        initialBody: '',
      ),
    );
    if (result == null) return;
    await actions.add(result.title, result.body);
  }

  Future<void> _confirmDelete(BuildContext context, NoteActions actions, Note note) async {
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
