import 'dart:io';

import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:attendance_app/ui/attend/camera_screen.dart';

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
      _showSnackBar("Ambil foto selfie terlebih dahulu.", Icons.camera_front);
      return;
    }
    if (nameController.text.trim().isEmpty) {
      _showSnackBar("Nama wajib diisi.", Icons.person_outline);
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
      _showSnackBar("Presensi berhasil disimpan ($status).", Icons.check_circle_outline);

      // Kembali ke HomeScreen yang sudah ada di bawah stack
      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      _showSnackBar("Gagal menyimpan presensi: $e", Icons.error_outline);
    }
  }

  void _showLoaderDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
  }

  void openCamera() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CameraScreen()),
    );
  }

  Future<bool> handleLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnackBar("Layanan GPS tidak aktif. Silakan aktifkan GPS perangkat Anda.", Icons.location_off);
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
      _showSnackBar("Izin lokasi ditolak permanen. Buka pengaturan aplikasi untuk mengizinkan.", Icons.error_outline);
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
    final image = widget.image;

    return Scaffold(
      appBar: AppBar(title: const Text("Attendance Record")),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            TextField(
              controller: nameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: "Full Name",
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Selfie Photo",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: openCamera,
              child: Container(
                height: 320,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                clipBehavior: Clip.antiAlias,
                child: image != null
                    ? Image.file(File(image.path), fit: BoxFit.cover)
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_front, size: 64, color: Colors.grey),
                          SizedBox(height: 8),
                          Text(
                            "Tap to take selfie",
                            style: TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    "Your Location",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  tooltip: "Refresh location",
                  onPressed: isLoading ? null : getGeoLocationPosition,
                  icon: const Icon(Icons.my_location),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Text(
                      strAlamat.isEmpty ? "Lokasi belum didapat" : strAlamat,
                      style: const TextStyle(color: Colors.black87),
                    ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: isLoading ? null : onSubmitPressed,
                icon: const Icon(Icons.send),
                label: const Text(
                  "Submit Attendance",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
