import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:attendance_app/models/attendance_session.dart';
import 'package:attendance_app/services/user_service.dart';
import 'package:attendance_app/theme/app_tokens.dart';
import 'package:attendance_app/ui/teacher/create_session_screen.dart';
import 'package:attendance_app/ui/teacher/session_qr_screen.dart';
import 'package:attendance_app/ui/teacher/session_recap_screen.dart';
import 'package:attendance_app/ui/teacher/session_status.dart';
import 'package:attendance_app/ui/widgets/dashboard_parts.dart';
import 'package:attendance_app/ui/widgets/state_view.dart';
import 'package:attendance_app/ui/widgets/status_badge.dart';
import 'package:attendance_app/utils/date_labels.dart';

/// Batas `whereIn` Firestore: rekap dashboard memakai 30 sesi terbaru.
const _maxSessions = 30;

/// Dashboard guru: ringkasan hari ini, sesi aktif, siswa terbaru, riwayat sesi.
class TeacherHomeView extends StatefulWidget {
  final AppUser user;

  const TeacherHomeView({super.key, required this.user});

  @override
  State<TeacherHomeView> createState() => _TeacherHomeViewState();
}

class _TeacherHomeViewState extends State<TeacherHomeView> {
  late final Stream<QuerySnapshot> _sessionsStream = FirebaseFirestore.instance
      .collection('sessions')
      .where('teacher_uid', isEqualTo: widget.user.uid)
      .snapshots();

  List<AttendanceSession> _sorted(QuerySnapshot snapshot) {
    final now = DateTime.now();
    final sessions = snapshot.docs.map(AttendanceSession.fromDoc).toList();
    // createdAt null = baru dibuat, belum dikonfirmasi server.
    sessions.sort((a, b) => (b.createdAt ?? now).compareTo(a.createdAt ?? now));
    return sessions.take(_maxSessions).toList();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _sessionsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView(children: [GreetingHeader(name: widget.user.name), const StateView.loading()]);
        }
        if (snapshot.hasError) {
          return ListView(
            children: [
              GreetingHeader(name: widget.user.name),
              StateView.error("Gagal memuat sesi: ${snapshot.error}"),
            ],
          );
        }
        return _Dashboard(
          user: widget.user,
          sessions: snapshot.hasData ? _sorted(snapshot.data!) : const [],
        );
      },
    );
  }
}

class _Dashboard extends StatefulWidget {
  final AppUser user;
  final List<AttendanceSession> sessions;

  const _Dashboard({required this.user, required this.sessions});

  @override
  State<_Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<_Dashboard> {
  Stream<QuerySnapshot>? _attendanceStream;
  List<String> _streamIds = const [];
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _syncAttendanceStream();
    // Status sesi (Active / Expired) berubah seiring waktu, bukan hanya saat data berubah.
    _ticker = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(_Dashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAttendanceStream();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  // Stream baru hanya saat daftar sesi berubah, supaya dashboard tidak berkedip.
  void _syncAttendanceStream() {
    final ids = widget.sessions.map((s) => s.id).toList();
    if (listEquals(ids, _streamIds)) return;
    _streamIds = ids;
    _attendanceStream = ids.isEmpty
        ? null
        : FirebaseFirestore.instance
            .collection('attendance')
            .where('session_id', whereIn: ids)
            .snapshots();
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

  void _openRecap(AttendanceSession session) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SessionRecapScreen(sessionId: session.id)),
    );
  }

