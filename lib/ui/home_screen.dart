import 'package:flutter/material.dart';
import 'package:attendance_app/theme/app_tokens.dart';
import 'package:attendance_app/ui/attend/attend_screen.dart';
import 'package:attendance_app/ui/absent/absent_screen.dart';
import 'package:attendance_app/ui/attendance_history/attendance_history_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendance - XI RPL"),
      ),
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
              "Select a menu to proceed",
              style: textTheme.bodyMedium!.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s6),
            _HomeMenuCard(
              title: "Attendance Record",
              subtitle: "Take selfie photo and record your attendance",
              imagePath: 'assets/images/ic_absen.png',
              fallbackIcon: Icons.photo_camera_front_rounded,
              isPrimary: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AttendScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.s4),
            _HomeMenuCard(
              title: "Permission / Leave",
              subtitle: "Submit leave request for sick or permission",
              imagePath: 'assets/images/ic_leave.png',
              fallbackIcon: Icons.assignment_rounded,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AbsentScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.s4),
            _HomeMenuCard(
              title: "Attendance History",
              subtitle: "View and manage all attendance history records",
              imagePath: 'assets/images/ic_history.png',
              fallbackIcon: Icons.history_rounded,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AttendanceHistoryScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        height: AppSizes.footerHeight,
        color: AppColors.primary,
        alignment: Alignment.center,
        child: Text(
          "IDN Boarding School Solo",
          style: textTheme.labelMedium!.copyWith(color: AppColors.onPrimary),
        ),
      ),
    );
  }
}

class _HomeMenuCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imagePath;
  final IconData fallbackIcon;
  final bool isPrimary;
  final VoidCallback onTap;

  const _HomeMenuCard({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.fallbackIcon,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final slotColor = isPrimary ? AppColors.primary : AppColors.primaryContainer;
    final slotIconColor = isPrimary ? AppColors.onPrimary : AppColors.onPrimaryContainer;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(color: isPrimary ? AppColors.primary : AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.surfaceMuted,
        highlightColor: AppColors.surfaceMuted,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s4),
          child: Row(
            children: [
              Container(
                width: AppSizes.menuSlot,
                height: AppSizes.menuSlot,
                decoration: BoxDecoration(
                  color: slotColor,
                  borderRadius: BorderRadius.circular(AppRadius.field),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                  // Ikon Rounded selama file ikon belum ditaruh di assets/images/.
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(fallbackIcon, size: 32, color: slotIconColor),
                ),
              ),
              const SizedBox(width: AppSpacing.s4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: textTheme.titleSmall),
                    const SizedBox(height: AppSpacing.s1),
                    Text(
                      subtitle,
                      style: textTheme.bodySmall!.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
