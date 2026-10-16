import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:lottie/lottie.dart';
import 'package:attendance_app/models/attendance_session.dart';
import 'package:attendance_app/theme/app_tokens.dart';
import 'package:attendance_app/ui/attend/attend_screen.dart';
import 'package:attendance_app/ui/widgets/feedback.dart';
import 'package:attendance_app/utils/face_detection/google_ml_kit.dart';

class CameraScreen extends StatefulWidget {
  final AttendanceSession session;

  const CameraScreen({super.key, required this.session});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? controller;
  bool isCameraReady = false;
  bool isBusy = false;
  // ML Kit hanya ada di Android/iOS. Di Chrome/desktop deteksi wajah dilewati.
  static final bool faceDetectionSupported = !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  final FaceDetector? faceDetector =
      faceDetectionSupported ? GoogleMlKit.vision.faceDetector() : null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initializeCamera();
  }

  // Lepas kamera saat aplikasi ke background, nyalakan lagi saat kembali.
  // Tanpa ini kamera tetap terkunci dan preview jadi hitam setelah minimize.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      final oldController = controller;
      if (oldController == null) return;
      controller = null;
      if (mounted) setState(() => isCameraReady = false);
      oldController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      if (controller == null) initializeCamera();
    }
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

    final newController = CameraController(
      frontCamera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    controller = newController;

    try {
      await newController.initialize();
      // Bisa saja aplikasi sudah ke background & controller ini sudah dilepas
      if (!mounted || controller != newController) return;
      setState(() => isCameraReady = true);
    } catch (e) {
      debugPrint("Failed to initialize camera: $e");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller?.dispose();
    faceDetector?.close();
    super.dispose();
  }

  Future<void> captureImage() async {
    final cameraController = controller;
    if (!isCameraReady ||
        isBusy ||
        cameraController == null ||
        cameraController.value.isTakingPicture) {
      return;
    }

    showLoaderDialog(context);

    try {
      final imageFile = await cameraController.takePicture();
      if (faceDetector == null) {
        if (!mounted) return;
        Navigator.of(context, rootNavigator: true).pop();
        _openForm(imageFile);
        return;
      }
      final inputImage = InputImage.fromFilePath(imageFile.path);
      await processImage(inputImage, imageFile);
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        _showSnackBar("Gagal mengambil foto: $e", Icons.error_outline_rounded);
      }
    }
  }

  Future<void> processImage(InputImage inputImage, XFile imageFile) async {
    if (isBusy) return;
    isBusy = true;

    try {
      final faces = await faceDetector!.processImage(inputImage);
      isBusy = false;

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // Tutup loader dialog

      if (faces.isNotEmpty) {
        // Wajah asli terdeteksi -> Lanjut ke layar form konfirmasi presensi.
        _openForm(imageFile);
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
        _showSnackBar(
          "Gagal memproses deteksi wajah: $e",
          Icons.error_outline_rounded,
        );
      }
    }
  }

  // Buang form kosong & kamera dari stack supaya Back langsung ke Home.
  void _openForm(XFile imageFile) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AttendScreen(session: widget.session, image: imageFile),
      ),
      (route) => route.isFirst,
    );
  }

  void _showSnackBar(String message, IconData icon) {
    showAppSnackBar(context, message, icon);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cameraGround,
      appBar: AppBar(title: const Text("Face Scanner")),
      body: SizedBox.expand(
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isCameraReady)
              Positioned.fill(child: CameraPreview(controller!))
            else
              const CircularProgressIndicator(
                color: AppColors.accent,
                backgroundColor: AppColors.inverseSurface,
              ),
            DottedBorder(
              borderType: BorderType.RRect,
              radius: const Radius.circular(AppRadius.frame),
              dashPattern: const [8, 4],
              color: AppColors.accent,
              strokeWidth: 2,
              child: SizedBox(
                width: AppSizes.scannerFrameWidth,
                height: AppSizes.scannerFrameHeight,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Lottie.asset(
                      'assets/raw/face_id_ring.json',
                      width: AppSizes.scannerRing,
                      height: AppSizes.scannerRing,
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
              bottom: AppSpacing.s8,
              child: SizedBox.square(
                dimension: AppSizes.shutter,
                child: FloatingActionButton.large(
                  onPressed: captureImage,
                  tooltip: "Ambil foto",
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.primary,
                  splashColor: AppColors.surfaceMuted,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.frame),
                  ),
                  child: const Icon(Icons.photo_camera_rounded, size: 36),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
