import 'dart:io';

import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:attendance_app/theme/app_tokens.dart';
import 'package:attendance_app/ui/attend/camera_screen.dart';
import 'package:attendance_app/ui/widgets/feedback.dart';

class AttendScreen extends StatefulWidget {
  final XFile? image;

  const AttendScreen({super.key, this.image});

  @override
  State<AttendScreen> createState() => _AttendScreenState();
}

class _AttendScreenState extends State<AttendScreen> {
  double? dLat;
  double? dLong;
  String strAlamat = "";
  String strStatus = "Attend";
  String strDateTime = "";
  bool isLoading = false;

  final nameController = TextEditingController();
  final CollectionReference dataCollection =
      FirebaseFirestore.instance.collection('attendance');

  @override
  void initState() {
    super.initState();
    getGeoLocationPosition();
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  void setStatusAbsen() {
    final now = DateTime.now();
    final dateHours = now.hour;
    final dateMinutes = now.minute;

    if (dateHours < 8 || (dateHours == 8 && dateMinutes <= 30)) {
      strStatus = "Attend";   // Tepat waktu (sebelum / pukul 08:30)
    } else if ((dateHours > 8 && dateHours < 18) ||
        (dateHours == 8 && dateMinutes >= 31)) {
      strStatus = "Late";     // Terlambat (08:31 s/d 17:59)
    } else {
      strStatus = "Leave";    // Di luar jam operasional
    }
  }

  void onSubmitPressed() {
    if (widget.image == null) {
      _showSnackBar("Ambil foto selfie terlebih dahulu.", Icons.camera_front_rounded);
      return;
    }
    if (nameController.text.trim().isEmpty) {
      _showSnackBar("Nama wajib diisi.", Icons.person_outline_rounded);
      return;
    }
    setStatusAbsen();
    strDateTime = DateFormat('dd MMMM yyyy HH:mm:ss').format(DateTime.now());
    submitAbsen(strAlamat, nameController.text, strStatus);
  }

  Future<void> submitAbsen(String alamat, String nama, String status) async {
    _showLoaderDialog();

    try {
      await dataCollection.add({
        'name': nama.trim(),
        'address': alamat.isEmpty ? 'Lokasi tidak terekam' : alamat,
        'description': status,
        'datetime': strDateTime,
        'latitude': dLat,
        'longitude': dLong,
        'type': 'attendance',
        'created_at': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      _showSnackBar("Presensi berhasil disimpan ($status).", Icons.check_circle_outline_rounded);

      // Kembali ke HomeScreen yang sudah ada di bawah stack
      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      _showSnackBar("Gagal menyimpan presensi: $e", Icons.error_outline_rounded);
    }
  }

  void _showLoaderDialog() => showLoaderDialog(context);

  void openCamera() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CameraScreen()),
    );
  }

  Future<bool> handleLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnackBar("Layanan GPS tidak aktif. Silakan aktifkan GPS perangkat Anda.", Icons.location_off_rounded);
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnackBar("Izin akses lokasi ditolak.", Icons.warning_amber_rounded);
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showSnackBar("Izin lokasi ditolak permanen. Buka pengaturan aplikasi untuk mengizinkan.", Icons.error_outline_rounded);
      return false;
    }

    return true;
  }

  Future<void> getGeoLocationPosition() async {
    final hasPermission = await handleLocationPermission();
    if (!hasPermission) return;

    setState(() => isLoading = true);
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      dLat = position.latitude;
      dLong = position.longitude;
      await getAddressFromLongLat(position);
    } catch (e) {
      debugPrint("Error GPS: $e");
      if (mounted) {
        setState(() {
          strAlamat = "Koordinat: Lat $dLat, Long $dLong";
          isLoading = false;
        });
      }
    }
  }

  Future<void> getAddressFromLongLat(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isEmpty) throw Exception("No placemark found");
      if (mounted) {
        final place = placemarks[0];
        setState(() {
          strAlamat = "${place.street ?? ''}, ${place.subLocality ?? ''}, ${place.locality ?? ''}, ${place.country ?? ''}"
              .replaceAll(RegExp(r'^[,\s]+|[,\s]+$'), '')
              .replaceAll(RegExp(r',\s*,+'), ',');
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        strAlamat = "Lat: ${position.latitude.toStringAsFixed(5)}, Long: ${position.longitude.toStringAsFixed(5)}";
        isLoading = false;
      });
    }
  }

  void _showSnackBar(String message, IconData icon) {
    if (!mounted) return;
    showAppSnackBar(context, message, icon);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Attendance Record")),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s5,
            vertical: AppSpacing.s4,
          ),
          children: [
            TextField(
              controller: nameController,
              textCapitalization: TextCapitalization.words,
              style: textTheme.bodyLarge,
              decoration: const InputDecoration(
                labelText: "Full Name",
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: AppSpacing.s6),
            Text("Selfie Photo", style: textTheme.titleSmall),
            const SizedBox(height: AppSpacing.s3),
            _buildSelfieBox(textTheme),
            const SizedBox(height: AppSpacing.s6),
            Row(
              children: [
                Expanded(child: Text("Your Location", style: textTheme.titleSmall)),
                IconButton(
                  tooltip: "Refresh location",
                  color: AppColors.primary,
                  disabledColor: AppColors.onDisabled,
                  onPressed: isLoading ? null : getGeoLocationPosition,
                  icon: const Icon(Icons.my_location_rounded),
                ),
              ],
            ),
            _buildLocationPanel(textTheme),
            const SizedBox(height: AppSpacing.s8),
            SizedBox(
              height: AppSizes.buttonHeight,
              child: FilledButton.icon(
                onPressed: isLoading ? null : onSubmitPressed,
                icon: const Icon(Icons.send_rounded),
                label: const Text("Submit Attendance"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelfieBox(TextTheme textTheme) {
    final image = widget.image;
    final radius = BorderRadius.circular(AppRadius.card);

    if (image != null) {
      return Material(
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: Ink.image(
          image: FileImage(File(image.path)),
          fit: BoxFit.cover,
          height: AppSizes.selfieHeight,
          child: InkWell(onTap: openCamera),
        ),
      );
    }

    // Garis putus menandai slot foto yang wajib diisi.
    return DottedBorder(
      borderType: BorderType.RRect,
      radius: const Radius.circular(AppRadius.card),
      dashPattern: const [6, 4],
      color: AppColors.outline,
      strokeWidth: 1,
      padding: EdgeInsets.zero,
      child: Material(
        color: AppColors.surfaceMuted,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: openCamera,
          splashColor: AppColors.primaryContainer,
          highlightColor: AppColors.primaryContainer,
          child: SizedBox(
            height: AppSizes.selfieHeight,
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.camera_front_rounded, size: 64, color: AppColors.textSecondary),
                const SizedBox(height: AppSpacing.s2),
                Text(
                  "Tap to take selfie",
                  style: textTheme.bodyMedium!.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationPanel(TextTheme textTheme) {
    final hasAddress = strAlamat.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s4),
      constraints: const BoxConstraints(minHeight: 56),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: isLoading
          ? const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  hasAddress ? Icons.location_on_rounded : Icons.location_off_rounded,
                  color: hasAddress ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: Text(
                    hasAddress ? strAlamat : "Lokasi belum didapat",
                    style: textTheme.bodyMedium!.copyWith(
                      color: hasAddress ? AppColors.textPrimary : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
