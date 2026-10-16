import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:attendance_app/models/attendance_session.dart';
import 'package:attendance_app/services/user_service.dart';
import 'package:attendance_app/theme/app_tokens.dart';
import 'package:attendance_app/ui/teacher/create_session_screen.dart';
import 'package:attendance_app/ui/teacher/session_qr_screen.dart';
import 'package:attendance_app/ui/teacher/session_recap_screen.dart';
import 'package:attendance_app/ui/teacher/session_status.dart';
import 'package:attendance_app/ui/widgets/state_view.dart';

/// Home guru: tombol buat sesi + daftar sesi hari ini.
class TeacherHomeView extends StatefulWidget {
  final AppUser user;

  const TeacherHomeView({super.key, required this.user});

  @override
  State<TeacherHomeView> createState() => _TeacherHomeViewState();
}

class _TeacherHomeViewState extends State<TeacherHomeView> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Status sesi (Active / Expired) berubah seiring waktu, bukan hanya saat data berubah.
    _ticker = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _openSession(AttendanceSession session) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => session.isOpen
            ? SessionQrScreen(sessionId: session.id)
            : SessionRecapScreen(sessionId: session.id),
      ),
    );
  }

  List<AttendanceSession> _todaySessions(QuerySnapshot snapshot) {
    final now = DateTime.now();
    final sessions = snapshot.docs.map(AttendanceSession.fromDoc).where((s) {
      // createdAt null = baru dibuat, belum dikonfirmasi server.
      final created = s.createdAt ?? now;
      return created.year == now.year && created.month == now.month && created.day == now.day;
    }).toList();
    sessions.sort((a, b) => (b.createdAt ?? now).compareTo(a.createdAt ?? now));
    return sessions;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s5, AppSpacing.s6, AppSpacing.s5, AppSpacing.s4,
      ),
      children: [
        Text(
          "Hello, ${widget.user.name}",
          style: textTheme.titleLarge!.copyWith(color: AppColors.primary),
        ),
        const SizedBox(height: AppSpacing.s1),
        Text(
          "Create a session and show the QR to your class",
          style: textTheme.bodyMedium!.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.s6),
        SizedBox(
          height: AppSizes.buttonHeight,
          child: FilledButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CreateSessionScreen(user: widget.user)),
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text("Create Session"),
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        Text("Today's Sessions", style: textTheme.titleSmall),
        const SizedBox(height: AppSpacing.s3),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('sessions')
              .where('teacher_uid', isEqualTo: widget.user.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const StateView.loading();
            }
            if (snapshot.hasError) {
              return StateView.error("Gagal memuat sesi: ${snapshot.error}");
            }
            final sessions = snapshot.hasData ? _todaySessions(snapshot.data!) : <AttendanceSession>[];
            if (sessions.isEmpty) {
              return const StateView(
                icon: Icons.event_note_rounded,
                message: "Belum ada sesi hari ini",
              );
            }
            return Column(
              children: [
                for (final session in sessions)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.s3),
                    child: _SessionCard(session: session, onTap: () => _openSession(session)),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  final AttendanceSession session;
  final VoidCallback onTap;

  const _SessionCard({required this.session, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final created = session.createdAt;
    final timeText = created == null ? "-" : DateFormat('HH:mm').format(created);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.surfaceMuted,
        highlightColor: AppColors.surfaceMuted,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s4),
          child: Row(
            children: [
              Container(
                width: AppSizes.avatar,
                height: AppSizes.avatar,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.field),
                ),
                child: const Icon(Icons.class_outlined, color: AppColors.onPrimaryContainer),
              ),
              const SizedBox(width: AppSpacing.s4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(session.className, style: textTheme.titleSmall),
                    const SizedBox(height: AppSpacing.s1),
                    Text(
                      "${session.subject} · $timeText",
                      style: textTheme.bodySmall!.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s2),
              SessionStatusPill(state: sessionStateOf(session)),
            ],
          ),
        ),
      ),
    );
  }
}
