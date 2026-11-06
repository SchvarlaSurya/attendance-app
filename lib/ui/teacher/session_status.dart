import 'package:flutter/material.dart';
import 'package:attendance_app/models/attendance_session.dart';
import 'package:attendance_app/theme/app_tokens.dart';
import 'package:attendance_app/ui/widgets/status_badge.dart';

/// Sisa waktu di bawah ini dianggap "hampir habis".
const almostExpiredThreshold = Duration(seconds: 60);

enum SessionState { active, almostExpired, expired, ended }

SessionState sessionStateOf(AttendanceSession session) {
  if (!session.active) return SessionState.ended;
  final left = session.remaining;
  if (left == Duration.zero) return SessionState.expired;
  if (left <= almostExpiredThreshold) return SessionState.almostExpired;
  return SessionState.active;
}

const _sessionStyles = {
  SessionState.active: StatusStyle(Icons.qr_code_rounded, AppColors.statusAttend,
      AppColors.statusAttendOn, AppColors.statusAttendContainer, AppColors.statusAttendOnContainer),
  SessionState.almostExpired: StatusStyle(Icons.timer_rounded, AppColors.statusLate,
      AppColors.statusLateOn, AppColors.statusLateContainer, AppColors.statusLateOnContainer),
  SessionState.expired: StatusStyle(Icons.timer_off_rounded, AppColors.statusLeave,
      AppColors.statusLeaveOn, AppColors.statusLeaveContainer, AppColors.statusLeaveOnContainer),
  SessionState.ended: StatusStyle(Icons.stop_rounded, AppColors.statusLeave,
      AppColors.statusLeaveOn, AppColors.statusLeaveContainer, AppColors.statusLeaveOnContainer),
};

const _sessionLabels = {
  SessionState.active: 'Active',
  SessionState.almostExpired: 'Ending soon',
  SessionState.expired: 'Expired',
  SessionState.ended: 'Ended',
};

class SessionStatusPill extends StatelessWidget {
  final SessionState state;

  const SessionStatusPill({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return StatusPill(label: _sessionLabels[state]!, style: _sessionStyles[state]!);
  }
}

String formatCountdown(Duration d) {
  final minutes = d.inMinutes.toString().padLeft(2, '0');
  final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
