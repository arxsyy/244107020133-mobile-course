import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Membuka (atau membuat) database SQLite aplikasi.
/// Dipanggil oleh repository; bukan oleh UI secara langsung.
Future<Database> openNotesDb() async {
  final dir = await getDatabasesPath();
  final path = p.join(dir, 'offline_notes.db');

  return openDatabase(
    path,
    version: 1,
    onCreate: (db, version) async {
      // Tabel catatan pengguna
      await db.execute('''
        CREATE TABLE notes (
          id         INTEGER PRIMARY KEY AUTOINCREMENT,
          title      TEXT    NOT NULL DEFAULT '',
          body       TEXT    NOT NULL DEFAULT '',
          updated_at TEXT    NOT NULL,
          dirty      INTEGER NOT NULL DEFAULT 1
        )
      ''');

      // Tabel cache data posts dari API (pola cache-first Praktikum 4)
      await db.execute('''
        CREATE TABLE cached_posts (
          id         INTEGER PRIMARY KEY,
          payload    TEXT    NOT NULL,
          cached_at  TEXT    NOT NULL
        )
      ''');
    },
  );
}
