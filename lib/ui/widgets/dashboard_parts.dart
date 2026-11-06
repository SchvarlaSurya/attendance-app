import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:attendance_app/theme/app_tokens.dart';

/// Pita sapaan di bawah app bar, dipakai Home siswa dan dashboard guru.
class GreetingHeader extends StatelessWidget {
  final String name;

  const GreetingHeader({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s5, AppSpacing.s1, AppSpacing.s5, AppSpacing.s5,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Hello, $name",
            style: textTheme.titleLarge!.copyWith(color: AppColors.onPrimary),
          ),
          const SizedBox(height: AppSpacing.s1),
          Text(
            DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
            style: textTheme.bodyMedium!.copyWith(color: AppColors.primaryContainer),
          ),
        ],
      ),
    );
  }
}

/// Kartu angka ringkasan: ikon, nilai, label.
class StatTile extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;
  final Color color;

  const StatTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: AppSpacing.s2),
            Text("$value", style: textTheme.titleLarge),
            Text(label, style: textTheme.bodySmall!.copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
