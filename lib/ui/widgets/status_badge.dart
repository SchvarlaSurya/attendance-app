import 'package:flutter/material.dart';
import 'package:attendance_app/theme/app_tokens.dart';

class StatusStyle {
  final IconData icon;
  final Color base;
  final Color onBase;
  final Color container;
  final Color onContainer;

  const StatusStyle(this.icon, this.base, this.onBase, this.container, this.onContainer);

  static const attend = StatusStyle(Icons.check_rounded, AppColors.statusAttend,
      AppColors.statusAttendOn, AppColors.statusAttendContainer, AppColors.statusAttendOnContainer);
  static const late = StatusStyle(Icons.schedule_rounded, AppColors.statusLate,
      AppColors.statusLateOn, AppColors.statusLateContainer, AppColors.statusLateOnContainer);
  static const leave = StatusStyle(Icons.nights_stay_rounded, AppColors.statusLeave,
      AppColors.statusLeaveOn, AppColors.statusLeaveContainer, AppColors.statusLeaveOnContainer);
  static const sick = StatusStyle(Icons.medication_rounded, AppColors.statusSick,
      AppColors.statusSickOn, AppColors.statusSickContainer, AppColors.statusSickOnContainer);
  static const permission = StatusStyle(Icons.assignment_rounded, AppColors.statusPermission,
      AppColors.statusPermissionOn, AppColors.statusPermissionContainer,
      AppColors.statusPermissionOnContainer);
  static const others = StatusStyle(Icons.more_horiz_rounded, AppColors.statusOthers,
      AppColors.statusOthersOn, AppColors.statusOthersContainer, AppColors.statusOthersOnContainer);

  // Nilai di luar 6 status sistem (mis. "-" atau teks bebas dari Edit Data).
  static const unknown = StatusStyle(Icons.label_outline_rounded, AppColors.statusLeave,
      AppColors.statusLeaveOn, AppColors.statusLeaveContainer, AppColors.statusLeaveOnContainer);
}

/// Semua status sistem, urut seperti di rekap dan dialog ubah status.
const attendanceStatuses = ['Attend', 'Late', 'Leave', 'Sick', 'Permission', 'Others'];

const _statusStyles = {
  'Attend': StatusStyle.attend,
  'Late': StatusStyle.late,
  'Leave': StatusStyle.leave,
  'Sick': StatusStyle.sick,
  'Permission': StatusStyle.permission,
  'Others': StatusStyle.others,
};

StatusStyle statusStyleOf(String description) => _statusStyles[description] ?? StatusStyle.unknown;

/// Pill: ikon di lingkaran berwarna + label teks, jadi makna tidak hanya lewat warna.
class StatusPill extends StatelessWidget {
  final String label;
  final StatusStyle style;

  const StatusPill({super.key, required this.label, required this.style});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSizes.badgeHeight,
      padding: const EdgeInsets.only(left: AppSpacing.s1, right: 10),
      decoration: BoxDecoration(
        color: style.container,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(color: style.base, shape: BoxShape.circle),
            child: Icon(style.icon, size: 14, color: style.onBase),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall!.copyWith(color: style.onContainer),
          ),
        ],
      ),
    );
  }
}

/// Status presensi/izin dari field `description`.
class StatusBadge extends StatelessWidget {
  final String description;

  const StatusBadge({super.key, required this.description});

  @override
  Widget build(BuildContext context) {
    return StatusPill(label: description, style: statusStyleOf(description));
  }
}
