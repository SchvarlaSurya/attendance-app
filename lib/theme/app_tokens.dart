import 'package:flutter/material.dart';

/// Design tokens from the Attendance App design system (Fase 1).
/// Names follow the token names: `status-attend` -> `AppColors.statusAttend`.
class AppColors {
  AppColors._();

  static const primary = Color(0xFF4F46E5);
  static const primaryPressed = Color(0xFF4338CA);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFFEEF2FF);
  static const onPrimaryContainer = Color(0xFF3730A3);
  static const accent = Color(0xFFF59E0B);
  static const onAccent = Color(0xFF0F172A);
  static const background = Color(0xFFF8FAFC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF1F5F9);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF475569);
  static const border = Color(0xFFE2E8F0);
  static const outline = Color(0xFF64748B);
  static const danger = Color(0xFFDC2626);
  static const dangerPressed = Color(0xFFB91C1C);
  static const onDanger = Color(0xFFFFFFFF);
  static const inverseSurface = Color(0xFF1E293B);
  static const onInverseSurface = Color(0xFFF8FAFC);
  static const cameraGround = Color(0xFF000000);
  static const scrim = Color(0x800F172A);
  static const disabledContainer = Color(0xFFE2E8F0);
  static const onDisabled = Color(0xFF64748B);

  static const statusAttend = Color(0xFF16A34A);
  static const statusAttendOn = Color(0xFFFFFFFF);
  static const statusAttendContainer = Color(0xFFDCFCE7);
  static const statusAttendOnContainer = Color(0xFF14532D);

  static const statusLate = Color(0xFFEA580C);
  static const statusLateOn = Color(0xFFFFFFFF);
  static const statusLateContainer = Color(0xFFFFEDD5);
  static const statusLateOnContainer = Color(0xFF7C2D12);

  static const statusLeave = Color(0xFF64748B);
  static const statusLeaveOn = Color(0xFFFFFFFF);
  static const statusLeaveContainer = Color(0xFFF1F5F9);
  static const statusLeaveOnContainer = Color(0xFF334155);

  static const statusSick = Color(0xFFEAB308);
  static const statusSickOn = Color(0xFF422006);
  static const statusSickContainer = Color(0xFFFEF9C3);
  static const statusSickOnContainer = Color(0xFF713F12);

  static const statusPermission = Color(0xFF6366F1);
  static const statusPermissionOn = Color(0xFFFFFFFF);
  static const statusPermissionContainer = Color(0xFFE0E7FF);
  static const statusPermissionOnContainer = Color(0xFF3730A3);

  static const statusOthers = Color(0xFF0D9488);
  static const statusOthersOn = Color(0xFFFFFFFF);
  static const statusOthersContainer = Color(0xFFCCFBF1);
  static const statusOthersOnContainer = Color(0xFF134E4A);
}

class AppSpacing {
  AppSpacing._();

  static const s1 = 4.0;
  static const s2 = 8.0;
  static const s3 = 12.0;
  static const s4 = 16.0;
  static const s5 = 20.0;
  static const s6 = 24.0;
  static const s8 = 32.0;
}

class AppRadius {
  AppRadius._();

  static const field = 12.0;
  static const button = 14.0;
  static const card = 16.0;
  static const frame = 24.0;
  static const pill = 999.0;
}

class AppSizes {
  AppSizes._();

  static const touchMin = 48.0;
  static const buttonHeight = 52.0;
  static const footerHeight = 48.0;
  static const menuSlot = 64.0;
  static const avatar = 48.0;
  static const badgeHeight = 28.0;
  static const selfieHeight = 320.0;
  static const scannerFrameWidth = 260.0;
  static const scannerFrameHeight = 340.0;
  static const scannerRing = 240.0;
  static const shutter = 96.0;
}

class AppShadows {
  AppShadows._();

  static const card = [
    BoxShadow(color: Color(0x0F0F172A), offset: Offset(0, 1), blurRadius: 2),
    BoxShadow(color: Color(0x0F0F172A), offset: Offset(0, 2), blurRadius: 8),
  ];
  static const menu = [
    BoxShadow(color: Color(0x290F172A), offset: Offset(0, 4), blurRadius: 16),
  ];
  static const fab = [
    BoxShadow(color: Color(0x59000000), offset: Offset(0, 6), blurRadius: 16),
  ];
}
