import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:attendance_app/models/attendance_session.dart';
import 'package:attendance_app/theme/app_tokens.dart';
import 'package:attendance_app/ui/widgets/feedback.dart';
import 'package:attendance_app/ui/widgets/state_view.dart';
import 'package:attendance_app/ui/widgets/status_badge.dart';

/// Rekap satu sesi: jumlah per status + daftar siswa yang sudah absen.
class SessionRecapScreen extends StatelessWidget {
  final String sessionId;

  const SessionRecapScreen({super.key, required this.sessionId});

  Future<void> _changeStatus(BuildContext context, String docId, String name, String current) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Ubah Status"),
        contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.s6, 0, AppSpacing.s6, AppSpacing.s2),
              child: Text(name),
            ),
            for (final status in attendanceStatuses)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.s6),
                minTileHeight: AppSizes.touchMin,
                selected: status == current,
                selectedTileColor: AppColors.primaryContainer,
                title: Align(alignment: Alignment.centerLeft, child: StatusBadge(description: status)),
                trailing: status == current
                    ? const Icon(Icons.check_rounded, color: AppColors.onPrimaryContainer)
                    : null,
                onTap: () => Navigator.pop(context, status),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
        ],
      ),
    );
    if (selected == null || selected == current || !context.mounted) return;

    try {
      await FirebaseFirestore.instance.collection('attendance').doc(docId).update({
        'description': selected,
      });
      if (context.mounted) {
        showAppSnackBar(context, "Status $name diubah ke $selected.", Icons.check_circle_outline_rounded);
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(context, "Gagal mengubah status: $e", Icons.error_outline_rounded);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Class Recap")),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('sessions').doc(sessionId).snapshots(),
          builder: (context, sessionSnapshot) {
            final session = sessionSnapshot.data?.exists == true
                ? AttendanceSession.fromDoc(sessionSnapshot.data!)
                : null;

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('attendance')
                  .where('session_id', isEqualTo: sessionId)
                  .snapshots(),
              builder: (context, snapshot) {
                final header = <Widget>[
                  if (session != null) ...[
                    Text(session.className, style: textTheme.titleLarge),
                    Text(
                      session.subject,
                      style: textTheme.bodyMedium!.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.s6),
                  ],
                ];

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListView(padding: _padding, children: [...header, const StateView.loading()]);
                }
                if (snapshot.hasError) {
                  return ListView(
                    padding: _padding,
                    children: [...header, StateView.error("Gagal memuat rekap: ${snapshot.error}")],
                  );
                }

                final docs = List<QueryDocumentSnapshot>.from(snapshot.data?.docs ?? []);
                docs.sort((a, b) {
                  final nameA = (a.data() as Map<String, dynamic>?)?['name']?.toString() ?? '';
                  final nameB = (b.data() as Map<String, dynamic>?)?['name']?.toString() ?? '';
                  return nameA.toLowerCase().compareTo(nameB.toLowerCase());
                });

                final counts = {for (final s in attendanceStatuses) s: 0};
                for (final doc in docs) {
                  final status = (doc.data() as Map<String, dynamic>?)?['description']?.toString();
                  if (counts.containsKey(status)) counts[status!] = counts[status]! + 1;
                }

                return ListView(
                  padding: _padding,
                  children: [
                    ...header,
                    _SummaryCard(total: docs.length, counts: counts),
                    const SizedBox(height: AppSpacing.s6),
                    Text("Students", style: textTheme.titleSmall),
                    const SizedBox(height: AppSpacing.s3),
                    if (docs.isEmpty)
                      const StateView(
                        icon: Icons.groups_rounded,
                        message: "Belum ada siswa yang absen di sesi ini",
                      )
                    else
                      for (final doc in docs) _buildStudentRow(context, doc),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  static const _padding = EdgeInsets.fromLTRB(
    AppSpacing.s5, AppSpacing.s4, AppSpacing.s5, AppSpacing.s4,
  );

  Widget _buildStudentRow(BuildContext context, QueryDocumentSnapshot doc) {
    final textTheme = Theme.of(context).textTheme;
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final name = data['name']?.toString() ?? 'Unknown';
    final description = data['description']?.toString() ?? '-';
    final datetime = data['datetime']?.toString() ?? '-';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s3),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.s4, AppSpacing.s2, AppSpacing.s1, AppSpacing.s2),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: textTheme.titleSmall),
                    const SizedBox(height: AppSpacing.s1),
                    Text(datetime, style: textTheme.bodySmall!.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              StatusBadge(description: description),
              IconButton(
                tooltip: "Ubah status",
                onPressed: () => _changeStatus(context, doc.id, name, description),
                icon: const Icon(Icons.edit_rounded, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int total;
  final Map<String, int> counts;

  const _SummaryCard({required this.total, required this.counts});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // Attend, Late, Leave selalu tampil; jenis izin hanya bila ada.
    final shown = attendanceStatuses.where(
      (s) => ['Attend', 'Late', 'Leave'].contains(s) || counts[s]! > 0,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.groups_rounded, color: AppColors.primary),
                const SizedBox(width: AppSpacing.s3),
                Expanded(child: Text("Total", style: textTheme.bodyMedium)),
                Text("$total", style: textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: AppSpacing.s3),
            Wrap(
              spacing: AppSpacing.s2,
              runSpacing: AppSpacing.s2,
              children: [
                for (final status in shown)
                  StatusPill(label: "$status ${counts[status]}", style: statusStyleOf(status)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
