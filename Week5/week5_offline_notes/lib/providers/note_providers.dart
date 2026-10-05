import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/note.dart';
import '../data/repositories/note_repository.dart';

/// Provider tunggal untuk instance NoteRepository.
/// Bisa di-override di test dengan FakeNoteRepository.
final noteRepositoryProvider = Provider<NoteRepository>(
  (ref) => NoteRepository(),
);

/// Provider daftar catatan (diurutkan updated_at terbaru).
final notesProvider = AsyncNotifierProvider<NotesNotifier, List<Note>>(
  NotesNotifier.new,
);

class NotesNotifier extends AsyncNotifier<List<Note>> {
  @override
  Future<List<Note>> build() =>
      ref.watch(noteRepositoryProvider).fetchNotes();
}

/// Provider jumlah catatan yang belum tersinkron.
final dirtyCountProvider = AsyncNotifierProvider<DirtyCountNotifier, int>(
  DirtyCountNotifier.new,
);

class DirtyCountNotifier extends AsyncNotifier<int> {
  @override
  Future<int> build() =>
      ref.watch(noteRepositoryProvider).countDirty();
}

/// Satu kelas untuk semua aksi mutasi (tambah, ubah, hapus, sync).
/// Invalidasi provider dilakukan di sini agar widget tidak perlu tahu detailnya.
class NoteActions {
  NoteActions(this._ref, this._repo);

  final Ref _ref;
  final NoteRepository _repo;

  void _refresh() {
    _ref.invalidate(notesProvider);
    _ref.invalidate(dirtyCountProvider);
  }

  Future<void> add(String title, String body) async {
    await _repo.insertNote(
      Note(title: title, body: body, updatedAt: DateTime.now()),
    );
    _refresh();
  }

  Future<void> update(Note note, String title, String body) async {
    await _repo.updateNote(note.copyWith(title: title, body: body));
    _refresh();
  }

  Future<void> delete(int id) async {
    await _repo.deleteNote(id);
    _refresh();
  }
}

final noteActionsProvider = Provider<NoteActions>((ref) {
  final repo = ref.watch(noteRepositoryProvider);
  return NoteActions(ref, repo);
});
