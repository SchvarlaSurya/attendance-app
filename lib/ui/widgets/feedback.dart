import 'package:flutter/material.dart';
import 'package:attendance_app/theme/app_tokens.dart';

/// Snackbar sistem: satu gaya untuk semua pesan, jenis pesan dibedakan lewat ikon.
void showAppSnackBar(BuildContext context, String message, IconData icon) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(icon, color: AppColors.onInverseSurface),
          const SizedBox(width: AppSpacing.s3),
          Expanded(child: Text(message)),
        ],
      ),
    ),
  );
}

/// Loader yang menutupi layar saat mengirim data atau memproses foto.
void showLoaderDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Center(
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: AppShadows.menu,
        ),
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      ),
    ),
  );
}
