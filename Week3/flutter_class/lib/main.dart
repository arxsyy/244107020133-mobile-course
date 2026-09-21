import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'lirik.dart';
import 'mahasiswa.dart';

void main() {
  runApp(const Marsya());
}

class Marsya extends StatelessWidget {
  const Marsya({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lirik Lagu',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF89664F),
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F3EE),
      ),
      home: const HalamanLirik(),
    );
  }
}

// StatefulWidget menyimpan perubahan tampilan dan input.
class HalamanLirik extends StatefulWidget {
  const HalamanLirik({super.key});

  @override
  State<HalamanLirik> createState() => _HalamanLirikState();
}

class _HalamanLirikState extends State<HalamanLirik> {
  final mahasiswa = Mahasiswa(
    nama: 'Marsya',
    umur: 20,
    kelas: 'TI-3C',
  );

  final _scroll = ScrollController();
  final _form = GlobalKey<FormState>();
  final _catatan = TextEditingController();
  final _namaPlaylist = TextEditingController();

  // Pemutar audio dan pemantau statusnya.
  final _audioPlayer = AudioPlayer();
  StreamSubscription<PlayerState>? _statusAudio;

  bool _sedangPutar = false;
  bool _memuatAudio = false;

  bool _favorit = false;
  bool _tampilLirik = true;
  bool _latihan = false;

  double _ukuran = 16;
  String _perataan = 'Tengah';
  String _suasana = 'Santai';

  DateTime? _tanggal;
  TimeOfDay? _waktu;

  final _urutan = [
    'Baca lirik',
    'Tulis catatan',
    'Latihan bernyanyi',
  ];

  static const foto =
      'https://images.unsplash.com/photo-1516280440614-37939bbacd81?w=800';

