import 'package:flutter/material.dart';
import 'package:attendance_app/theme/app_tokens.dart';

/// Pill status: icon in a status-colored dot + label text, so status is never color only.
class StatusBadge extends StatelessWidget {
  final String description;

  const StatusBadge({super.key, required this.description});

  static const _styles = {
    'Attend': _BadgeStyle(Icons.check_rounded, AppColors.statusAttend, AppColors.statusAttendOn,
        AppColors.statusAttendContainer, AppColors.statusAttendOnContainer),
    'Late': _BadgeStyle(Icons.schedule_rounded, AppColors.statusLate, AppColors.statusLateOn,
        AppColors.statusLateContainer, AppColors.statusLateOnContainer),
    'Leave': _BadgeStyle(Icons.nights_stay_rounded, AppColors.statusLeave, AppColors.statusLeaveOn,
        AppColors.statusLeaveContainer, AppColors.statusLeaveOnContainer),
    'Sick': _BadgeStyle(Icons.medication_rounded, AppColors.statusSick, AppColors.statusSickOn,
        AppColors.statusSickContainer, AppColors.statusSickOnContainer),
    'Permission': _BadgeStyle(Icons.assignment_rounded, AppColors.statusPermission,
        AppColors.statusPermissionOn, AppColors.statusPermissionContainer,
        AppColors.statusPermissionOnContainer),
    'Others': _BadgeStyle(Icons.more_horiz_rounded, AppColors.statusOthers, AppColors.statusOthersOn,
        AppColors.statusOthersContainer, AppColors.statusOthersOnContainer),
  };

  // Nilai di luar 6 status sistem (mis. "-" atau teks bebas dari Edit Data).
  static const _fallback = _BadgeStyle(Icons.label_outline_rounded, AppColors.statusLeave,
      AppColors.statusLeaveOn, AppColors.statusLeaveContainer, AppColors.statusLeaveOnContainer);

  @override
  Widget build(BuildContext context) {
    final s = _styles[description] ?? _fallback;

    return Container(
      height: AppSizes.badgeHeight,
      padding: const EdgeInsets.only(left: AppSpacing.s1, right: 10),
      decoration: BoxDecoration(
        color: s.container,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(color: s.base, shape: BoxShape.circle),
            child: Icon(s.icon, size: 14, color: s.onBase),
          ),
          const SizedBox(width: 6),
          Text(
            description,
            style: Theme.of(context).textTheme.labelSmall!.copyWith(color: s.onContainer),
          ),
        ],
      ),
    );
  }
}

class _BadgeStyle {
  final IconData icon;
  final Color base;
  final Color onBase;
  final Color container;
  final Color onContainer;

  const _BadgeStyle(this.icon, this.base, this.onBase, this.container, this.onContainer);
}
