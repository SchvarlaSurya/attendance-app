import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:attendance_app/services/user_service.dart';
import 'package:attendance_app/theme/app_tokens.dart';
import 'package:attendance_app/ui/teacher/session_qr_screen.dart';
import 'package:attendance_app/ui/widgets/feedback.dart';

class CreateSessionScreen extends StatefulWidget {
  final AppUser user;

  const CreateSessionScreen({super.key, required this.user});

  @override
  State<CreateSessionScreen> createState() => _CreateSessionScreenState();
}

class _CreateSessionScreenState extends State<CreateSessionScreen> {
  static const durations = [5, 10, 15, 30];

  final classController = TextEditingController();
  final subjectController = TextEditingController();
  int selectedMinutes = 10;

  @override
  void dispose() {
    classController.dispose();
    subjectController.dispose();
    super.dispose();
  }

  Future<void> onCreatePressed() async {
    final className = classController.text.trim();
    final subject = subjectController.text.trim();
    if (className.isEmpty || subject.isEmpty) {
      showAppSnackBar(context, "Lengkapi kelas dan mata pelajaran terlebih dahulu.", Icons.warning_amber_rounded);
      return;
    }

    showLoaderDialog(context);
    try {
      final doc = await FirebaseFirestore.instance.collection('sessions').add({
        'class_name': className,
        'subject': subject,
        'teacher_uid': widget.user.uid,
        'teacher_name': widget.user.name,
        'created_at': FieldValue.serverTimestamp(),
        'expires_at': Timestamp.fromDate(DateTime.now().add(Duration(minutes: selectedMinutes))),
        'active': true,
      });
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SessionQrScreen(sessionId: doc.id)),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      showAppSnackBar(context, "Gagal membuat sesi: $e", Icons.error_outline_rounded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Create Session")),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s5,
            vertical: AppSpacing.s4,
          ),
          children: [
            TextField(
              controller: classController,
              textCapitalization: TextCapitalization.characters,
              style: textTheme.bodyLarge,
              decoration: const InputDecoration(
                labelText: "Class",
                prefixIcon: Icon(Icons.class_outlined),
              ),
            ),
            const SizedBox(height: AppSpacing.s4),
            TextField(
              controller: subjectController,
              textCapitalization: TextCapitalization.words,
              style: textTheme.bodyLarge,
              decoration: const InputDecoration(
                labelText: "Subject",
                prefixIcon: Icon(Icons.menu_book_rounded),
              ),
            ),
            const SizedBox(height: AppSpacing.s4),
            DropdownButtonFormField<int>(
              initialValue: selectedMinutes,
              style: textTheme.bodyLarge,
              dropdownColor: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.field),
              icon: const Icon(Icons.arrow_drop_down_rounded),
              decoration: const InputDecoration(
                labelText: "QR valid for",
                prefixIcon: Icon(Icons.timer_outlined),
              ),
              items: [
                for (final minutes in durations)
                  DropdownMenuItem(value: minutes, child: Text("$minutes minutes")),
              ],
              onChanged: (value) => setState(() => selectedMinutes = value ?? selectedMinutes),
            ),
            const SizedBox(height: AppSpacing.s8),
            SizedBox(
              height: AppSizes.buttonHeight,
              child: FilledButton.icon(
                onPressed: onCreatePressed,
                icon: const Icon(Icons.qr_code_rounded),
                label: const Text("Create Session"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