  // Gambar sementara ketika FadeInImage memuat foto.
  final _placeholder = MemoryImage(
    base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII=',
    ),
  );

  @override
  void initState() {
    super.initState();

    // Memperbarui ikon saat lagu diputar, dijeda, atau selesai.
    _statusAudio = _audioPlayer.onPlayerStateChanged.listen((status) {
      if (!mounted) return;

      setState(() {
        _sedangPutar = status == PlayerState.playing;
      });
    });
  }

  // Memutar, menjeda, atau melanjutkan lagu.
  Future<void> _putarAtauJeda() async {
    if (_memuatAudio) return;

    setState(() {
      _memuatAudio = true;
    });

    try {
      if (_audioPlayer.state == PlayerState.playing) {
        await _audioPlayer.pause();
      } else if (_audioPlayer.state == PlayerState.paused) {
        await _audioPlayer.resume();
      } else {
        // AssetSource otomatis menggunakan folder assets/.
        await _audioPlayer.play(
          AssetSource('audio/cinta_sudah_lewat.mp3'),
        );
      }
    } catch (error) {
      if (mounted) {
        _pesan(
          'Audio gagal diputar. Periksa file MP3 dan pubspec.yaml.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _memuatAudio = false;
        });
      }
    }
  }

  @override
  void dispose() {
    // Melepas audio dan controller ketika halaman ditutup.
    _statusAudio?.cancel();
    _audioPlayer.dispose();
    _scroll.dispose();
    _catatan.dispose();
    _namaPlaylist.dispose();
    super.dispose();
  }

  // Pesan singkat untuk hasil aksi pengguna.
  void _pesan(String pesan) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(pesan)),
    );
  }

  // Gaya judul yang digunakan pada beberapa bagian.
  Widget _judul(String teks) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(
        teks,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _pilihTanggal() async {
    // Slide 8: DatePicker memilih tanggal.
    final hasil = await showDatePicker(
      context: context,
      initialDate: _tanggal ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (!mounted || hasil == null) return;

    setState(() {
      _tanggal = hasil;
    });
  }

  Future<void> _pilihWaktu() async {
    // Slide 8: TimePicker memilih jam.
    final hasil = await showTimePicker(
      context: context,
      initialTime: _waktu ?? TimeOfDay.now(),
    );

    if (!mounted || hasil == null) return;

    setState(() {
      _waktu = hasil;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Merapikan spasi awal setiap baris lirik.
    final isi = lirik.isi
        .split('\n')
        .map((baris) => baris.trim())
        .join('\n')
        .trim();

    // Scaffold tetap di main.dart.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lirik Lagu'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF7F3EE),
        actions: [
          // Slide 7: PopupMenuButton menampilkan menu.
          PopupMenuButton<String>(
            onSelected: (nilai) {
              if (nilai == 'info') {
                _pesan('${lirik.judul} — ${lirik.penyanyi}');
              } else {
                setState(() {
                  _ukuran = 16;
                  _perataan = 'Tengah';
                  _tampilLirik = true;
                });
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'info',
                child: Text('Info lagu'),
              ),
              PopupMenuItem(
                value: 'reset',
                child: Text('Reset tampilan'),
              ),
            ],
          ),
        ],
      ),

      // Slide 7: Tombol mengambang kembali ke atas.
      floatingActionButton: FloatingActionButton(
        tooltip: 'Kembali ke atas',
        onPressed: () {
          _scroll.animateTo(
            0,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
          );
        },
        child: const Icon(Icons.arrow_upward),
      ),

      body: SafeArea(
        // Slide 10: Scrollbar menunjukkan posisi scroll.
        child: Scrollbar(
          controller: _scroll,
          thumbVisibility: true,

          // Slide 10: Menggulir seluruh isi halaman.
          child: SingleChildScrollView(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 90),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Slide 9: Hero memberi transisi gambar.
                    Hero(
                      tag: 'sampul',

                      // Slide 9: Membulatkan sudut gambar.
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),

                        // Slide 9: Gambar dari internet.
                        child: Image.network(
                          foto,
                          height: 150,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stack) {
                            return Container(
                              height: 150,
                              color: const Color(0xFFEADDD0),
                              child: const Icon(
                                Icons.music_note,
                                size: 54,
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // Slide 7: TextButton membuka detail gambar.
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) => const DetailSampul(),
                          ),
                        );
                      },
                      child: const Text('Lihat sampul'),
                    ),

                    Text(
                      lirik.judul,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF49382E),
                      ),
                    ),
                    const SizedBox(height: 6),

                    Text(
                      lirik.penyanyi,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF816D60),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // TAMBAHAN AUDIO: Tombol putar dan jeda.
                    Center(
                      child: ElevatedButton.icon(
                        onPressed:
                            _memuatAudio ? null : _putarAtauJeda,
                        icon: Icon(
                          _sedangPutar
                              ? Icons.pause
                              : Icons.play_arrow,
                        ),
                        label: Text(
                          _memuatAudio
                              ? 'Memuat...'
                              : (_sedangPutar
                                  ? 'Jeda lagu'
                                  : 'Putar lagu'),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEADDD0),
                          foregroundColor: const Color(0xFF654B3E),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Kotak lirik muncul ketika switch aktif.
                    if (_tampilLirik)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: const Color(0xFFE8DDD3),
                          ),
                        ),
                        child: Text(
                          isi,
                          textAlign: _perataan == 'Tengah'
                              ? TextAlign.center
                              : TextAlign.left,
                          style: TextStyle(
                            fontSize: _ukuran,
                            height: 1.9,
                            color: const Color(0xFF56483F),
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),

                    // Created by tetap di luar kotak lirik.
                    Text(
                      'Created by ${mahasiswa.nama}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF816D60),
                      ),
                    ),

                    // Slide 7: IconButton mengubah favorit.
                    Center(
                      child: IconButton(
                        tooltip:
                            _favorit ? 'Hapus favorit' : 'Tambah favorit',
                        onPressed: () {
                          setState(() {
                            _favorit = !_favorit;
                          });
                        },
                        icon: Icon(
                          _favorit
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: const Color(0xFF9C8070),
                        ),
                      ),
                    ),

                    _judul('Pengaturan membaca'),

                    Row(
                      children: [
                        const Expanded(
                          child: Text('Tampilkan lirik'),
                        ),

                        // Slide 8: Switch mengatur visibilitas lirik.
                        Switch(
                          value: _tampilLirik,
                          onChanged: (nilai) {
                            setState(() {
                              _tampilLirik = nilai;
                            });
                          },
                        ),
                      ],
                    ),

                    Text('Ukuran teks: ${_ukuran.round()}'),

                    // Slide 8: Slider mengatur ukuran teks.
                    Slider(
                      value: _ukuran,
                      min: 14,
                      max: 24,
                      divisions: 10,
                      label: '${_ukuran.round()}',
                      onChanged: (nilai) {
                        setState(() {
                          _ukuran = nilai;
                        });
                      },
                    ),

                    // Slide 8: Radio memilih perataan teks.
                    RadioGroup<String>(
                      groupValue: _perataan,
                      onChanged: (nilai) {
                        if (nilai == null) return;

                        setState(() {
                          _perataan = nilai;
                        });
                      },

                      // Slide 10: Wrap pindah baris jika sempit.
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          for (final pilihan in ['Tengah', 'Kiri'])
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Radio<String>(value: pilihan),
                                Text(pilihan),
                              ],
                            ),
                        ],
                      ),
                    ),

                    // Slide 7: DropdownButton memilih suasana.
                    DropdownButton<String>(
                      value: _suasana,
                      isExpanded: true,
                      items: ['Santai', 'Fokus', 'Nostalgia']
                          .map(
                            (teks) => DropdownMenuItem(
                              value: teks,
                              child: Text(teks),
                            ),
                          )
                          .toList(),
                      onChanged: (nilai) {
                        if (nilai == null) return;

                        setState(() {
                          _suasana = nilai;
                        });
                      },
                    ),

                    Text('Suasana pilihan: $_suasana'),

                    _judul('Catatan & playlist'),

                    // Slide 8: TextField menerima catatan bebas.
                    TextField(
                      controller: _catatan,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Catatan lagu',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Slide 8: Form mengelompokkan input.
                    Form(
                      key: _form,

                      // Slide 8: TextFormField memvalidasi input.
                      child: TextFormField(
                        controller: _namaPlaylist,
                        decoration: const InputDecoration(
                          labelText: 'Nama playlist',
                          border: OutlineInputBorder(),
                        ),
                        validator: (nilai) {
                          if (nilai == null || nilai.trim().isEmpty) {
                            return 'Nama playlist belum diisi';
                          }
                          return null;
                        },
                      ),
                    ),

                    Row(
                      children: [
                        // Slide 8: Checkbox menandai latihan.
                        Checkbox(
                          value: _latihan,
                          onChanged: (nilai) {
                            setState(() {
                              _latihan = nilai ?? false;
                            });
                          },
                        ),
                        const Expanded(
                          child: Text('Tandai untuk latihan'),
                        ),
                      ],
                    ),

                    // Slide 7: ButtonBar menata tombol.
                    // Widget lama ini dipakai sesuai materi slide.
                    ButtonBar(
                      alignment: MainAxisAlignment.start,
                      children: [
                        // Slide 7: ElevatedButton memeriksa catatan.
                        ElevatedButton(
                          onPressed: () {
                            if (_form.currentState!.validate()) {
                              final catatan = _catatan.text.trim();

                              _pesan(
                                'Playlist: ${_namaPlaylist.text.trim()}\n'
                                'Catatan: ${catatan.isEmpty ? "-" : catatan}\n'
                                'Latihan: ${_latihan ? "Ya" : "Tidak"}',
                              );
                            }
                          },
                          child: const Text('Cek catatan'),
                        ),

                        // Slide 7: OutlinedButton membersihkan input.
                        OutlinedButton(
                          onPressed: () {
                            _form.currentState!.reset();
                            _namaPlaylist.clear();
                            _catatan.clear();

                            setState(() {
                              _latihan = false;
                            });
                          },
                          child: const Text('Bersihkan'),
                        ),
                      ],
                    ),

                    Wrap(
                      spacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed: _pilihTanggal,
                          child: const Text('Pilih tanggal'),
                        ),
                        OutlinedButton(
                          onPressed: _pilihWaktu,
                          child: const Text('Pilih jam'),
                        ),
                      ],
                    ),

                    Text(
                      'Tanggal: ${_tanggal == null ? "Belum dipilih" : "${_tanggal!.day}/${_tanggal!.month}/${_tanggal!.year}"}',
                    ),
                    Text(
                      'Jam: ${_waktu == null ? "Belum dipilih" : _waktu!.format(context)}',
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Pilihan hanya berlaku selama aplikasi terbuka.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.brown,
                      ),
                    ),

                    _judul('Profil pembuat'),

                    // Slide 9: Card membungkus informasi profil.
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Slide 9: CircleAvatar menampilkan inisial.
                            CircleAvatar(
                              child: Text(mahasiswa.nama[0]),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '${mahasiswa.nama}\n${mahasiswa.kelas}',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    _judul('Galeri suasana'),

                    // Slide 10: PageView bisa digeser ke samping.
                    SizedBox(
                      height: 160,
                      child: PageView(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),

                            // Slide 9: Transisi fade ketika foto muncul.
                            child: FadeInImage(
                              placeholder: _placeholder,
                              image: const NetworkImage(foto),
                              fit: BoxFit.cover,
                              imageErrorBuilder: (context, error, stack) {
                                return const Center(
                                  child: Icon(
                                    Icons.music_note,
                                    size: 48,
                                  ),
                                );
                              },
                            ),
                          ),
                          const Card(
                            child: Center(
                              child: Text(
                                'Nikmati lagu, baca perlahan.',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Text(
                      'Geser ke samping untuk melihat halaman berikutnya.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12),
                    ),

                    _judul('Informasi lagu'),

                    // Slide 10: ListView menampilkan daftar.
                    ListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        ListTile(
                          leading: const Icon(Icons.music_note),
                          title: Text(lirik.judul),
                        ),
                        ListTile(
                          leading: const Icon(Icons.person),
                          title: Text(lirik.penyanyi),
                        ),
                      ],
                    ),

                    // Slide 10: GridView menyusun dua kolom.
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1.8,
                      children: [
                        Card(
                          child: Center(
                            child: Text(
                              'Suasana\n$_suasana',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        Card(
                          child: Center(
                            child: Text(
                              _favorit ? 'Lagu favorit' : 'Belum favorit',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),

                    _judul('Urutan kegiatan'),

                    const Text(
                      'Tahan lalu geser item, atau gunakan pegangan di kanan.',
                    ),

                    // Slide 10: Mengubah urutan dengan drag & drop.
                    ReorderableListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      onReorder: (awal, akhir) {
                        setState(() {
                          if (akhir > awal) akhir--;

                          final item = _urutan.removeAt(awal);
                          _urutan.insert(akhir, item);
                        });
                      },
                      children: [
                        for (final item in _urutan)
                          ListTile(
                            key: ValueKey(item),
                            title: Text(item),
                          ),
                      ],
                    ),

                    _judul('Tips membaca'),

                    // Slide 10: CustomScrollView menggabungkan sliver.
                    SizedBox(
                      height: 130,
                      child: CustomScrollView(
                        primary: false,
                        slivers: [
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.all(8),
                              child: Text('Geser area tips ini'),
                            ),
                          ),
                          SliverList(
                            delegate: SliverChildListDelegate(
                              const [
                                ListTile(
                                  title: Text(
                                    '1. Atur ukuran teks agar nyaman.',
                                  ),
                                ),
                                ListTile(
                                  title: Text(
                                    '2. Baca lirik per bait.',
                                  ),
                                ),
                                ListTile(
                                  title: Text(
                                    '3. Tulis kesan di bagian catatan.',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Halaman detail untuk animasi Hero.
class DetailSampul extends StatelessWidget {
  const DetailSampul({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sampul lagu'),
      ),
      body: Center(
        child: Hero(
          tag: 'sampul',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.network(
              _HalamanLirikState.foto,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stack) {
                return const Icon(
                  Icons.music_note,
                  size: 100,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}