import 'package:flutter/material.dart';
import 'package:attendance_app/services/user_service.dart';
import 'package:attendance_app/theme/app_tokens.dart';

/// Profil akun yang sedang login. Dipakai siswa (dari Home) dan guru (tab Profile).
class ProfileView extends StatelessWidget {
  final AppUser user;

  const ProfileView({super.key, required this.user});

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout?"),
        content: const Text("Kamu perlu mengisi nama dan peran lagi untuk memakai aplikasi."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Logout"),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
    await UserService.signOut();
  }

  Widget _row(BuildContext context, IconData icon, String label, String value) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s3),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: textTheme.bodySmall!.copyWith(color: AppColors.textSecondary)),
                Text(value, style: textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final initial = user.name.isNotEmpty ? user.name[0].toUpperCase() : '?';

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s5, AppSpacing.s6, AppSpacing.s5, AppSpacing.s4,
      ),
      children: [
        Center(
          child: CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.primary,
            child: Text(
              initial,
              style: textTheme.titleLarge!.copyWith(color: AppColors.onPrimary, fontSize: 32),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s3),
        Text(user.name, style: textTheme.titleLarge, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.s6),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s1),
            child: Column(
              children: [
                _row(context, Icons.person_outline_rounded, "Full Name", user.name),
                const Divider(height: 1, color: AppColors.border),
                _row(context, Icons.badge_outlined, "Role", user.roleLabel),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        SizedBox(
          height: AppSizes.buttonHeight,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.danger),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
              textStyle: textTheme.labelLarge,
            ),
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout_rounded),
            label: const Text("Logout"),
          ),
        ),
      ],
    );
  }
}

/// Profil sebagai halaman sendiri (untuk siswa).
class ProfileScreen extends StatelessWidget {
  final AppUser user;

  const ProfileScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: SafeArea(child: ProfileView(user: user)),
    );
  }
}
