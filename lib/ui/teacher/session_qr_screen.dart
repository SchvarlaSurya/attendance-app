import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:attendance_app/models/attendance_session.dart';
import 'package:attendance_app/theme/app_tokens.dart';
import 'package:attendance_app/ui/teacher/session_recap_screen.dart';
import 'package:attendance_app/ui/teacher/session_status.dart';
import 'package:attendance_app/ui/widgets/feedback.dart';
import 'package:attendance_app/ui/widgets/state_view.dart';

/// QR sesi untuk dipindai siswa, dengan hitung mundur masa berlaku.
class SessionQrScreen extends StatefulWidget {
  final String sessionId;

  const SessionQrScreen({super.key, required this.sessionId});

  @override
  State<SessionQrScreen> createState() => _SessionQrScreenState();
}

class _SessionQrScreenState extends State<SessionQrScreen> {
  late final DocumentReference sessionRef =
      FirebaseFirestore.instance.collection('sessions').doc(widget.sessionId);
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _endSession() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_rounded, color: AppColors.danger, size: 40),
        title: const Text("Akhiri Sesi?"),
        content: const Text("QR langsung tidak berlaku dan siswa tidak bisa absen lagi di sesi ini."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          FilledButton(
            style: ButtonStyle(
              backgroundColor: WidgetStateColor.resolveWith(
                (states) => states.contains(WidgetState.pressed)
                    ? AppColors.dangerPressed
                    : AppColors.danger,
              ),
              foregroundColor: const WidgetStatePropertyAll(AppColors.onDanger),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Akhiri"),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await sessionRef.update({'active': false});
      if (mounted) showAppSnackBar(context, "Sesi diakhiri.", Icons.stop_circle_outlined);
    } catch (e) {
      if (mounted) showAppSnackBar(context, "Gagal mengakhiri sesi: $e", Icons.error_outline_rounded);
    }
  }

  void _openRecap() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SessionRecapScreen(sessionId: widget.sessionId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Session QR")),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: sessionRef.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const StateView.loading();
            }
            if (snapshot.hasError) {
              return StateView.error("Gagal memuat sesi: ${snapshot.error}");
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const StateView(icon: Icons.search_off_rounded, message: "Sesi tidak ditemukan.");
            }
            return _buildContent(AttendanceSession.fromDoc(snapshot.data!));
          },
        ),
      ),
    );
  }

  Widget _buildContent(AttendanceSession session) {
    final textTheme = Theme.of(context).textTheme;
    final state = sessionStateOf(session);
    final isOpen = state == SessionState.active || state == SessionState.almostExpired;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s5, AppSpacing.s4, AppSpacing.s5, AppSpacing.s4,
      ),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(session.className, style: textTheme.titleLarge),
                  Text(
                    session.subject,
                    style: textTheme.bodyMedium!.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            SessionStatusPill(state: state),
          ],
        ),
        const SizedBox(height: AppSpacing.s6),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s6),
            child: isOpen ? _buildQr(session) : _buildClosed(state),
          ),
        ),
        const SizedBox(height: AppSpacing.s4),
        _buildCountdown(session, state),
        const SizedBox(height: AppSpacing.s8),
        SizedBox(
          height: AppSizes.buttonHeight,
          child: FilledButton.icon(
            onPressed: _openRecap,
            icon: const Icon(Icons.groups_rounded),
            label: const Text("View Recap"),
          ),
        ),
        if (isOpen) ...[
          const SizedBox(height: AppSpacing.s3),
          SizedBox(
            height: AppSizes.buttonHeight,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                textStyle: textTheme.labelLarge,
              ),
              onPressed: _endSession,
              icon: const Icon(Icons.stop_circle_outlined),
              label: const Text("End Session"),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQr(AttendanceSession session) {
    return Column(
      children: [
        Semantics(
          label: "QR sesi ${session.className}",
          child: QrImageView(
            data: session.qrData,
            size: AppSizes.scannerRing,
            backgroundColor: AppColors.surface,
            eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppColors.textPrimary),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s3),
        Text(
          "Minta siswa memindai QR ini dari menu Attendance Record",
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall!.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildClosed(SessionState state) {
    final expired = state == SessionState.expired;
    return SizedBox(
      height: AppSizes.scannerRing + AppSpacing.s8,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            expired ? Icons.timer_off_rounded : Icons.stop_circle_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.s3),
          Text(
            expired ? "QR sudah kedaluwarsa" : "Sesi sudah diakhiri",
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.s1),
          Text(
            "Siswa tidak bisa absen lagi di sesi ini.",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdown(AttendanceSession session, SessionState state) {
    final textTheme = Theme.of(context).textTheme;
    final almost = state == SessionState.almostExpired;
    final open = state == SessionState.active || almost;

    final background = almost ? AppColors.statusLateContainer : AppColors.surfaceMuted;
    final foreground = almost ? AppColors.statusLateOnContainer : AppColors.textPrimary;
    final label = !open
        ? "Masa berlaku habis"
        : almost
            ? "QR hampir kedaluwarsa"
            : "QR berlaku";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: almost ? AppColors.statusLate : AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            open ? (almost ? Icons.timer_rounded : Icons.timer_outlined) : Icons.timer_off_rounded,
            color: almost ? AppColors.statusLateOnContainer : AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.s3),
          Expanded(child: Text(label, style: textTheme.bodyMedium!.copyWith(color: foreground))),
          Text(
            formatCountdown(open ? session.remaining : Duration.zero),
            style: textTheme.titleLarge!.copyWith(
              color: foreground,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
