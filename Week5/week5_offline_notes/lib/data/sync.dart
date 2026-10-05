import '../data/local/note.dart';
import '../data/repositories/note_repository.dart';

/// Exception yang dilempar ketika sinkronisasi ditolak karena offline.
class OfflineException implements Exception {
  const OfflineException(this.message);
  final String message;

  @override
  String toString() => 'OfflineException: $message';
}

/// Menyinkronkan semua catatan dirty ke server (simulasi).
///
/// Parameter [latency] dapat diisi Duration.zero saat testing.
/// Jika [offline] true, fungsi melempar [OfflineException] dan tidak
/// mengubah flag dirty, sehingga antrean tetap utuh untuk dicoba lagi.
Future<int> syncNotes(
  NoteRepository repo, {
  bool offline = false,
  Duration latency = const Duration(seconds: 1),
}) async {
  if (offline) {
    throw const OfflineException('Perangkat offline, sinkronisasi ditunda.');
  }
  final dirtyCount = await repo.countDirty();
  if (dirtyCount == 0) return 0;

  // Simulasi upload. Pada project nyata: kirim tiap catatan dirty
  // ke REST API, lalu tandai bersih HANYA bila server menjawab 2xx.
  await Future.delayed(latency);
  await repo.markAllSynced();
  return dirtyCount;
}

/// Aturan konflik: last-write-wins berdasarkan updatedAt.
Note resolveConflict(Note local, Note remote) {
  return remote.updatedAt.isAfter(local.updatedAt) ? remote : local;
}