  void _createSession() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreateSessionScreen(user: widget.user)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stream = _attendanceStream;
    if (stream == null) return _buildContent(const [], attendanceError: null);

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) => _buildContent(
        snapshot.data?.docs.map(_Record.fromDoc).toList() ?? const [],
        attendanceError: snapshot.error,
      ),
    );
  }

  Widget _buildContent(List<_Record> records, {required Object? attendanceError}) {
    final textTheme = Theme.of(context).textTheme;
    final now = DateTime.now();
    final sessions = widget.sessions;

    bool isToday(DateTime? d) => dayLabel(d ?? now, now) == 'Today';
    final todaySessions = sessions.where((s) => isToday(s.createdAt)).toList();
    final todayIds = todaySessions.map((s) => s.id).toSet();
    final todayRecords = records.where((r) => todayIds.contains(r.sessionId)).toList()
      ..sort((a, b) => (b.createdAt ?? now).compareTo(a.createdAt ?? now));

    final countBySession = <String, int>{};
    for (final r in records) {
      countBySession[r.sessionId] = (countBySession[r.sessionId] ?? 0) + 1;
    }
    final statusCounts = <String, int>{};
    for (final r in todayRecords) {
      statusCounts[r.status] = (statusCounts[r.status] ?? 0) + 1;
    }

    final open = sessions.where((s) => s.isOpen).toList();
    final active = open.isEmpty ? null : open.first;
    final others = sessions.where((s) => s.id != active?.id).toList();

    final classNames = _sessionNameById(sessions);

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.s6),
      children: [
        GreetingHeader(name: widget.user.name),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s5, AppSpacing.s4, AppSpacing.s5, 0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: StatTile(
                      icon: Icons.event_note_rounded,
                      value: todaySessions.length,
                      label: "Sessions",
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s3),
                  Expanded(
                    child: StatTile(
                      icon: Icons.check_rounded,
                      value: statusCounts['Attend'] ?? 0,
                      label: "Attend",
                      color: AppColors.statusAttend,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s3),
                  Expanded(
                    child: StatTile(
                      icon: Icons.schedule_rounded,
                      value: statusCounts['Late'] ?? 0,
                      label: "Late",
                      color: AppColors.statusLate,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s4),
              if (active != null) ...[
                _ActiveSessionCard(
                  key: ValueKey(active.id),
                  session: active,
                  checkedIn: countBySession[active.id] ?? 0,
                  onShowQr: () => _openSession(active),
                  onRecap: () => _openRecap(active),
                  onExpired: () {
                    if (mounted) setState(() {});
                  },
                ),
                const SizedBox(height: AppSpacing.s3),
                SizedBox(
                  height: AppSizes.buttonHeight,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                      textStyle: textTheme.labelLarge,
                    ),
                    onPressed: _createSession,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text("Create Session"),
                  ),
                ),
              ] else
                _NoActiveSessionCard(onCreate: _createSession),
              const SizedBox(height: AppSpacing.s6),
              Text("Today's Attendance", style: textTheme.titleSmall),
              const SizedBox(height: AppSpacing.s3),
              if (attendanceError != null)
                StateView.error("Gagal memuat presensi: $attendanceError")
              else
                _AttendanceBreakdown(counts: statusCounts, total: todayRecords.length),
              if (todayRecords.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s6),
                Text("Latest Check-ins", style: textTheme.titleSmall),
                const SizedBox(height: AppSpacing.s3),
                _LatestCheckIns(records: todayRecords.take(5).toList(), classNames: classNames),
              ],
              const SizedBox(height: AppSpacing.s6),
              if (others.isEmpty)
                const StateView(
                  icon: Icons.event_note_rounded,
                  message: "Riwayat sesi akan muncul di sini",
                )
              else
                ..._buildSessionHistory(others, countBySession, now),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildSessionHistory(
    List<AttendanceSession> sessions,
    Map<String, int> countBySession,
    DateTime now,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final widgets = <Widget>[];
    String? currentDay;
    for (final session in sessions) {
      final day = dayLabel(session.createdAt ?? now, now);
      if (day != currentDay) {
        if (currentDay != null) widgets.add(const SizedBox(height: AppSpacing.s3));
        widgets.add(Text(day, style: textTheme.titleSmall));
        widgets.add(const SizedBox(height: AppSpacing.s3));
        currentDay = day;
      }
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.s3),
          child: _SessionCard(
            session: session,
            checkedIn: countBySession[session.id] ?? 0,
            onTap: () => _openSession(session),
          ),
        ),
      );
    }
    return widgets;
  }
}

Map<String, String> _sessionNameById(List<AttendanceSession> sessions) =>
    {for (final s in sessions) s.id: s.className};

class _Record {
  final String sessionId;
  final String name;
  final String status;
  final DateTime? createdAt;

  const _Record(this.sessionId, this.name, this.status, this.createdAt);

  factory _Record.fromDoc(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return _Record(
      data['session_id']?.toString() ?? '',
      data['name']?.toString() ?? 'Unknown',
      data['description']?.toString() ?? '-',
      (data['created_at'] as Timestamp?)?.toDate(),
    );
  }
}

class _ActiveSessionCard extends StatefulWidget {
  final AttendanceSession session;
  final int checkedIn;
  final VoidCallback onShowQr;
  final VoidCallback onRecap;
  final VoidCallback onExpired;

  const _ActiveSessionCard({
    super.key,
    required this.session,
    required this.checkedIn,
    required this.onShowQr,
    required this.onRecap,
    required this.onExpired,
  });

  @override
  State<_ActiveSessionCard> createState() => _ActiveSessionCardState();
}

