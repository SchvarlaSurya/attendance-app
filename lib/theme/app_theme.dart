import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:attendance_app/theme/app_tokens.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    const colorScheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary: AppColors.primary,
      onSecondary: AppColors.onPrimary,
      tertiary: AppColors.accent,
      onTertiary: AppColors.onAccent,
      error: AppColors.danger,
      onError: AppColors.onDanger,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      surfaceContainerHighest: AppColors.surfaceMuted,
      outline: AppColors.outline,
      outlineVariant: AppColors.border,
      inverseSurface: AppColors.inverseSurface,
      onInverseSurface: AppColors.onInverseSurface,
      scrim: AppColors.scrim,
      surfaceTint: Colors.transparent,
    );

    final textTheme = _textTheme();

    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.field),
      borderSide: const BorderSide(color: AppColors.outline),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        centerTitle: true,
        titleTextStyle: textTheme.titleMedium!.copyWith(color: AppColors.onPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 1,
        shadowColor: const Color(0x290F172A),
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        labelStyle: textTheme.bodyLarge!.copyWith(color: AppColors.textSecondary),
        floatingLabelStyle: WidgetStateTextStyle.resolveWith(
          (states) => textTheme.bodySmall!.copyWith(
            color: states.contains(WidgetState.focused)
                ? AppColors.primary
                : AppColors.textSecondary,
          ),
        ),
        prefixIconColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.focused)
              ? AppColors.primary
              : AppColors.textSecondary,
        ),
        suffixIconColor: AppColors.textSecondary,
        border: fieldBorder,
        enabledBorder: fieldBorder,
        focusedBorder: fieldBorder.copyWith(
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s4,
          vertical: AppSpacing.s4,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(64, AppSizes.touchMin)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: AppSpacing.s6),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
          ),
          textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
          backgroundColor: WidgetStateColor.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return AppColors.disabledContainer;
            if (states.contains(WidgetState.pressed)) return AppColors.primaryPressed;
            return AppColors.primary;
          }),
          foregroundColor: WidgetStateColor.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? AppColors.onDisabled
                : AppColors.onPrimary,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(64, AppSizes.touchMin),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3),
          textStyle: textTheme.labelMedium,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
        ).copyWith(
          overlayColor: const WidgetStatePropertyAll(AppColors.primaryContainer),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.inverseSurface,
        contentTextStyle: textTheme.bodyMedium!.copyWith(color: AppColors.onInverseSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.frame)),
        titleTextStyle: textTheme.titleLarge!.copyWith(color: AppColors.textPrimary),
        contentTextStyle: textTheme.bodyMedium!.copyWith(color: AppColors.textSecondary),
        barrierColor: AppColors.scrim,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        textStyle: textTheme.labelMedium!.copyWith(color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        circularTrackColor: AppColors.primaryContainer,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primaryContainer,
        elevation: 0,
        labelTextStyle: WidgetStateTextStyle.resolveWith(
          (states) => textTheme.labelSmall!.copyWith(
            color: states.contains(WidgetState.selected)
                ? AppColors.onPrimaryContainer
                : AppColors.textSecondary,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.onPrimaryContainer
                : AppColors.textSecondary,
          ),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: AppColors.primary,
        headerForegroundColor: AppColors.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.frame)),
      ),
    );
  }

  static TextTheme _textTheme() {
    final base = GoogleFonts.plusJakartaSansTextTheme();
    TextStyle style(TextStyle? s, double size, double height, FontWeight weight,
        [double letterSpacing = 0]) {
      return s!.copyWith(
        fontSize: size,
        height: height / size,
        fontWeight: weight,
        letterSpacing: letterSpacing,
        color: AppColors.textPrimary,
      );
    }

    return base.copyWith(
      titleLarge: style(base.titleLarge, 20, 28, FontWeight.w700),
      titleMedium: style(base.titleMedium, 18, 24, FontWeight.w700),
      titleSmall: style(base.titleSmall, 16, 22, FontWeight.w700),
      bodyLarge: style(base.bodyLarge, 16, 24, FontWeight.w400),
      bodyMedium: style(base.bodyMedium, 14, 20, FontWeight.w400),
      bodySmall: style(base.bodySmall, 12, 16, FontWeight.w400),
      labelLarge: style(base.labelLarge, 16, 20, FontWeight.w700),
      labelMedium: style(base.labelMedium, 14, 20, FontWeight.w600),
      labelSmall: style(base.labelSmall, 12, 16, FontWeight.w600, 0.2),
    );
  }
}
