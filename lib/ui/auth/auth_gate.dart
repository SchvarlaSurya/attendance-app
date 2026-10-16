import 'package:flutter/material.dart';
import 'package:attendance_app/services/user_service.dart';
import 'package:attendance_app/ui/auth/login_screen.dart';
import 'package:attendance_app/ui/home_screen.dart';
import 'package:attendance_app/ui/teacher/teacher_shell.dart';

/// Pilih layar awal sesuai profil lokal dan peran (Student / Teacher).
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppUser?>(
      valueListenable: UserService.current,
      builder: (context, user, _) {
        if (user == null) return const LoginScreen();
        return user.role == UserRole.teacher
            ? TeacherShell(user: user)
            : HomeScreen(user: user);
      },
    );
  }
}
