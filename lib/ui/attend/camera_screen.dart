import 'package:camera/camera.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:lottie/lottie.dart';
import 'package:attendance_app/ui/attend/attend_screen.dart';
import 'package:attendance_app/utils/face_detection/google_ml_kit.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? controller;
  bool isCameraReady = false;
  bool isBusy = false;
  final FaceDetector faceDetector = GoogleMlKit.vision.faceDetector();

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  Future<void> initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      debugPrint("No camera found on this device");
      return;
    }
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    controller = CameraController(
      frontCamera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await controller!.initialize();
      if (mounted) setState(() => isCameraReady = true);
    } catch (e) {
      debugPrint("Failed to initialize camera: $e");
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    faceDetector.close();
    super.dispose();
  }

  Future<void> captureImage() async {
    if (!isCameraReady || isBusy || controller!.value.isTakingPicture) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final imageFile = await controller!.takePicture();
      final inputImage = InputImage.fromFilePath(imageFile.path);
      await processImage(inputImage, imageFile);
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        _showSnackBar("Gagal mengambil foto: $e", Icons.error_outline);
      }
    }
  }

  Future<void> processImage(InputImage inputImage, XFile imageFile) async {
    if (isBusy) return;
    isBusy = true;

    try {
      final faces = await faceDetector.processImage(inputImage);
      isBusy = false;

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // Tutup loader dialog

      if (faces.isNotEmpty) {
        // Wajah asli terdeteksi -> Lanjut ke layar form konfirmasi presensi.
        // Buang form kosong & kamera dari stack supaya Back langsung ke Home.
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => AttendScreen(image: imageFile),
          ),
          (route) => route.isFirst,
        );
      } else {
        _showSnackBar(
          "Wajah tidak terdeteksi! Pastikan wajah terlihat jelas di bingkai.",
          Icons.warning_amber_rounded,
        );
      }
    } catch (e) {
      isBusy = false;
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        _showSnackBar("Gagal memproses deteksi wajah: $e", Icons.error_outline);
      }
    }
  }

  void _showSnackBar(String message, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text("Face Scanner")),
      body: Stack(
        alignment: Alignment.center,
        children: [
          if (isCameraReady)
            Positioned.fill(child: CameraPreview(controller!))
          else
            const CircularProgressIndicator(),
          DottedBorder(
            borderType: BorderType.RRect,
            radius: const Radius.circular(24),
            dashPattern: const [8, 4],
            color: Colors.blueAccent,
            strokeWidth: 2,
            child: SizedBox(
              width: 260,
              height: 340,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Lottie.asset(
                    'assets/raw/face_id_ring.json',
                    width: 240,
                    height: 240,
                    fit: BoxFit.contain,
                    // Kosong selama face_id_ring.json belum ditaruh di assets/raw/.
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 32,
            child: FloatingActionButton.large(
              onPressed: captureImage,
              backgroundColor: Colors.white,
              child: const Icon(
                Icons.camera_alt,
                color: Color(0xFF1A008F),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
