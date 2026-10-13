import 'package:flutter/material.dart';

class AbsentScreen extends StatelessWidget {
  const AbsentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Izin / Sakit')),
      body: const Center(child: Text('Form izin & sakit')),
    );
  }
}