class _ActiveSessionCardState extends State<_ActiveSessionCard> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (widget.session.remaining == Duration.zero) {
        _ticker?.cancel();
        widget.onExpired();
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final session = widget.session;
    final state = sessionStateOf(session);
    final almost = state == SessionState.almostExpired;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: const BorderSide(color: AppColors.primary),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
            const SizedBox(height: AppSpacing.s4),
            Row(
              children: [
                Expanded(
                  child: _HeroFigure(
                    icon: Icons.timer_outlined,
                    value: formatCountdown(session.remaining),
                    label: "QR valid for",
                    color: almost ? AppColors.statusLateOnContainer : AppColors.textPrimary,
                  ),
                ),
                Expanded(
                  child: _HeroFigure(
                    icon: Icons.groups_rounded,
                    value: "${widget.checkedIn}",
                    label: "Checked in",
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s4),
            SizedBox(
              height: AppSizes.buttonHeight,
              child: FilledButton.icon(
                onPressed: widget.onShowQr,
                icon: const Icon(Icons.qr_code_rounded),
                label: const Text("Show QR"),
              ),
            ),
            const SizedBox(height: AppSpacing.s1),
            TextButton(onPressed: widget.onRecap, child: const Text("View Recap")),
          ],
        ),
      ),
    );
  }
}

class _HeroFigure extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _HeroFigure({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.s2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: textTheme.titleLarge!.copyWith(
                  color: color,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(label, style: textTheme.bodySmall!.copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}

class _NoActiveSessionCard extends StatelessWidget {
  final VoidCallback onCreate;

  const _NoActiveSessionCard({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Belum ada sesi aktif", style: textTheme.titleSmall),
            const SizedBox(height: AppSpacing.s1),
            Text(
              "Buat sesi, tampilkan QR, lalu siswa bisa mulai absen.",
              style: textTheme.bodyMedium!.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.s4),
            const Row(
              children: [
                Expanded(child: _Step(icon: Icons.add_rounded, label: "Create")),
                Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                Expanded(child: _Step(icon: Icons.qr_code_rounded, label: "Show QR")),
                Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                Expanded(child: _Step(icon: Icons.groups_rounded, label: "Recap")),
              ],
            ),
            const SizedBox(height: AppSpacing.s4),
            SizedBox(
              height: AppSizes.buttonHeight,
              child: FilledButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add_rounded),
                label: const Text("Create Session"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Step({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: AppSizes.touchMin,
          height: AppSizes.touchMin,
          decoration: const BoxDecoration(
            color: AppColors.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.onPrimaryContainer),
        ),
        const SizedBox(height: AppSpacing.s1),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall!.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

/// Komposisi status hari ini: bar proporsi + pill berisi jumlah.
class _AttendanceBreakdown extends StatelessWidget {
  final Map<String, int> counts;
  final int total;

  const _AttendanceBreakdown({required this.counts, required this.total});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final shown = attendanceStatuses.where((s) => (counts[s] ?? 0) > 0).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s4),
        child: total == 0
            ? Row(
                children: [
                  const Icon(Icons.bar_chart_rounded, color: AppColors.textSecondary),
                  const SizedBox(width: AppSpacing.s3),
                  Expanded(
                    child: Text(
                      "Belum ada siswa yang absen hari ini",
                      style: textTheme.bodyMedium!.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text("$total students checked in", style: textTheme.bodyMedium),
                  const SizedBox(height: AppSpacing.s3),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: SizedBox(
                      height: AppSpacing.s2,
                      child: Row(
                        children: [
                          for (final status in shown)
                            Expanded(
                              flex: counts[status]!,
                              child: ColoredBox(color: statusStyleOf(status).base),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s3),
                  Wrap(
                    spacing: AppSpacing.s2,
                    runSpacing: AppSpacing.s2,
                    children: [
                      for (final status in shown)
                        StatusPill(
                          label: "$status ${counts[status]}",
                          style: statusStyleOf(status),
                        ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

class _LatestCheckIns extends StatelessWidget {
  final List<_Record> records;
  final Map<String, String> classNames;

  const _LatestCheckIns({required this.records, required this.classNames});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Column(
        children: [
          for (var i = 0; i < records.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.s3),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primaryContainer,
                    child: Text(
                      records[i].name.isNotEmpty ? records[i].name[0].toUpperCase() : '?',
                      style: textTheme.titleSmall!.copyWith(color: AppColors.onPrimaryContainer),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(records[i].name, style: textTheme.titleSmall),
                        Text(
                          "${classNames[records[i].sessionId] ?? '-'} · ${_time(records[i].createdAt)}",
                          style: textTheme.bodySmall!.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s2),
                  StatusBadge(description: records[i].status),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _time(DateTime? d) => d == null ? '-' : DateFormat('HH:mm').format(d);
}

class _SessionCard extends StatelessWidget {
  final AttendanceSession session;
  final int checkedIn;
  final VoidCallback onTap;

  const _SessionCard({required this.session, required this.checkedIn, required this.onTap});

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
                      "${session.subject} · $timeText · $checkedIn students",
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
