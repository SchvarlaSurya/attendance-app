import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:attendance_app/models/attendance_session.dart';
import 'package:attendance_app/services/user_service.dart';
import 'package:attendance_app/theme/app_tokens.dart';
import 'package:attendance_app/ui/attend/attend_screen.dart';
import 'package:attendance_app/ui/widgets/feedback.dart';

/// Langkah pertama presensi siswa: pindai QR sesi dari guru, lewat kamera atau gambar.
class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  bool isChecking = false;

  // Hanya untuk membaca QR dari gambar; kamera dikelola widget MobileScanner sendiri.
  final _imageAnalyzer = MobileScannerController(autoStart: false);

  @override
  void dispose() {
    _imageAnalyzer.dispose();
    super.dispose();
  }

  void onDetect(BarcodeCapture capture) {
    if (isChecking) return;
    _checkQr(capture.barcodes.isEmpty ? null : capture.barcodes.first.rawValue);
  }

  Future<void> pickFromGallery() async {
    if (isChecking) return;
    setState(() => isChecking = true);
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image == null) {
        if (mounted) setState(() => isChecking = false);
        return;
      }
      final capture = await _imageAnalyzer.analyzeImage(image.path);
      final raw = capture?.barcodes.isEmpty ?? true ? null : capture!.barcodes.first.rawValue;
      if (raw == null) {
        _rejectAfterPause("QR tidak ditemukan di gambar.", Icons.image_search_rounded);
        return;
      }
      await _checkQr(raw);
    } catch (e) {
      _rejectAfterPause("Gagal membaca gambar: $e", Icons.error_outline_rounded);
    }
  }

  Future<void> _checkQr(String? raw) async {
    final sessionId = AttendanceSession.idFromQr(raw);
    if (sessionId == null) {
      _rejectAfterPause("QR tidak dikenali. Pindai QR sesi dari guru.", Icons.qr_code_2_rounded);
      return;
    }

    setState(() => isChecking = true);
    showLoaderDialog(context);
    try {
      final doc = await FirebaseFirestore.instance.collection('sessions').doc(sessionId).get();
      if (!doc.exists) throw const _ScanRejected("Sesi tidak ditemukan.", Icons.search_off_rounded);
      final session = AttendanceSession.fromDoc(doc);
      if (!session.isOpen) {
        throw const _ScanRejected("Sesi sudah berakhir atau QR kedaluwarsa.", Icons.timer_off_rounded);
      }

      final uid = UserService.current.value?.uid;
      final existing = await FirebaseFirestore.instance
          .collection('attendance')
          .where('session_id', isEqualTo: sessionId)
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
        throw const _ScanRejected("Kamu sudah absen di sesi ini.", Icons.check_circle_outline_rounded);
      }

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AttendScreen(session: session)),
      );
    } on _ScanRejected catch (r) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      _rejectAfterPause(r.message, r.icon);
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      _rejectAfterPause("Gagal memeriksa sesi: $e", Icons.error_outline_rounded);
    }
  }

  // Jeda sebentar supaya QR yang sama tidak langsung terbaca berulang kali.
  void _rejectAfterPause(String message, IconData icon) {
    if (!mounted) return;
    setState(() => isChecking = true);
    showAppSnackBar(context, message, icon);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => isChecking = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.cameraGround,
      appBar: AppBar(title: const Text("Scan Session QR")),
      body: SizedBox.expand(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: MobileScanner(
                onDetect: onDetect,
                errorBuilder: (context, error) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.s6),
                    child: Text(
                      "Kamera tidak bisa dibuka: ${error.errorCode.name}",
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium!.copyWith(color: AppColors.onInverseSurface),
                    ),
                  ),
                ),
              ),
            ),
            DottedBorder(
              borderType: BorderType.RRect,
              radius: const Radius.circular(AppRadius.frame),
              dashPattern: const [8, 4],
              color: AppColors.accent,
              strokeWidth: 2,
              child: const SizedBox.square(dimension: AppSizes.scannerFrameWidth),
            ),
            Positioned(
              left: AppSpacing.s4,
              right: AppSpacing.s4,
              bottom: AppSpacing.s8,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s4,
                      vertical: AppSpacing.s3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.inverseSurface,
                      borderRadius: BorderRadius.circular(AppRadius.field),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.qr_code_scanner_rounded, color: AppColors.onInverseSurface),
                        const SizedBox(width: AppSpacing.s3),
                        Expanded(
                          child: Text(
                            "Arahkan kamera ke QR sesi yang ditampilkan guru",
                            style: textTheme.bodyMedium!.copyWith(color: AppColors.onInverseSurface),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s3),
                  SizedBox(
                    height: AppSizes.buttonHeight,
                    child: FilledButton.icon(
                      onPressed: isChecking ? null : pickFromGallery,
                      icon: const Icon(Icons.photo_library_rounded),
                      label: const Text("Scan from Gallery"),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanRejected implements Exception {
  final String message;
  final IconData icon;

  const _ScanRejected(this.message, this.icon);
}
