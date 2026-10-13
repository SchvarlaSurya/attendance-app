import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
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
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    getGeoLocationPosition();
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
    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    Placemark place = placemarks[0];
    if (mounted) {
      setState(() {
        strAlamat =
            "${place.street}, ${place.subLocality}, ${place.locality}, "
            "${place.subAdministrativeArea}, ${place.postalCode}, ${place.country}";
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
          ],
        ),
      ),
    );
  }
}
