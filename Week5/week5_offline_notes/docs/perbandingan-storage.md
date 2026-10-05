# Tabel Perbandingan Storage

Berikut adalah tabel perbandingan Storage lokal (SharedPreferences vs Hive vs sqflite vs Drift) yang telah dikomparasi menggunakan AI Prompting serta diverifikasi secara mandiri berdasarkan arsitektur aplikasi *Offline Notes*.

| Kriteria | SharedPreferences | Hive | sqflite | Drift |
|---|---|---|---|---|
| Kompleksitas query | Sangat rendah (key-value primitif murni) | Rendah (bukan SQL, iterasi manual/filter) | Tinggi (bisa kueri SQL kompleks, JOIN, ORDER BY) | Sangat tinggi (builder Dart *type-safe* ke SQL) |
| Dukungan relasi | Tidak ada | Terbatas (`HiveList`/referensi object IDs) | Kuat (Relasional tabel asli, Foreign Key) | Kuat (sama seperti SQLite + model mapping) |
| Reaktivitas (stream) | Tidak bawaan | Ya (bisa listen ke Box) | Tidak bawaan (butuh manual atau lib eksternal) | Ya (stream kueri reaktif dari abstraksi SQLite) |
| Type-safety | Rendah (*string key* dan *primitive types*) | Menengah (`TypeAdapter` objek Dart) | Rendah (Mapping Map manual `toMap/fromMap`) | Sangat Tinggi (di-*generate* otomatis) |
| Ukuran boilerplate| Sangat kecil | Sedang (kelas konverter manual) | Sedang (string SQL dasar) | Sangat besar (build_runner, *class generator*) |
| Kemudahan testing | Mudah (*Mock* global instance) | Sedang (*in-memory db*) | Sedang (butuh *Fake factory* khusus) | Spesifik library test bawaan |
| Cocok untuk Preferensi? | **Sangat cocok** | Cocok, tapi sedikit *Overkill* | Kurang cocok & Berat | Tidak Relevan |
| Cocok 1000+ Catatan? | **Sangat tidak cocok** | Sangat cocok (Kencang memanggil I/O) | **Sangat cocok** | Sangat Cocok (apalagi jika relasional tebal) |
| **Keputusan Final** | **Pilih SharedPreferences** | - | **Pilih sqflite** | - |

**Keputusan & Alasan:**
**SharedPreferences** sangat tepat dan efisien untuk menyimpan preferensi aplikasi semacam setelan *Dark Mode* dan riwayat sesi aplikasi karena ia dirancang untuk nilai dasar (primitif) dengan bobot ukuran kecil. Namun bagi penyimpanan data "Catatan" yang berjumlah banyak secara kolektif, disarankan mengandalkan **sqflite**. Relasional database *sqflite* menawarkan fungsionalitas mumpuni untuk pencarian *(filtering)* spesifik semisal `WHERE dirty = 1`, pengurutan tanggal terbaru (`ORDER BY updated_at DESC`), serta integritas pembaruan parsial yang tak dimiliki *SharedPreferences*.
