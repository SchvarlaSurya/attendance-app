import 'package:flutter/material.dart';
import 'package:attendance_app/theme/app_tokens.dart';

/// Isi area daftar saat memuat, kosong, atau error.
class StateView extends StatelessWidget {
  final IconData? icon;
  final String? message;
  final bool isError;
  final bool isLoading;

  const StateView({super.key, required this.icon, required this.message})
      : isError = false,
        isLoading = false;

  const StateView.loading({super.key})
      : icon = null,
        message = null,
        isError = false,
        isLoading = true;

  const StateView.error(this.message, {super.key})
      : icon = Icons.error_rounded,
        isError = true,
        isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s6),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              const CircularProgressIndicator()
            else
              Icon(icon, size: 48, color: isError ? AppColors.danger : AppColors.textSecondary),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.s3),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: AppColors.textSecondary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
