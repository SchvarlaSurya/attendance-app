import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:attendance_app/models/attendance_record.dart';
import 'package:attendance_app/services/user_service.dart';
import 'package:attendance_app/theme/app_tokens.dart';
import 'package:attendance_app/ui/absent/absent_screen.dart';
import 'package:attendance_app/ui/attend/scan_qr_screen.dart';
import 'package:attendance_app/ui/attendance_history/attendance_history_screen.dart';
import 'package:attendance_app/ui/profile/profile_screen.dart';
import 'package:attendance_app/ui/widgets/dashboard_parts.dart';
import 'package:attendance_app/ui/widgets/state_view.dart';
import 'package:attendance_app/ui/widgets/status_badge.dart';

/// Home siswa: status hari ini, aksi presensi, ringkasan bulan ini, aktivitas terbaru.
class HomeScreen extends StatefulWidget {
  final AppUser user;

  /// Sumber riwayat siswa. Default dari Firestore; tes mengisinya sendiri.
  final Stream<List<AttendanceRecord>>? recordsStream;

  const HomeScreen({super.key, required this.user, this.recordsStream});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Stream<List<AttendanceRecord>> _records =
      widget.recordsStream ??
      FirebaseFirestore.instance
          .collection('attendance')
          .where('uid', isEqualTo: widget.user.uid)
          .snapshots()
          .map((s) => s.docs.map(AttendanceRecord.fromDoc).toList());

  void _push(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendance - XI RPL"),
        actions: [
          IconButton(
            tooltip: "Profile",
            icon: const Icon(Icons.account_circle_rounded),
            onPressed: () => _push(ProfileScreen(user: widget.user)),
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<List<AttendanceRecord>>(
          stream: _records,
          builder: (context, snapshot) {
            final now = DateTime.now();
            final records =
                List<AttendanceRecord>.from(snapshot.data ?? const [])..sort(
                  (a, b) => (b.createdAt ?? now).compareTo(a.createdAt ?? now),
                );
            final summary = StudentSummary.from(records, now);

            return ListView(
              padding: const EdgeInsets.only(bottom: AppSpacing.s4),
              children: [
                GreetingHeader(name: widget.user.name),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.s5,
                    AppSpacing.s4,
                    AppSpacing.s5,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _CheckInHero(
                        latestToday: summary.latestToday,
                        onTap: () => _push(const ScanQrScreen()),
                      ),
                      const SizedBox(height: AppSpacing.s6),
                      Text("This Month", style: textTheme.titleSmall),
                      const SizedBox(height: AppSpacing.s3),
                      Row(
                        children: [
                          Expanded(
                            child: StatTile(
                              icon: Icons.check_rounded,
                              value: summary.monthAttend,
                              label: "Attend",
                              color: AppColors.statusAttend,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.s3),
                          Expanded(
                            child: StatTile(
                              icon: Icons.schedule_rounded,
                              value: summary.monthLate,
                              label: "Late",
                              color: AppColors.statusLate,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.s3),
                          Expanded(
                            child: StatTile(
                              icon: Icons.assignment_rounded,
                              value: summary.monthPermission,
                              label: "Permission",
                              color: AppColors.statusPermission,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s6),
                      Text("Menu", style: textTheme.titleSmall),
                      const SizedBox(height: AppSpacing.s3),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _MenuTile(
                              title: "Permission / Leave",
                              subtitle:
                                  "Submit leave request for sick or permission",
                              imagePath: 'assets/images/ic_leave.png',
                              icon: Icons.assignment_rounded,
                              onTap: () => _push(const AbsentScreen()),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.s3),
                          Expanded(
                            child: _MenuTile(
                              title: "Attendance History",
                              subtitle:
                                  "View and manage all attendance history records",
                              imagePath: 'assets/images/ic_history.png',
                              icon: Icons.history_rounded,
                              onTap: () =>
                                  _push(const AttendanceHistoryScreen()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s6),
                      Text("Recent Activity", style: textTheme.titleSmall),
                      const SizedBox(height: AppSpacing.s3),
                      if (snapshot.hasError)
                        StateView.error(
                          "Gagal memuat aktivitas: ${snapshot.error}",
                        )
                      else if (snapshot.connectionState ==
                          ConnectionState.waiting)
                        const StateView.loading()
                      else
                        _RecentActivity(records: records.take(4).toList()),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: ColoredBox(
        color: AppColors.primary,
        child: SafeArea(
          top: false,
          child: Container(
            height: AppSizes.footerHeight,
            alignment: Alignment.center,
            child: Text(
              "IDN Boarding School Solo",
              style: textTheme.labelMedium!.copyWith(
                color: AppColors.onPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Aksi utama: kartu besar presensi, sekaligus menunjukkan status hari ini.
class _CheckInHero extends StatelessWidget {
  final AttendanceRecord? latestToday;
  final VoidCallback onTap;

  const _CheckInHero({required this.latestToday, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final latest = latestToday;
    final radius = BorderRadius.circular(AppRadius.card);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.s4),
            child: Row(
              children: [
                Container(
                  width: AppSizes.menuSlot,
                  height: AppSizes.menuSlot,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppRadius.field),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    'assets/images/ic_absen.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.qr_code_scanner_rounded,
                      size: 32,
                      color: AppColors.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Attendance Record", style: textTheme.titleSmall),
                      const SizedBox(height: AppSpacing.s1),
                      Text(
                        "Take selfie photo and record your attendance",
                        style: textTheme.bodySmall!.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
            padding: const EdgeInsets.all(AppSpacing.s3),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: radius,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Today",
                        style: textTheme.bodySmall!.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        latest == null
                            ? "Belum absen hari ini"
                            : "${latest.className ?? 'Absen'} · ${_time(latest.createdAt)}",
                        style: textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                if (latest != null)
                  StatusBadge(description: latest.description),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.s4),
            child: SizedBox(
              height: AppSizes.buttonHeight,
              child: FilledButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: const Text("Scan Session QR"),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _time(DateTime? d) => d == null ? '-' : DateFormat('HH:mm').format(d);
}

class _MenuTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imagePath;
  final IconData icon;
  final VoidCallback onTap;

  const _MenuTile({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.surfaceMuted,
        highlightColor: AppColors.surfaceMuted,
        child: ConstrainedBox(
          // Dua kartu sama tinggi selama teksnya muat, dan tetap bisa memanjang bila tidak.
          constraints: const BoxConstraints(minHeight: 172),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: AppSizes.touchMin,
                  height: AppSizes.touchMin,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.field),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(icon, color: AppColors.onPrimaryContainer),
                  ),
                ),
                const SizedBox(height: AppSpacing.s3),
                Text(title, style: textTheme.titleSmall),
                const SizedBox(height: AppSpacing.s1),
                Text(
                  subtitle,
                  style: textTheme.bodySmall!.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentActivity extends StatelessWidget {
  final List<AttendanceRecord> records;

  const _RecentActivity({required this.records});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: records.isEmpty
          ? const StateView(
              icon: Icons.history_rounded,
              message: "Aktivitas presensi dan izinmu akan muncul di sini",
            )
          : Column(
              children: [
                for (var i = 0; i < records.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: AppColors.border),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.s3),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                records[i].isPermission
                                    ? "Permission request"
                                    : records[i].className ?? "Attendance",
                                style: textTheme.titleSmall,
                              ),
                              Text(
                                records[i].datetime,
                                style: textTheme.bodySmall!.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s2),
                        StatusBadge(description: records[i].description),
                      ],
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
