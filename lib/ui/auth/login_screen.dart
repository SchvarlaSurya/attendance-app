import 'package:flutter/material.dart';
import 'package:attendance_app/services/user_service.dart';
import 'package:attendance_app/theme/app_tokens.dart';
import 'package:attendance_app/ui/widgets/feedback.dart';

/// Masuk sementara tanpa akun: isi nama dan pilih peran.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final nameController = TextEditingController();
  UserRole? selectedRole;

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> onContinuePressed() async {
    final name = nameController.text.trim();
    if (name.isEmpty || selectedRole == null) {
      showAppSnackBar(context, "Isi nama dan pilih peran terlebih dahulu.", Icons.warning_amber_rounded);
      return;
    }
    await UserService.signIn(name: name, role: selectedRole!);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Attendance - XI RPL")),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s5, AppSpacing.s6, AppSpacing.s5, AppSpacing.s4,
          ),
          children: [
            Text(
              "Welcome to Attendance App",
              style: textTheme.titleLarge!.copyWith(color: AppColors.primary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s1),
            Text(
              "Enter your name and choose your role",
              style: textTheme.bodyMedium!.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s6),
            TextField(
              controller: nameController,
              textCapitalization: TextCapitalization.words,
              style: textTheme.bodyLarge,
              decoration: const InputDecoration(
                labelText: "Full Name",
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: AppSpacing.s4),
            DropdownButtonFormField<UserRole>(
              initialValue: selectedRole,
              style: textTheme.bodyLarge,
              dropdownColor: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.field),
              icon: const Icon(Icons.arrow_drop_down_rounded),
              decoration: const InputDecoration(
                labelText: "Role",
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              items: const [
                DropdownMenuItem(value: UserRole.student, child: Text("Student")),
                DropdownMenuItem(value: UserRole.teacher, child: Text("Teacher")),
              ],
              onChanged: (value) => setState(() => selectedRole = value),
            ),
            const SizedBox(height: AppSpacing.s8),
            SizedBox(
              height: AppSizes.buttonHeight,
              child: FilledButton.icon(
                onPressed: onContinuePressed,
                icon: const Icon(Icons.login_rounded),
                label: const Text("Continue"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
