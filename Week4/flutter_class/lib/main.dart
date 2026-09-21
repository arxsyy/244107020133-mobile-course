import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final cameras = await availableCameras();

  runApp(
    PhotoboothApp(cameras: cameras),
  );
}

class PhotoboothApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  const PhotoboothApp({
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
  State<PhotoboothPage> createState() =>
      _PhotoboothPageState();
}

class _PhotoboothPageState extends State<PhotoboothPage> {
  CameraController? controller;

  final List<Uint8List> photos = [];

  bool isCameraReady = false;
  bool isTakingPhoto = false;
  bool isSwitchingCamera = false;
  bool cameraError = false;

  String errorMessage = '';

  CameraLensDirection currentDirection =
      CameraLensDirection.front;

  @override
  void initState() {
    super.initState();

    initializeCamera(currentDirection);
  }

  // ==============================
  // INISIALISASI KAMERA
  // ==============================

  Future<void> initializeCamera(
    CameraLensDirection direction,
  ) async {
    if (widget.cameras.isEmpty) {
      if (!mounted) return;

      setState(() {
        cameraError = true;
        errorMessage = 'Kamera tidak ditemukan.';
      });

      return;
    }

    try {
      // Sembunyikan preview lama terlebih dahulu
      if (mounted) {
        setState(() {
          isCameraReady = false;
        });
      }

      // Simpan controller lama
      final oldController = controller;

      // Lepaskan dari UI terlebih dahulu
      controller = null;

      // Baru dispose
      await oldController?.dispose();

      // Cari kamera sesuai arah
      final selectedCamera = widget.cameras.firstWhere(
        (camera) =>
            camera.lensDirection == direction,
        orElse: () => widget.cameras.first,
      );

      // Buat controller baru
      final newController = CameraController(
        selectedCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      // Jalankan kamera
      await newController.initialize();

      if (!mounted) {
        await newController.dispose();
        return;
      }

      // Tampilkan kamera baru
      setState(() {
        controller = newController;

        currentDirection =
            selectedCamera.lensDirection;

        isCameraReady = true;
        cameraError = false;
      });
    } on CameraException catch (e) {
      debugPrint(
        'Camera Error: ${e.code} ${e.description}',
      );

      if (!mounted) return;

      setState(() {
        cameraError = true;
        isCameraReady = false;

        if (e.code == 'CameraAccessDenied') {
          errorMessage =
              'Akses kamera ditolak. Izinkan kamera melalui pengaturan aplikasi.';
        } else {
          errorMessage =
              'Kamera tidak dapat digunakan.';
        }
      });
    }
  }

  // ==============================
  // SWITCH CAMERA
  // ==============================

  Future<void> switchCamera() async {
    if (isSwitchingCamera) return;

    setState(() {
      isSwitchingCamera = true;
    });

    final newDirection =
        currentDirection ==
                CameraLensDirection.front
            ? CameraLensDirection.back
            : CameraLensDirection.front;

    await initializeCamera(newDirection);

    if (!mounted) return;

    setState(() {
      isSwitchingCamera = false;
    });
  }

  // ==============================
  // AMBIL FOTO
  // ==============================

  Future<void> takePhoto() async {
    final currentController = controller;

    if (currentController == null) return;

    if (!currentController.value.isInitialized) {
      return;
    }

    if (isTakingPhoto) return;

    if (photos.length >= 3) return;

    setState(() {
      isTakingPhoto = true;
    });

    try {
      final XFile image =
          await currentController.takePicture();

      final Uint8List imageBytes =
          await image.readAsBytes();

      if (!mounted) return;

      setState(() {
        photos.add(imageBytes);
      });
    } on CameraException catch (e) {
      debugPrint(
        'Take Photo Error: ${e.code}',
      );
    } finally {
      if (mounted) {
        setState(() {
          isTakingPhoto = false;
        });
      }
    }
  }

  // ==============================
  // RESET FOTO
  // ==============================

  void resetPhotos() {
    setState(() {
      photos.clear();
    });
  }

  // ==============================
  // CAMERA PREVIEW
  // ==============================

  Widget cameraPreview() {
    final currentController = controller;

    if (!isCameraReady ||
        currentController == null ||
        !currentController.value.isInitialized ||
        currentController.value.previewSize == null) {
      return Container(
        height: 420,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      );
    }

    final previewSize =
        currentController.value.previewSize!;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),

      // Frame photobooth
      child: SizedBox(
        width: double.infinity,
        height: 420,

        // Cover supaya kamera tidak gepeng
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            // Dibalik karena HP portrait
            width: previewSize.height,
            height: previewSize.width,
            child: CameraPreview(
              currentController,
            ),
          ),
        ),
      ),
    );
  }

  // ==============================
  // UI
  // ==============================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFFFF7F9),

      appBar: AppBar(
        centerTitle: true,
        backgroundColor:
            const Color(0xFFFFC1D6),

        title: const Text(
          '📸 My Photobooth',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SafeArea(
        child: cameraError

            // ERROR CAMERA
            ? Center(
                child: Padding(
                  padding:
                      const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.camera_alt_outlined,
                        size: 60,
                        color: Colors.grey,
                      ),

                      const SizedBox(height: 15),

                      Text(
                        errorMessage,
                        textAlign:
                            TextAlign.center,
                        style: const TextStyle(
                          fontSize: 17,
                        ),
                      ),
                    ],
                  ),
                ),
              )

            // MAIN CONTENT
            : SingleChildScrollView(
                padding:
                    const EdgeInsets.all(20),

                child: Column(
                  children: [
                    // ======================
                    // TITLE
                    // ======================

                    const Text(
                      'Strike a Pose! ✨',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      currentDirection ==
                              CameraLensDirection
                                  .front
                          ? 'Front Camera'
                          : 'Back Camera',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ======================
                    // CAMERA
                    // ======================

                    Container(
                      width: double.infinity,
                      constraints:
                          const BoxConstraints(
                        maxWidth: 500,
                      ),
                      padding:
                          const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(
                          24,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color:
                                Colors.black12,
                            blurRadius: 12,
                            offset:
                                Offset(0, 5),
                          ),
                        ],
                      ),

                      child: Stack(
                        children: [
                          // Preview kamera
                          cameraPreview(),

                          // =================
                          // SWITCH CAMERA
                          // =================

                          Positioned(
                            top: 12,
                            right: 12,

                            child: Container(
                              decoration:
                                  const BoxDecoration(
                                color:
                                    Colors.black54,
                                shape:
                                    BoxShape.circle,
                              ),

                              child: IconButton(
                                onPressed:
                                    isSwitchingCamera
                                        ? null
                                        : switchCamera,

                                icon:
                                    isSwitchingCamera
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child:
                                                CircularProgressIndicator(
                                              strokeWidth:
                                                  2,
                                              color:
                                                  Colors.white,
                                            ),
                                          )
                                        : const Icon(
                                            Icons
                                                .cameraswitch,
                                            color:
                                                Colors.white,
                                          ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ======================
                    // COUNTER
                    // ======================

                    Text(
                      '${photos.length} / 3 Photos',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ======================
                    // TAKE PHOTO
                    // ======================

                    SizedBox(
                      width: 210,
                      height: 55,

                      child: ElevatedButton.icon(
                        onPressed:
                            photos.length >= 3 ||
                                    isTakingPhoto ||
                                    !isCameraReady ||
                                    isSwitchingCamera
                                ? null
                                : takePhoto,

                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(
                            0xFFFF77A9,
                          ),
                          foregroundColor:
                              Colors.white,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              30,
                            ),
                          ),
                        ),

                        icon: const Icon(
                          Icons.camera_alt,
                        ),

                        label: Text(
                          isTakingPhoto
                              ? 'Taking...'
                              : 'Take Photo',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // ======================
                    // PHOTO STRIP
                    // ======================

                    if (photos.isNotEmpty)
                      Container(
                        width: 280,
                        padding:
                            const EdgeInsets.all(
                          14,
                        ),
                        decoration:
                            BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(
                            12,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color:
                                  Colors.black12,
                              blurRadius: 10,
                              offset:
                                  Offset(0, 5),
                            ),
                          ],
                        ),

                        child: Column(
                          children: [
                            const Text(
                              'PHOTOBOOTH',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    FontWeight.bold,
                                letterSpacing: 4,
                              ),
                            ),

                            const SizedBox(
                              height: 12,
                            ),

                            for (final photo
                                in photos)
                              Padding(
                                padding:
                                    const EdgeInsets
                                        .only(
                                  bottom: 10,
                                ),

                                child: ClipRRect(
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    6,
                                  ),

                                  child:
                                      Image.memory(
                                    photo,
                                    width: 250,
                                    height: 180,
                                    fit:
                                        BoxFit.cover,
                                  ),
                                ),
                              ),

                            const SizedBox(
                              height: 5,
                            ),

                            const Text(
                              '✨ memories ✨',
                              style: TextStyle(
                                fontSize: 13,
                                fontStyle:
                                    FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 20),

                    // ======================
                    // RESET
                    // ======================

                    if (photos.isNotEmpty)
                      OutlinedButton.icon(
                        onPressed:
                            resetPhotos,
                        icon: const Icon(
                          Icons.refresh,
                        ),
                        label: const Text(
                          'Take Again',
                        ),
                      ),

                    const SizedBox(height: 30),
                  ],
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