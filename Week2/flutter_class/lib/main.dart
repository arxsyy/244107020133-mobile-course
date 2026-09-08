import 'package:flutter/material.dart';
import 'lirik.dart';
import 'mahasiswa.dart';

void main() {
  runApp(const Marsya());
}

class Marsya extends StatelessWidget {
  const Marsya({super.key});

  @override
  Widget build(BuildContext context) {
    final mahasiswa = Mahasiswa(nama: 'Marsya', umur: 20, kelas: 'TI-3C');

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lirik Lagu',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF89664F),
        ),
      ),
      home: Scaffold(
        backgroundColor: const Color(0xFFF7F3EE),
        appBar: AppBar(
          title: const Text('Lirik Lagu'),
          centerTitle: true,
          backgroundColor: const Color(0xFFF7F3EE),
          foregroundColor: const Color(0xFF654B3E),
          elevation: 0,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    // Ikon musik sebagai hiasan sederhana.
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEADDD0),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(
                          Icons.music_note_rounded,
                          size: 44,
                          color: Color(0xFF89664F),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
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
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Kotak putih dan jarak antarbaris agar nyaman dibaca.
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 28,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE8DDD3)),
                      ),
                      child: Text(
                        lirik.isi.split('\n').map((baris) => baris.trim()).join('\n').trim(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.9,
                          color: Color(0xFF56483F),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Created by ${mahasiswa.nama}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF816D60),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Icon(
                      Icons.favorite_border,
                      size: 20,
                      color: Color(0xFF9C8070),
                    ),
                    const SizedBox(height: 12),
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
