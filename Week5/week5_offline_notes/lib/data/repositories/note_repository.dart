import 'package:sqflite/sqflite.dart';

import '../local/db.dart';
import '../local/note.dart';

class NoteRepository {
  NoteRepository({Future<Database> Function()? openDb})
      : _openDb = openDb ?? openNotesDb;

  final Future<Database> Function() _openDb;

  /// Mengambil semua catatan, diurutkan dari yang terbaru.
  Future<List<Note>> fetchNotes() async {
    final db = await _openDb();
    final rows = await db.query('notes', orderBy: 'updated_at DESC');
    return rows.map(Note.fromMap).toList();
  }

  /// Menyimpan catatan baru (dirty = 1 secara bawaan).
  Future<int> insertNote(Note note) async {
    final db = await _openDb();
    return db.insert('notes', note.toMap());
  }

  /// Memperbarui catatan yang ada; selalu set dirty = 1 dan updated_at terbaru.
  Future<void> updateNote(Note note) async {
    final db = await _openDb();
    await db.update(
      'notes',
      note.copyWith(dirty: true, updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  /// Menghapus catatan berdasarkan id.
  Future<void> deleteNote(int id) async {
    final db = await _openDb();
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  /// Menghitung catatan yang belum tersinkron (dirty = 1).
  Future<int> countDirty() async {
    final db = await _openDb();
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM notes WHERE dirty = 1',
    );
    return (result.first['c'] as int?) ?? 0;
  }

  /// Menandai semua catatan sebagai sudah tersinkron (dirty = 0).
  Future<void> markAllSynced() async {
    final db = await _openDb();
    await db.update('notes', {'dirty': 0});
  }
}
