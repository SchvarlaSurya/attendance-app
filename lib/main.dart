import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:attendance_app/services/user_service.dart';
import 'package:attendance_app/theme/app_theme.dart';
import 'package:attendance_app/ui/auth/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyDauGqKgEV6Q2yJMjFbaCbUNDk5FjGb0hc',
        appId: '1:113228359740:android:c9363c7bec701353b93b39',
        messagingSenderId: '113228359740',
        projectId: 'idn-attendance-app-6ceac',
      ),
    );
    debugPrint("Firebase connected successfully!");
  } catch (e) {
    debugPrint("Firebase connection failed: $e");
  }
  await UserService.load();
  runApp(const AttendanceApp());
}

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Attendance App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const AuthGate(),
    );
  }
}
