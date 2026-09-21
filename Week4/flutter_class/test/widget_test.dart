import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final cameras = await availableCameras();

  runApp(
    MyApp(cameras: cameras),
  );
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  const MyApp({
    super.key,
    required this.cameras,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My Photobooth',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: PhotoboothPage(cameras: cameras),
    );
  }
}

class PhotoboothPage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const PhotoboothPage({
    super.key,
    required this.cameras,
  });

  @override
  State<PhotoboothPage> createState() => _PhotoboothPageState();
}

class _PhotoboothPageState extends State<PhotoboothPage> {
  CameraController? controller;

  List<Uint8List> photos = [];

  bool isTakingPhoto = false;

  @override
  void initState() {
    super.initState();

    initializeCamera();
  }

  Future<void> initializeCamera() async {
    if (widget.cameras.isEmpty) {
      return;
    }

    controller = CameraController(
      widget.cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await controller!.initialize();

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> takePhoto() async {
    if (controller == null ||
        !controller!.value.isInitialized ||
        isTakingPhoto ||
        photos.length >= 3) {
      return;
    }

    setState(() {
      isTakingPhoto = true;
    });

    try {
      final XFile picture = await controller!.takePicture();

      final Uint8List bytes = await picture.readAsBytes();

      setState(() {
        photos.add(bytes);
      });
    } catch (e) {
      print(e);
    }

    setState(() {
      isTakingPhoto = false;
    });
  }

  void resetPhotos() {
    setState(() {
      photos.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff6f0e8),

      appBar: AppBar(
        backgroundColor: Colors.pink.shade200,
        title: const Text(
          '📸 My Photobooth',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      body: controller == null ||
              !controller!.value.isInitialized
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    children: [

                      // Judul
                      const Text(
                        'Strike a Pose! ✨',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // CAMERA PREVIEW
                      Container(
                        width: 550,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                              blurRadius: 10,
                              color: Colors.black26,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: AspectRatio(
                            aspectRatio:
                                controller!.value.aspectRatio,
                            child: CameraPreview(controller!),
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),

                      Text(
                        '${photos.length}/3 photos',
                        style: const TextStyle(
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 15),

                      // SHUTTER BUTTON
                      ElevatedButton.icon(
                        onPressed:
                            photos.length >= 3 ? null : takePhoto,
                        icon: const Icon(
                          Icons.camera_alt,
                        ),
                        label: Text(
                          isTakingPhoto
                              ? 'Taking photo...'
                              : 'Take Photo',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.pink.shade300,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 18,
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // PHOTO STRIP
                      if (photos.isNotEmpty)
                        Container(
                          width: 270,
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: const [
                              BoxShadow(
                                blurRadius: 10,
                                color: Colors.black26,
                              ),
                            ],
                            borderRadius:
                                BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [

                              const Text(
                                'PHOTOBOOTH',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 3,
                                ),
                              ),

                              const SizedBox(height: 12),

                              ...photos.map(
                                (photo) => Padding(
                                  padding:
                                      const EdgeInsets.only(
                                    bottom: 10,
                                  ),
                                  child: ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(5),
                                    child: Image.memory(
                                      photo,
                                      width: 240,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 5),

                              const Text(
                                '✨ memories ✨',
                                style: TextStyle(
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 20),

                      // RESET
                      if (photos.isNotEmpty)
                        TextButton.icon(
                          onPressed: resetPhotos,
                          icon:
                              const Icon(Icons.refresh),
                          label:
                              const Text('Take Again'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}