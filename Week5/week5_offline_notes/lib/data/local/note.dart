class Note {
  const Note({
    this.id,
    required this.title,
    this.body = '',
    required this.updatedAt,
    this.dirty = true,
  });

  final int? id;
  final String title;
  final String body;
  final DateTime updatedAt;
  // dirty = true berarti belum tersinkron ke server
  final bool dirty;

  /// Membuat Note dari Map (baris database SQLite).
  /// Setiap field yang hilang diberi nilai bawaan agar data lama tidak crash.
  factory Note.fromMap(Map<String, dynamic> map) => Note(
        id: map['id'] as int?,
        title: map['title'] as String? ?? '',
        body: map['body'] as String? ?? '',
        updatedAt: map['updated_at'] != null
            ? DateTime.parse(map['updated_at'] as String)
            : DateTime.now(),
        dirty: (map['dirty'] as int? ?? 1) == 1,
      );

  /// Mengubah Note menjadi Map untuk disimpan ke SQLite.
  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'title': title,
        'body': body,
        'updated_at': updatedAt.toIso8601String(),
        'dirty': dirty ? 1 : 0,
      };

  /// Membuat salinan Note dengan sebagian field diubah (immutable pattern).
  Note copyWith({
    int? id,
    String? title,
    String? body,
    DateTime? updatedAt,
    bool? dirty,
  }) =>
      Note(
        id: id ?? this.id,
        title: title ?? this.title,
        body: body ?? this.body,
        updatedAt: updatedAt ?? this.updatedAt,
        dirty: dirty ?? this.dirty,
      );

  @override
  String toString() =>
      'Note(id: $id, title: $title, dirty: $dirty, updatedAt: $updatedAt)';
}
