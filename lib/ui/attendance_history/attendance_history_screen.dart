import 'package:flutter/material.dart';

class AttendanceHistoryScreen extends StatelessWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Presensi')),
      body: const Center(child: Text('Riwayat presensi')),
    );
  }
}
